import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import '../services/triage_engine.dart';
import '../services/gemma_triage_service.dart';
import '../services/patient_repository.dart';
import '../services/mesh_service.dart';

class MedicalTriageScreen extends StatefulWidget {
  const MedicalTriageScreen({super.key});

  @override
  State<MedicalTriageScreen> createState() => _MedicalTriageScreenState();
}

class _MedicalTriageScreenState extends State<MedicalTriageScreen> {
  final TriageEngine _triage = TriageEngine();
  final GemmaTriageService _gemmaTriage = GemmaTriageService();
  final PatientRepository _repo = PatientRepository();
  final MeshService _mesh = MeshService();
  
  List<PatientAssessment> _patients = [];
  final TextEditingController _descController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  // Assessment form state
  bool? _isWalking;
  bool? _isBreathing;
  double _respRate = 20;
  bool? _hasRadialPulse;
  double _capRefill = 1;
  bool? _respondsToVoice;
  bool? _respondsToPain;
  String _visibleInjuries = '';
  bool _isAssessing = false;
  XFile? _cameraImage;

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  Future<void> _loadPatients() async {
    final patients = await _repo.getAllPatients();
    if (mounted) {
      setState(() => _patients = patients);
    }
  }

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  Future<void> _performTriage() async {
    if (_isWalking == null || _isBreathing == null ||
        _hasRadialPulse == null || _respondsToVoice == null ||
        _respondsToPain == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Set all assessment fields before triaging'),
          backgroundColor: Color(0xFF8B0000),
        ),
      );
      return;
    }

    setState(() => _isAssessing = true);

    try {
      final assessment = _triage.assess(
        isWalking: _isWalking!,
        isBreathing: _isBreathing!,
        respiratoryRate: _respRate.round(),
        hasRadialPulse: _hasRadialPulse!,
        capillaryRefillSeconds: _capRefill.round(),
        respondsToVoice: _respondsToVoice!,
        respondsToPain: _respondsToPain!,
        visibleInjuries: _visibleInjuries.isNotEmpty ? _visibleInjuries : null,
      );

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: Text('Confirm ${assessment.category.code}',
            style: TextStyle(
              color: _categoryColor(assessment.category),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(assessment.category.description,
                style: const TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 12),
              _confirmField('Walking', assessment.isWalking),
              _confirmField('Breathing', assessment.isBreathing),
              _confirmField('Resp Rate', '${assessment.respiratoryRate}/min'),
              _confirmField('Radial Pulse', assessment.hasRadialPulse),
              _confirmField('Cap Refill', '${assessment.capillaryRefillSeconds}s'),
              _confirmField('Responds to Voice', assessment.respondsToVoice),
              _confirmField('Responds to Pain', assessment.respondsToPain),
              if (assessment.visibleInjuries != null)
                _confirmField('Injuries', assessment.visibleInjuries!),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37),
                foregroundColor: Colors.black,
              ),
              child: const Text('Save Assessment'),
            ),
          ],
        ),
      );

      if (confirmed != true) {
        if (mounted) setState(() => _isAssessing = false);
        return;
      }

      await _repo.insertPatient(assessment);
      await _loadPatients();
      if (mounted) {
        setState(() {
          _isAssessing = false;
          _resetForm();
        });
      }
    } catch (e) {
      debugPrint('[!] Triage save error: $e');
      if (mounted) setState(() => _isAssessing = false);
    }
  }

  Widget _confirmField(String label, dynamic value) {
    final display = value is bool ? (value ? 'Yes' : 'No') : value.toString();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(color: Colors.grey, fontSize: 12)),
          Text(display, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Future<void> _parseFromDescription() async {
    final text = _descController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isAssessing = true);

    try {
      final assessment = await _gemmaTriage.parseAndAssess(text)
          .timeout(const Duration(seconds: 90));
      await _repo.insertPatient(assessment);
      await _loadPatients();
    } catch (e) {
      debugPrint('[!] AI analysis timeout/error, using fallback: $e');
      final assessment = _triage.parseFromDescription(text);
      await _repo.insertPatient(assessment);
      await _loadPatients();
    }

    if (mounted) {
      setState(() {
        _isAssessing = false;
        _descController.clear();
      });
    }
  }

  Future<void> _assessFromCamera() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image == null) return;

    setState(() => _cameraImage = image);
  }

  Future<void> _analyzeCameraImage() async {
    if (_cameraImage == null) return;

    setState(() => _isAssessing = true);

    final bytes = await _cameraImage!.readAsBytes();
    final assessment = await _gemmaTriage.assessFromImage(bytes, _descController.text);
    await _repo.insertPatient(assessment);
    await _loadPatients();

    if (mounted) {
      setState(() {
        _isAssessing = false;
        _cameraImage = null;
      });
    }
  }

  void _showSyncDialog() async {
    final payload = await _mesh.generateSyncPayload();
    
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Mesh Sync', style: TextStyle(color: Color(0xFFD4AF37))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Share your triage log with another responder.', style: TextStyle(color: Colors.white, fontSize: 13)),
            const SizedBox(height: 20),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(10),
              child: QrImageView(
                data: payload,
                version: QrVersions.auto,
                size: 200.0,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _scanSyncQr();
              },
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Scan to Sync'),
            ),
          ],
        ),
      ),
    );
  }

  void _scanSyncQr() {
    final scaffold = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => Scaffold(
          appBar: AppBar(title: const Text('Scan Sync QR')),
          body: QRView(
            key: GlobalKey(debugLabel: 'QR'),
            onQRViewCreated: (controller) {
              controller.scannedDataStream.listen((scanData) async {
                controller.pauseCamera();
                final count = await _mesh.processSyncPayload(scanData.code ?? '');
                
                navigator.pop();
                scaffold.showSnackBar(
                  SnackBar(content: Text(count >= 0 ? 'Synced $count new patient records.' : 'Sync failed. Invalid data.')),
                );
                _loadPatients();
              });
            },
          ),
        ),
      ),
    );
  }

  void _resetForm() {
    setState(() {
      _isWalking = null;
      _isBreathing = null;
      _respRate = 20;
      _hasRadialPulse = null;
      _capRefill = 1;
      _respondsToVoice = null;
      _respondsToPain = null;
      _visibleInjuries = '';
      _cameraImage = null;
    });
  }

  Color _categoryColor(TriageCategory cat) {
    switch (cat) {
      case TriageCategory.immediate:
        return Colors.red;
      case TriageCategory.delayed:
        return const Color(0xFFD4AF37); // Gold
      case TriageCategory.minimal:
        return Colors.green;
      case TriageCategory.deceased:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medical Triage'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync, color: Color(0xFFD4AF37)),
            onPressed: _showSyncDialog,
          ),
          TextButton(
            onPressed: _patients.isEmpty
                ? null
                : () async {
                    await _repo.clearAll();
                    _loadPatients();
                  },
            child: const Text('Clear'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Triage form
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Kintsugi Triage Engine',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFD4AF37),
                            ),
                      ),
                      const Badge(
                        label: Text('OFFLINE'),
                        backgroundColor: Color(0xFF8B0000),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Unified assessment using START protocol + Gemma 4',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                  const SizedBox(height: 16),

                  // Quick description input
                  TextField(
                    controller: _descController,
                    decoration: InputDecoration(
                      labelText: 'Sovereign Input (Natural Language)',
                      hintText: 'e.g., "Patient not walking, weak pulse"',
                      border: const OutlineInputBorder(),
                      isDense: true,
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.camera_alt, color: Color(0xFFD4AF37)),
                        onPressed: _assessFromCamera,
                        tooltip: 'Multimodal Assessment',
                      ),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _isAssessing ? null : _parseFromDescription,
                    icon: _isAssessing
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                        : const Icon(Icons.auto_awesome, size: 18),
                    label: Text(_isAssessing ? 'Analyzing... (up to 90s)' : 'AI Analysis'),
                  ),

                  // Camera preview
                  if (_cameraImage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              File(_cameraImage!.path),
                              height: 180,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => setState(() => _cameraImage = null),
                                  icon: const Icon(Icons.refresh, size: 16),
                                  label: const Text('Retake', style: TextStyle(fontSize: 12)),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.grey,
                                    side: const BorderSide(color: Color(0xFF333333)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _isAssessing ? null : _analyzeCameraImage,
                                  icon: _isAssessing
                                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                                      : const Icon(Icons.auto_awesome, size: 16),
                                  label: Text(_isAssessing ? 'Analyzing...' : 'Analyze Image', style: const TextStyle(fontSize: 12)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFD4AF37),
                                    foregroundColor: Colors.black,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                  const Divider(height: 24, color: Color(0xFF333333)),
                  const Text('START ASSESSMENT', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                  const SizedBox(height: 12),

                  // Row 1: Walking + Breathing
                  Row(
                    children: [
                      Expanded(child: _quickToggle('Walking', _isWalking, (v) => setState(() => _isWalking = v))),
                      const SizedBox(width: 8),
                      Expanded(child: _quickToggle('Breathing', _isBreathing, (v) => setState(() => _isBreathing = v))),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Row 2: Radial Pulse + Mental Status
                  Row(
                    children: [
                      Expanded(child: _quickToggle('Radial Pulse', _hasRadialPulse, (v) => setState(() => _hasRadialPulse = v))),
                      const SizedBox(width: 8),
                      Expanded(child: _quickToggle('Responds Voice', _respondsToVoice, (v) => setState(() => _respondsToVoice = v))),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Row 3: Pain Response
                  Row(
                    children: [
                      Expanded(child: _quickToggle('Responds Pain', _respondsToPain, (v) => setState(() => _respondsToPain = v))),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFF333333)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              const Text('Resp Rate', style: TextStyle(fontSize: 10, color: Colors.grey)),
                              Text('${_respRate.round()}/min', style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Respiratory rate slider + Cap refill slider
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 2,
                                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                              ),
                              child: Slider(
                                value: _respRate,
                                min: 0,
                                max: 50,
                                divisions: 50,
                                activeColor: (_respRate > 30 || _respRate < 10) ? const Color(0xFF8B0000) : const Color(0xFFD4AF37),
                                inactiveColor: const Color(0xFF333333),
                                label: '${_respRate.round()}',
                                onChanged: (v) => setState(() => _respRate = v),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 60,
                        child: Column(
                          children: [
                            const Text('Cap Refill', style: TextStyle(fontSize: 10, color: Colors.grey)),
                            Text('${_capRefill.round()}s', style: TextStyle(fontSize: 12, color: _capRefill > 2 ? const Color(0xFF8B0000) : Colors.white, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 2,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                    ),
                    child: Slider(
                      value: _capRefill,
                      min: 0,
                      max: 5,
                      divisions: 10,
                      activeColor: _capRefill > 2 ? const Color(0xFF8B0000) : const Color(0xFFD4AF37),
                      inactiveColor: const Color(0xFF333333),
                      label: '${_capRefill.round()}s',
                      onChanged: (v) => setState(() => _capRefill = v),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _isAssessing ? null : _performTriage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B0000),
                      foregroundColor: Colors.white,
                    ),
                    child: Text(_isAssessing ? 'Assessing...' : 'RUN START PROTOCOL'),
                  ),
                ],
              ),
            ),
          ),

          // Patient list
          Expanded(
            child: _patients.isEmpty
                ? const Center(child: Text('No patients triaged yet.', style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _patients.length,
                    itemBuilder: (context, index) {
                      final p = _patients[index];
                      final isHighConfidence = p.confidenceScore >= 0.8;
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(12),
                          border: isHighConfidence 
                            ? Border.all(color: const Color(0xFFD4AF37), width: 1.5) // Golden Glow
                            : Border.all(color: const Color(0xFF333333)),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _categoryColor(p.category).withValues(alpha: 0.2),
                            child: Text(
                              p.category.code,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _categoryColor(p.category),
                              ),
                            ),
                          ),
                          title: Text('Patient ${p.id.substring(0, 8)}...', style: const TextStyle(fontSize: 14, color: Colors.white)),
                          subtitle: Text(
                            'Category: ${p.category.description}\n'
                            'Confidence: ${(p.confidenceScore * 100).toStringAsFixed(0)}%',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          trailing: isHighConfidence 
                            ? const Icon(Icons.verified, color: Color(0xFFD4AF37), size: 18)
                            : null,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _quickToggle(String label, bool? value, ValueChanged<bool> onChanged) {
    final isSet = value != null;
    return InkWell(
      onTap: () => onChanged(value != true),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: isSet ? const Color(0xFFD4AF37).withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSet ? const Color(0xFFD4AF37) : const Color(0xFF555555),
            width: isSet ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSet ? (value ? Icons.check_circle : Icons.cancel_outlined) : Icons.help_outline,
              color: isSet ? const Color(0xFFD4AF37) : Colors.grey,
              size: 14,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                isSet ? '$label: ${value ? "Yes" : "No"}' : label,
                style: TextStyle(
                  fontSize: 10,
                  color: isSet ? Colors.white : Colors.grey,
                  fontWeight: isSet ? FontWeight.bold : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
