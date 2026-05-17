import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:path_provider/path_provider.dart';

/// Confidence level for Gemma 4 responses
enum ConfidenceLevel { high, medium, low, insufficient }

/// Result wrapper with confidence scoring
class GemmaResult {
  final String text;
  final ConfidenceLevel confidence;
  final double confidenceScore;
  final Duration latency;
  final String? error;

  const GemmaResult({
    required this.text,
    this.confidence = ConfidenceLevel.medium,
    this.confidenceScore = 0.5,
    this.latency = Duration.zero,
    this.error,
  });

  bool get isError => error != null;
  bool get isSafe => confidence != ConfidenceLevel.insufficient;
}

/// Gemma 4 E2B on-device inference service.
class GemmaInferenceService {
  static final GemmaInferenceService _instance =
      GemmaInferenceService._internal();
  factory GemmaInferenceService() => _instance;
  GemmaInferenceService._internal();

  bool _isInitialized = false;
  InferenceModel? _model;
  String _lastError = '';
  int _totalInferences = 0;
  double _avgLatencyMs = 0;

  bool get isInitialized => _isInitialized;
  bool get isModelLoaded => _model != null;
  String get lastError => _lastError;
  int get totalInferences => _totalInferences;
  double get avgLatencyMs => _avgLatencyMs;

  /// Initialize Gemma 4 engine using flutter_gemma v0.15.0 pattern.
  ///
  /// [onStatus] is called with progress messages (shown on splash screen).
  Future<void> initialize({void Function(String msg)? onStatus}) async {
    debugPrint('[*] Initializing Kintsugi Intelligence (Gemma 4 E2B)...');
    try {
      // Step 1: Register the model with the model manager if not already done.
      if (!FlutterGemma.hasActiveModel()) {
        await _installModelFromDevice(onStatus: onStatus);
      }

      // Step 2: Get the active model for inference
      onStatus?.call('Loading model into engine...');
      _model = await FlutterGemma.getActiveModel(
        maxTokens: 1024,
        preferredBackend: PreferredBackend.cpu,
        supportImage: true,
        maxNumImages: 1,
        enableSpeculativeDecoding: true,
      );

      _isInitialized = true;
      debugPrint('[+] Sovereign Node Intelligence Online');
    } catch (e) {
      _lastError = 'Intelligence wake-up failed: $e';
      debugPrint('[!] $_lastError');
      rethrow;
    }
  }

  /// Locate model on device and copy to app-private storage (Android 11+ safe).
  Future<void> _installModelFromDevice({void Function(String msg)? onStatus}) async {
    // App-private path — the only location native FFI can access on Android 11+
    late final String privateDir;
    try {
      privateDir = (await getApplicationSupportDirectory()).path;
    } catch (_) {
      privateDir = (await getExternalStorageDirectory())?.path ?? '';
    }
    final privatePath = '$privateDir/gemma-4-E2B-it.litertlm';
    final privateFile = File(privatePath);

    // Step 1: Check if already copied to private storage (and valid size)
    if (await privateFile.exists()) {
      final size = await privateFile.length();
      if (size >= 1048576) { // minimum 1MB to be valid
        onStatus?.call('Found model in app storage');
        if (!FlutterGemma.hasActiveModel()) {
          await FlutterGemma.installModel(
            modelType: ModelType.gemma4,
            fileType: ModelFileType.litertlm,
          ).fromFile(privatePath).install();
        }
        return;
      }
      // Corrupted/empty file — delete and re-copy
      debugPrint('[!] Corrupted model file ($size bytes), re-copying...');
      await privateFile.delete();
    }

    // Step 2: Search candidate source paths
    // App-specific external dir is checked first (always accessible on Android 11+)
    late final String externalDir;
    try {
      externalDir = (await getExternalStorageDirectory())?.path ?? '';
    } catch (_) {
      externalDir = '';
    }
    final List<String> sourcePaths = [
      if (externalDir.isNotEmpty) '$externalDir/gemma-4-E2B-it.litertlm',
      '/sdcard/Download/gemma-4-E2B-it.litertlm',
      '/storage/emulated/0/Download/gemma-4-E2B-it.litertlm',
    ];

    for (final srcPath in sourcePaths) {
      final srcFile = File(srcPath);
      if (!await srcFile.exists()) continue;

      onStatus?.call('Copying model to app storage...');
      final length = await srcFile.length();

      // Stream-copy with progress
      final sink = privateFile.openWrite();
      final stream = srcFile.openRead();
      int copied = 0;
      await for (final chunk in stream) {
        sink.add(chunk);
        copied += chunk.length;
        final pct = (copied * 100 / length).round();
        if (pct % 10 == 0 || copied == length) {
          onStatus?.call('Copying model: $pct%');
        }
      }
      await sink.close();

      final copiedSize = await privateFile.length();
      debugPrint('[+] Copied model to: $privatePath ($copiedSize bytes)');

      // Register with flutter_gemma from private path
      await FlutterGemma.installModel(
        modelType: ModelType.gemma4,
        fileType: ModelFileType.litertlm,
      ).fromFile(privatePath).install();
      return;
    }

    throw StateError(
      'Gemma 4 model file not found.\n'
      '1. adb push assets/models/gemma-4-E2B-it.litertlm ${externalDir.isNotEmpty ? externalDir : '/sdcard/Download/'}\n'
      '2. Restart the app',
    );
  }

