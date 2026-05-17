import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/gps_service.dart';
import '../services/gemma_service.dart';

class SosScreen extends StatefulWidget {
  const SosScreen({super.key});

  @override
  State<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen>
    with SingleTickerProviderStateMixin {
  final GpsService _gps = GpsService();
  final GemmaInferenceService _gemma = GemmaInferenceService();
  bool _isBroadcasting = false;
  bool _hasAlerted = false;
  String _message = '';
  Timer? _blinkTimer;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _startSOS() async {
    HapticFeedback.heavyImpact();

    setState(() {
      _isBroadcasting = true;
      _message = 'Generating golden SOS...';
    });
    _pulseController.repeat(reverse: true);

    try {
      final latLng = await _gps.getCurrentPosition();

      setState(() {
        _message =
            'SITUATION REPORT\n'
            'Location: ${latLng.latitude.toStringAsFixed(4)}, ${latLng.longitude.toStringAsFixed(4)}\n'
            'Time: ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')} IST\n'
            'Nearest help: Share coordinates via radio or show to nearby responders.';
        _hasAlerted = true;
      });
    } catch (e) {
      setState(() {
        _message =
            'SITUATION REPORT\n'
            'Time: ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')} IST\n'
            'GPS unavailable. Share your location verbally with responders.';
        _hasAlerted = true;
      });
    }
  }

  void _stopSOS() {
    _pulseController.stop();
    _blinkTimer?.cancel();
    setState(() {
      _isBroadcasting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        title: const Text('SOS BROADCAST', style: TextStyle(letterSpacing: 2)),
        backgroundColor: const Color(0xFF8B0000), // Crimson
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isBroadcasting)
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Container(
                          width: 200 + _pulseController.value * 40,
                          height: 200 + _pulseController.value * 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF8B0000)
                                .withAlpha(( (0.3 - _pulseController.value * 0.2) * 255 ).toInt()),
                          ),
                          child: child,
                        );
                      },
                      child: const Icon(Icons.sos,
                          size: 80, color: Colors.white),
                    )
                  else
                    const Icon(Icons.sos,
                        size: 80, color: Color(0xFF8B0000)),

                  const SizedBox(height: 24),

                  Text(
                    _isBroadcasting ? 'BROADCASTING ACTIVE' : 'EMERGENCY BEACON',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),

                  const SizedBox(height: 16),

                  if (_message.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 32),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFD4AF37)),
                      ),
                      child: SelectableText(
                        _message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xFFE0E0E0), fontSize: 13, height: 1.5),
                      ),
                    ),

                  const SizedBox(height: 24),

                  if (_hasAlerted)
                    const Text(
                      'READY FOR MESH TRANSMISSION',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                ],
              ),
            ),
          ),

          // SOS button
          Padding(
            padding: const EdgeInsets.all(32),
            child: SizedBox(
              width: double.infinity,
              height: 64,
              child: ElevatedButton.icon(
                onPressed: _isBroadcasting ? _stopSOS : _startSOS,
                icon: Icon(_isBroadcasting ? Icons.stop : Icons.sos, color: Colors.white),
                label: Text(
                    _isBroadcasting ? 'STOP BEACON' : 'ACTIVATE SOS'),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _isBroadcasting ? Colors.grey : const Color(0xFF8B0000),
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(
                      fontWeight: FontWeight.w900, letterSpacing: 2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
