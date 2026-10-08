import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../providers/locale_provider.dart';
import '../providers/theme_provider.dart';

class LanguageThemeToggle extends StatelessWidget {
  const LanguageThemeToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProv = Provider.of<LocaleProvider>(context);
    final themeProv = Provider.of<ThemeProvider>(context);
    final isDark = themeProv.isDarkMode;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Language Selector Pill
        InkWell(
          onTap: () => localeProv.toggleLocale(),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.language, size: 16, color: AppColors.primary),
                const SizedBox(width: 4),
                Text(
                  localeProv.isHindi ? 'हिन्दी' : 'EN',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Dark/Light Mode Icon Button
        IconButton(
          icon: Icon(
            isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            size: 20,
            color: isDark ? const Color(0xFFFBBF24) : AppColors.textSecondaryLight,
          ),
          onPressed: () => themeProv.toggleTheme(),
          tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
        ),
      ],
    );
  }
}
