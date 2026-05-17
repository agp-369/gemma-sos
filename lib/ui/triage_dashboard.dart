import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/gemma_service.dart';
import '../services/gps_service.dart';
import '../services/mesh_service.dart';
import './widgets/wreckage_analyzer.dart';
import './medical_triage_screen.dart' as medical;
import './offline_maps_screen.dart';
import './sos_screen.dart';

class TriageDashboard extends StatefulWidget {
  const TriageDashboard({super.key});

  @override
  State<TriageDashboard> createState() => _TriageDashboardState();
}

class _TriageDashboardState extends State<TriageDashboard> {
  final GemmaInferenceService _gemma = GemmaInferenceService();
  final GpsService _gps = GpsService();
  bool _isInitializing = true;
  bool _gpsReady = false;
  String _statusMessage = 'Waking engine...';

  @override
  void initState() {
    super.initState();
    _initSystem();
  }

  Future<void> _initSystem() async {
    try {
      setState(() => _statusMessage = 'Gemma 4 Heartbeat...');
      await _gemma.initialize();

      setState(() => _statusMessage = 'Acquiring GPS...');
      _gpsReady = await _gps.initialize();
    } catch (e) {
      debugPrint('[!] Init error: $e');
      _statusMessage = 'System error: ${e.toString().substring(0, 80)}';
    }

    if (mounted) {
      setState(() {
        _isInitializing = false;
        if (!_gemma.isInitialized && _statusMessage.startsWith('System error')) {
          // keep the error message
        } else if (!_gpsReady) {
          _statusMessage = 'GPS Signal Lost — Triage still available';
        } else {
          _statusMessage = 'Sovereign Node Active';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: Text(
              'KINTSUGI SOS',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                letterSpacing: 4.0,
                color: const Color(0xFFD4AF37),
              ),
            ),
            backgroundColor: const Color(0xFF0F0F0F),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.hub_outlined, color: Color(0xFFD4AF37)),
                onPressed: () => _showSystemStatus(context),
              ),
            ],
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildStatusHeader(),
                  const SizedBox(height: 32),
                  _buildHeroTriageCard(),
                  const SizedBox(height: 32),
                  _buildToolGrid(),
                  const Spacer(),
                  _buildSovereignFooter(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          _isInitializing
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFD4AF37)),
                )
              : const Icon(Icons.radar, color: Color(0xFFD4AF37), size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _statusMessage.toUpperCase(),
                  style: TextStyle(
                    color: const Color(0xFFD4AF37),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const Text(
                  'DECENTRALIZED MESH NODE #72-A',
                  style: TextStyle(color: Colors.grey, fontSize: 10, letterSpacing: 2),
                ),
              ],
            ),
          ),
          const Badge(
            label: Text('OFFLINE'),
            backgroundColor: Color(0xFF8B0000),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroTriageCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFFD4AF37).withValues(alpha: 0.1), Colors.transparent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFD4AF37), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD4AF37).withValues(alpha: 0.05),
            blurRadius: 20,
            spreadRadius: 5,
          )
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const medical.MedicalTriageScreen()),
          );
        },
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            children: [
              const Icon(Icons.healing_outlined, color: Color(0xFFD4AF37), size: 64),
              const SizedBox(height: 16),
              Text(
                'AMABIE TRIAGE',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFFD4AF37),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Sovereign START Protocol. AI-guided assessment for mass casualty incidents. Hardware-accelerated on-device reasoning.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF37),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'BEGIN ASSESSMENT',
                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, letterSpacing: 2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildToolTile(
          icon: Icons.remove_red_eye_outlined,
          label: 'TENGU SIGHT',
          sublabel: 'Wreckage Vision',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WreckageAnalyzer())),
        ),
        _buildToolTile(
          icon: Icons.sos,
          label: 'SOS BEACON',
          sublabel: 'Emergency Broadcast',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SosScreen())),
        ),
        _buildToolTile(
          icon: Icons.qr_code_scanner,
          label: 'MESH SYNC',
          sublabel: 'QR Patient Transfer',
          onTap: () => _showSyncDialog(context),
        ),
        _buildToolTile(
          icon: Icons.explore_outlined,
          label: 'KITSUNE MAP',
          sublabel: 'Offline Resources',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OfflineMapsScreen())),
        ),
      ],
    );
  }

  Widget _buildToolTile({required IconData icon, required String label, required String sublabel, required VoidCallback onTap}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF333333)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: const Color(0xFFD4AF37), size: 24),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold, fontSize: 12)),
              Text(sublabel, style: const TextStyle(color: Colors.grey, fontSize: 10)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSovereignFooter() {
    return Column(
      children: [
        const Divider(color: Color(0xFF333333)),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_outlined, color: Colors.grey, size: 14),
            const SizedBox(width: 8),
              Text(
                'GRID-INDEPENDENT INTELLIGENCE',
                style: TextStyle(color: Colors.grey, fontSize: 10, letterSpacing: 3),
              ),
          ],
        ),
      ],
    );
  }

  void _showSyncDialog(BuildContext context) {
    final mesh = MeshService();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('MESH SYNC', style: TextStyle(color: Color(0xFFD4AF37))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Share patient data with nearby responders via QR code.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final payload = await mesh.generateSyncPayload();
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                  _showQrCode(context, payload);
                },
                icon: const Icon(Icons.qr_code, size: 18),
                label: const Text('GENERATE EXPORT QR'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4AF37),
                  foregroundColor: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _showImportDialog(context);
                },
                icon: const Icon(Icons.download, size: 18),
                label: const Text('IMPORT FROM QR SCAN'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFD4AF37),
                  side: const BorderSide(color: Color(0xFFD4AF37)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showQrCode(BuildContext context, String payload) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('SCAN TO SYNC', style: TextStyle(color: Color(0xFFD4AF37))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Show this QR code to another responder.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 16),
            QrImageView(
              data: payload,
              version: QrVersions.auto,
              size: 200,
              backgroundColor: Colors.white,
              padding: const EdgeInsets.all(12),
            ),
            const SizedBox(height: 12),
            Text(
              '${payload.length} chars | ${(payload.length * 0.75).round()} bytes',
              style: const TextStyle(color: Colors.grey, fontSize: 10),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showImportDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('IMPORT SYNC', style: TextStyle(color: Color(0xFFD4AF37))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Paste the QR code content received from another device, or scan using QR Scanner.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Paste sync payload here...',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              maxLines: 3,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) return;
              final mesh = MeshService();
              final count = await mesh.processSyncPayload(controller.text.trim());
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(count > 0
                      ? 'Imported $count patients'
                      : count == 0
                          ? 'No new patients to import'
                          : 'Invalid sync data'),
                  backgroundColor: count > 0 ? const Color(0xFF2E7D32) : const Color(0xFF8B0000),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4AF37),
              foregroundColor: Colors.black,
            ),
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }

  void _showSystemStatus(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('System Status', style: TextStyle(color: Color(0xFFD4AF37))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _statusRow('Gemma 4 Engine',
                _gemma.isInitialized ? 'Ready' : 'Offline'),
            _statusRow('GPS', _gpsReady ? 'Acquired' : 'Unavailable'),
            _statusRow(
                'Model', _gemma.isModelLoaded ? 'Loaded' : 'Not loaded'),
            _statusRow('Inferences', '${_gemma.totalInferences}'),
            if (_gemma.lastError.isNotEmpty)
              _statusRow('Last Error', _gemma.lastError),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _statusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.white)),
          Text(value, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