  /// Generate a text response using Gemma 4 E2B.
  Future<GemmaResult> getResponse(
    String prompt, {
    String? systemInstruction,
    double temperature = 0.3,
    int maxTokens = 512,
  }) async {
    if (_model == null) {
      return const GemmaResult(
        text: 'Sovereign node offline.',
        confidence: ConfidenceLevel.insufficient,
        error: 'Model not loaded',
      );
    }

    final stopwatch = Stopwatch()..start();
    _totalInferences++;

    try {
      final fullPrompt = systemInstruction != null 
          ? '$systemInstruction\n\nUser: $prompt'
          : prompt;

      final session = await _model!.createSession();
      await session.addQueryChunk(Message.text(text: fullPrompt));
      final responseText = await session.getResponse();
      await session.close();
      
      stopwatch.stop();

      final result = _evaluateResponse(responseText, prompt);
      _avgLatencyMs =
          (_avgLatencyMs * (_totalInferences - 1) + stopwatch.elapsedMilliseconds) /
              _totalInferences;

      return GemmaResult(
        text: result['text'] as String,
        confidence: result['confidence'] as ConfidenceLevel,
        confidenceScore: result['score'] as double,
        latency: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      return GemmaResult(
        text: 'Neural fracture: $e',
        confidence: ConfidenceLevel.insufficient,
        error: e.toString(),
        latency: stopwatch.elapsed,
      );
    }
  }

  /// Analyze an image using Gemma 4's multimodal vision.
  Future<GemmaResult> analyzeImage(
    Uint8List imageBytes,
    String query,
  ) async {
    if (_model == null) {
      return const GemmaResult(
        text: 'Vision node offline.',
        confidence: ConfidenceLevel.insufficient,
        error: 'Model not loaded',
      );
    }

    return const GemmaResult(
      text: 'Vision analysis unavailable on this device. '
          'Gemma 4 E2B vision requires GPU acceleration which is not available '
          'on the current hardware. Text-based triage still works.',
      confidence: ConfidenceLevel.insufficient,
      error: 'Image analysis compiled model failed on CPU backend',
    );
  }

  /// Post-process: evaluate response confidence and safety.
  Map<String, dynamic> _evaluateResponse(String text, String query) {
    final lower = text.toLowerCase();
    double score = 0.7;

    if (lower.contains('i don\'t know') ||
        lower.contains('i am not sure') ||
        lower.contains('cannot assess')) {
      score -= 0.3;
    }

    if (lower.contains('confidently') ||
        lower.contains('definitely') ||
        lower.contains('clearly')) {
      score += 0.15;
    }

    if (lower.contains('seek professional') ||
        lower.contains('call emergency')) {
      score += 0.1;
    }

    score = score.clamp(0.0, 1.0);

    ConfidenceLevel level;
    if (score >= 0.8) {
      level = ConfidenceLevel.high;
    } else if (score >= 0.5) {
      level = ConfidenceLevel.medium;
    } else if (score >= 0.25) {
      level = ConfidenceLevel.low;
    } else {
      level = ConfidenceLevel.insufficient;
    }

    return {
      'text': text,
      'confidence': level,
      'score': score,
    };
  }

  void dispose() {
    _isInitialized = false;
    _model = null;
  }
}
