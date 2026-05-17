import 'package:flutter/material.dart';
import 'package:gemma_sos/services/gemma_service.dart';
import 'package:gemma_sos/ui/triage_dashboard.dart';
import 'package:flutter_gemma/flutter_gemma.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GemmaSOSApp());
}

class GemmaSOSApp extends StatelessWidget {
  const GemmaSOSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gemma-SOS: Kintsugi Protocol',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      home: const _SplashScreen(),
    );
  }

  static ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0F0F0F),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFD4AF37),
        secondary: Color(0xFF8B0000),
        surface: Color(0xFF1A1A1A),
        onPrimary: Colors.black,
        onSecondary: Colors.white,
      ),
      textTheme: ThemeData.dark().textTheme.apply(
        bodyColor: const Color(0xFFE0E0E0),
        displayColor: const Color(0xFFD4AF37),
        fontFamily: 'sans-serif',
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1A1A1A),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF333333), width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0F0F0F),
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Color(0xFFD4AF37),
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFD4AF37),
          foregroundColor: Colors.black,
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}

class _SplashScreen extends StatefulWidget {
  const _SplashScreen();
  @override
  State<_SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<_SplashScreen>
    with SingleTickerProviderStateMixin {
  String _status = 'Initializing Kintsugi Protocol...';
  bool _hasError = false;
  bool _ready = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _fadeController.forward();
    _init();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    try {
      await FlutterGemma.initialize();
      if (!mounted) return;
      setState(() => _status = 'Waking Gemma 4 engine...');

      final gemma = GemmaInferenceService();
      await gemma.initialize(onStatus: (msg) {
        if (mounted) setState(() => _status = msg);
      }).timeout(const Duration(minutes: 5));
      if (!mounted) return;

      setState(() => _ready = true);
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const TriageDashboard()),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        final msg = e.toString();
        _status = msg.length > 300 ? msg.substring(0, 300) : msg;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFD4AF37), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(Icons.healing_outlined, color: Color(0xFFD4AF37), size: 48),
              ),
              const SizedBox(height: 32),
              const Text(
                'KINTSUGI PROTOCOL',
                style: TextStyle(
                  color: Color(0xFFD4AF37),
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'SOVEREIGN RESCUE INTELLIGENCE',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 10,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 48),
              if (_hasError)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    children: [
                      const Icon(Icons.error_outline, color: Color(0xFF8B0000), size: 32),
                      const SizedBox(height: 12),
                      Text(
                        _status,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xFF8B0000), fontSize: 12),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _hasError = false;
                            _status = 'Retrying...';
                          });
                          _init();
                        },
                        child: const Text('RETRY'),
                      ),
                    ],
                  ),
                )
              else
                Column(
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _ready ? Colors.green : const Color(0xFFD4AF37),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _status,
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
