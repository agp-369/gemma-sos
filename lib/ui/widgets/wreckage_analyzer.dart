import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/gemma_service.dart';

class WreckageAnalyzer extends StatefulWidget {
  const WreckageAnalyzer({super.key});

  @override
  State<WreckageAnalyzer> createState() => _WreckageAnalyzerState();
}

class _WreckageAnalyzerState extends State<WreckageAnalyzer> {
  final ImagePicker _picker = ImagePicker();
  final GemmaInferenceService _gemma = GemmaInferenceService();

  XFile? _image;
  String _analysis = '';
  bool _isAnalyzing = false;
  ConfidenceLevel _lastConfidence = ConfidenceLevel.medium;

  Future<void> _captureAndAnalyze() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo == null) return;

    setState(() {
      _image = photo;
      _isAnalyzing = true;
      _analysis = 'Tengu Sight is focusing... Gemma 4 E2B analyzing structural fractures.';
    });

    final bytes = await photo.readAsBytes();

    final result = await _gemma.analyzeImage(
      bytes,
      'Act as a structural engineer in a disaster zone. Analyze this image for: '
      '1. CRITICAL HAZARDS (Fire, Gas, Electrical) '
      '2. STRUCTURAL FRACTURES (Severity, Collapse Risk) '
      '3. SURVIVOR SIGNALS (Movement, Entrapment) '
      '4. TACTICAL ACCESS (Blocked vs Safe routes) '
      'Provide a concise, life-saving report.',
    );

    setState(() {
      _isAnalyzing = false;
      _analysis = result.text;
      _lastConfidence = result.confidence;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isHighConfidence = _lastConfidence == ConfidenceLevel.high;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        title: const Text('TENGU SIGHT', style: TextStyle(letterSpacing: 2)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            if (_image != null)
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF333333)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(
                    File(_image!.path),
                    height: 250,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),

            const SizedBox(height: 24),

            if (_isAnalyzing)
              const LinearProgressIndicator(color: Color(0xFFD4AF37), backgroundColor: Color(0xFF1A1A1A)),

            if (_analysis.isNotEmpty && !_isAnalyzing)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isHighConfidence ? const Color(0xFFD4AF37) : const Color(0xFF333333),
                    width: isHighConfidence ? 1.5 : 1,
                  ),
                  boxShadow: isHighConfidence ? [
                    BoxShadow(color: const Color(0xFFD4AF37).withValues(alpha: 0.1), blurRadius: 15)
                  ] : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.remove_red_eye, color: Color(0xFFD4AF37), size: 18),
                        const SizedBox(width: 12),
                        const Text('TACTICAL ASSESSMENT', 
                          style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.5)),
                        const Spacer(),
                        _confidenceBadge(_lastConfidence),
                      ],
                    ),
                    const Divider(color: Color(0xFF333333), height: 32),
                    Text(
                      _analysis,
                      style: const TextStyle(color: Color(0xFFE0E0E0), fontSize: 14, height: 1.5),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 32),

            ElevatedButton.icon(
              onPressed: _isAnalyzing ? null : _captureAndAnalyze,
              icon: const Icon(Icons.camera_alt),
              label: Text(_image == null ? 'SCAN STRUCTURE' : 'RE-SCAN'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                backgroundColor: const Color(0xFFD4AF37),
                foregroundColor: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'SOVEREIGN VISION ENGINE | GEMMA 4 MULTIMODAL',
              style: TextStyle(color: Colors.grey, fontSize: 10, letterSpacing: 2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _confidenceBadge(ConfidenceLevel level) {
    Color color = Colors.grey;
    if (level == ConfidenceLevel.high) color = const Color(0xFFD4AF37);
    if (level == ConfidenceLevel.insufficient) color = const Color(0xFF8B0000);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        level.name.toUpperCase(),
        style: TextStyle(fontSize: 8, color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}
