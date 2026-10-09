import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../core/constants/api_endpoints.dart';
import '../core/constants/app_colors.dart';
import '../core/services/storage_service.dart';

class ServerSettingsDialog extends StatefulWidget {
  const ServerSettingsDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => const ServerSettingsDialog(),
    );
  }

  @override
  State<ServerSettingsDialog> createState() => _ServerSettingsDialogState();
}

class _ServerSettingsDialogState extends State<ServerSettingsDialog> {
  final _urlController = TextEditingController();
  bool _isTesting = false;
  String? _testResult;
  bool _testSuccess = false;

  @override
  void initState() {
    super.initState();
    _urlController.text = ApiEndpoints.baseUrl;
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _testConnection(String url) async {
    setState(() {
      _isTesting = true;
      _testResult = null;
    });

    String target = url.trim();
    if (!target.startsWith('http://') && !target.startsWith('https://')) {
      target = 'http://$target';
    }
    while (target.endsWith('/')) {
      target = target.substring(0, target.length - 1);
    }
    if (!target.endsWith('/api')) {
      target = '$target/api';
    }

    try {
      final healthUri = Uri.parse('$target/health');
      final response = await http.get(healthUri).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        setState(() {
          _isTesting = false;
          _testSuccess = true;
          _testResult = 'सर्वर सफलतापूर्वक कनेक्ट हो गया! (Server Connected)';
        });
      } else {
        setState(() {
          _isTesting = false;
          _testSuccess = false;
          _testResult = 'Server returned HTTP ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _isTesting = false;
        _testSuccess = false;
        _testResult = 'कनेक्शन विफल (Connection failed): $e';
      });
    }
  }

  Future<void> _saveSettings() async {
    final text = _urlController.text.trim();
    if (text.isEmpty) {
      ApiEndpoints.setCustomBaseUrl(null);
      await StorageService.saveBaseUrl('');
    } else {
      ApiEndpoints.setCustomBaseUrl(text);
      await StorageService.saveBaseUrl(ApiEndpoints.baseUrl);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Server URL set to: ${ApiEndpoints.baseUrl}'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.dns_rounded, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'सर्वर सेटिंग्स (Server URL)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'यदि ऐप कनेक्ट नहीं हो रहा है, तो सही सर्वर IP चुनें:',
              style: TextStyle(
                fontSize: 12.5,
                color: isDark ? Colors.white70 : const Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 14),

            // URL input
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                labelText: 'Backend API URL',
                hintText: 'http://192.168.0.206:5050/api',
                prefixIcon: const Icon(Icons.link_rounded),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                isDense: true,
              ),
              style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
            ),
            const SizedBox(height: 12),

            // Quick Preset Buttons
            const Text(
              'क्विक प्रीसेट (Quick Presets):',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _buildPresetChip('🌐 Cloud Tunnel (Recommended)', 'https://map-furniture-ideal-fall.trycloudflare.com/api'),
                _buildPresetChip('📱 Wi-Fi (192.168.0.206)', 'http://192.168.0.206:5050/api'),
                _buildPresetChip('💻 Emulator (10.0.2.2)', 'http://10.0.2.2:5050/api'),
                _buildPresetChip('🔌 Localhost (127.0.0.1)', 'http://localhost:5050/api'),
              ],
            ),
            const SizedBox(height: 14),

            // Test button & result
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: _isTesting
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.network_check_rounded, size: 18),
                    label: Text(_isTesting ? 'Testing...' : 'Test Connection'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _isTesting ? null : () => _testConnection(_urlController.text),
                  ),
                ),
              ],
            ),

            if (_testResult != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _testSuccess
                      ? AppColors.success.withOpacity(0.12)
                      : AppColors.error.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _testSuccess ? AppColors.success : AppColors.error,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      _testSuccess ? Icons.check_circle_outline : Icons.error_outline,
                      size: 18,
                      color: _testSuccess ? AppColors.success : AppColors.error,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _testResult!,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: _testSuccess ? AppColors.success : AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('रद्द करें (Cancel)'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: _saveSettings,
          child: const Text('सेव करें (Save)'),
        ),
      ],
    );
  }

  Widget _buildPresetChip(String label, String url) {
    final isSelected = _urlController.text.trim() == url;
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      backgroundColor: isSelected ? AppColors.primary.withOpacity(0.18) : null,
      side: BorderSide(
        color: isSelected ? AppColors.primary : Colors.grey.withOpacity(0.3),
      ),
      onPressed: () {
        setState(() {
          _urlController.text = url;
          _testResult = null;
        });
      },
    );
  }
}
