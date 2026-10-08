import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';
import '../worker/worker_main_navigation.dart';
import '../admin/admin_main_navigation.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuth();
    });
  }

  Future<void> _checkAuth() async {
    final authProv = Provider.of<AuthProvider>(context, listen: false);
    await authProv.initAuth();

    if (!mounted) return;

    if (authProv.isAuthenticated && authProv.currentUser != null) {
      if (authProv.isAdmin) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AdminMainNavigation()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const WorkerMainNavigation()),
        );
      }
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.1,
            colors: [
              Color(0xFF1E3A8A), // Vibrant Royal Blue center
              Color(0xFF0C2461), // Deep Navy Blue
              Color(0xFF060E1E), // Midnight Navy Outer
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Gold-bordered emblem container
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF0C2461),
                      border: Border.all(
                        color: AppColors.accentLight,
                        width: 3.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accent.withOpacity(0.4),
                          blurRadius: 28,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.door_sliding_rounded,
                      size: 60,
                      color: AppColors.accentLight,
                    ),
                  ),
                  const SizedBox(height: 26),

                  // Brand Name - Top in Gold, Bottom in White
                  const Text(
                    'श्री लक्ष्मीनारायण',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFFBBF24),
                      letterSpacing: 1.2,
                      shadows: [
                        Shadow(
                          color: Colors.black54,
                          offset: Offset(0, 3),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'एल्युमिनियम वर्क्स',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 1.5,
                      shadows: [
                        Shadow(
                          color: Colors.black45,
                          offset: Offset(0, 2),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Tagline in Golden Pill Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Text(
                      'मजबूती भी, सुंदरता भी – बस हमारे साथ !',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF071739),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 52),

                  const SizedBox(
                    width: 36,
                    height: 36,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFBBF24)),
                      strokeWidth: 3.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
