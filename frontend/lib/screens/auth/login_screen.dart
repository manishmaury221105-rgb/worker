import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../widgets/company_logo.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/language_theme_toggle.dart';
import '../../widgets/server_settings_dialog.dart';
import '../admin/admin_main_navigation.dart';
import '../worker/worker_main_navigation.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authProv = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProv.login(
      _identifierController.text,
      _passwordController.text,
    );

    if (!mounted) return;

    if (success && authProv.currentUser != null) {
      if (authProv.isAdmin) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AdminMainNavigation()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const WorkerMainNavigation()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localeProv = Provider.of<LocaleProvider>(context);
    final authProv = Provider.of<AuthProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.dns_rounded, size: 20),
            tooltip: 'Server Settings (सर्वर सेटिंग्स)',
            onPressed: () => ServerSettingsDialog.show(context),
          ),
          const Padding(
            padding: EdgeInsets.only(right: 16),
            child: LanguageThemeToggle(),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Official Brand Logo with Gold Border & Navy Shadow
                    const Center(
                      child: CompanyLogo(
                        size: 88,
                        borderWidth: 2.5,
                        borderColor: Color(0xFFFBBF24),
                        hasShadow: true,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Title
                    Column(
                      children: [
                        Text(
                          'श्री लक्ष्मीनारायण',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706),
                            letterSpacing: 0.8,
                          ),
                        ),
                        Text(
                          'एल्युमिनियम वर्क्स',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : AppColors.primary,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Tagline pill badge
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(isDark ? 0.2 : 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.accent.withOpacity(0.5),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          localeProv.tr('app_tagline'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Error message
                    if (authProv.errorMessage != null)
                      ErrorBanner(
                        message: authProv.errorMessage!,
                        onDismiss: () => authProv.login('', ''),
                      ),

                    // Input Form Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDark : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark ? AppColors.borderDark : AppColors.borderLight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomTextField(
                            label: localeProv.tr('phone_number'),
                            hint: '9876543201',
                            controller: _identifierController,
                            prefixIcon: Icons.phone_android_rounded,
                            keyboardType: TextInputType.phone,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Please enter mobile number';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 18),
                          CustomTextField(
                            label: localeProv.tr('password'),
                            hint: '••••••••',
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            prefixIcon: Icons.lock_outline,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                size: 20,
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Please enter password';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          CustomButton(
                            text: localeProv.tr('login'),
                            icon: Icons.login_rounded,
                            isLoading: authProv.isLoading,
                            onPressed: _handleLogin,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Official Company Contact & Address Footer
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0D1E3A) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark ? const Color(0xFF1E3560) : const Color(0xFFCBD5E1),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Icon(Icons.phone_in_talk_rounded, size: 14, color: Color(0xFFF59E0B)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'अजय मौर्य: 9695718820 | विजय मौर्य: 99670 80639\nराज कुमार मौर्य: 98928 26110',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    height: 1.35,
                                    color: isDark ? Colors.white70 : const Color(0xFF0F172A),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.location_on_rounded, size: 14, color: Color(0xFFEF4444)),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'घमहापुर, चोरारी, जलालपुर रोड, मड़ियाहूँ, जौनपुर',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
