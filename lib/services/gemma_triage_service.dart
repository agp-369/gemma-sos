import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'gemma_service.dart';
import 'triage_engine.dart';

/// Service that leverages Gemma 4 to perform agentic medical triage.
class GemmaTriageService {
  final GemmaInferenceService _gemma = GemmaInferenceService();
  final TriageEngine _engine = TriageEngine();

  /// Use Gemma 4 to parse natural language and perform START triage.
  Future<PatientAssessment> parseAndAssess(String description) async {
    const String prompt = '''
Extract medical assessment parameters from this disaster scenario description.
Respond ONLY with a JSON object containing:
- is_walking (bool)
- is_breathing (bool)
- respiratory_rate (int, default 20)
- has_radial_pulse (bool, default true)
- capillary_refill_seconds (int, default 1)
- responds_to_voice (bool)
- responds_to_pain (bool)
- visible_injuries (string)

Description: "{description}"
''';

    try {
      final result = await _gemma.getResponse(
        prompt.replaceFirst('{description}', description),
        temperature: 0.1, // Low temperature for extraction
      );

      if (result.isError) {
        debugPrint('[!] Gemma extraction failed, falling back to regex: ${result.error}');
        return _engine.parseFromDescription(description);
      }

      // Parse JSON from Gemma response
      final jsonStart = result.text.indexOf('{');
      final jsonEnd = result.text.lastIndexOf('}');
      if (jsonStart != -1 && jsonEnd != -1) {
        final jsonStr = result.text.substring(jsonStart, jsonEnd + 1);
        final data = json.decode(jsonStr);

        return _engine.assess(
          isWalking: data['is_walking'] ?? false,
          isBreathing: data['is_breathing'] ?? true,
          respiratoryRate: data['respiratory_rate'] ?? 20,
          hasRadialPulse: data['has_radial_pulse'] ?? true,
          capillaryRefillSeconds: data['capillary_refill_seconds'] ?? 1,
          respondsToVoice: data['responds_to_voice'] ?? true,
          respondsToPain: data['responds_to_pain'] ?? true,
          visibleInjuries: data['visible_injuries'],
        );
      }
    } catch (e) {
      debugPrint('[!] Error in GemmaTriageService: $e');
    }

    // Fallback to regex engine if LLM fails or returns invalid JSON
    return _engine.parseFromDescription(description);
  }

  /// Use Gemma 4 Multimodal to assess a patient from an image.
  Future<PatientAssessment> assessFromImage(Uint8List imageBytes, String? context) async {
    const String query = 'Assess this patient for emergency triage. Is the patient walking? Are they breathing? Any visible severe bleeding or fractures? Provide a concise medical assessment.';
    
    final result = await _gemma.analyzeImage(imageBytes, query);
    
    // Combine vision text with the parser
    return parseAndAssess('${result.text} ${context ?? ""}');
  }
}
