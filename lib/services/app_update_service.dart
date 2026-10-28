import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/api_config.dart';

class AppUpdateInfo {
  final String version;
  final int versionCode;
  final String downloadUrl;
  final List<String> releaseNotes;
  final bool forceUpdate;

  AppUpdateInfo({
    required this.version,
    required this.versionCode,
    required this.downloadUrl,
    required this.releaseNotes,
    required this.forceUpdate,
  });

  factory AppUpdateInfo.fromJson(Map<String, dynamic> json) {
    var rawNotes = json['releaseNotes'];
    List<String> notes = [];
    if (rawNotes is List) {
      notes = rawNotes.map((e) => e.toString()).toList();
    } else if (rawNotes is String && rawNotes.isNotEmpty) {
      notes = [rawNotes];
    }

    return AppUpdateInfo(
      version: json['version'] ?? '1.0.0',
      versionCode: json['versionCode'] ?? 1,
      downloadUrl: json['downloadUrl'] ?? '',
      releaseNotes: notes,
      forceUpdate: json['forceUpdate'] == true,
    );
  }
}

class AppUpdateService {
  static final AppUpdateService instance = AppUpdateService._internal();
  AppUpdateService._internal();

  /// Installed app version details
  static const String currentVersion = '1.0.0';
  static const int currentVersionCode = 1;

  bool _hasPromptedThisSession = false;

  /// Check backend for new version
  Future<void> checkForUpdate(BuildContext context, {bool manual = false}) async {
    if (!manual && _hasPromptedThisSession) return;

    try {
      final endpoint = Uri.parse('${ApiConfig.baseUrl}/app/version');
      final response = await http.get(endpoint).timeout(const Duration(seconds: 4));

      if (response.statusCode != 200) return;

      final data = json.decode(response.body);
      if (data['success'] != true) return;

      final updateInfo = AppUpdateInfo.fromJson(data);

      if (_isUpdateAvailable(updateInfo)) {
        if (!context.mounted) return;
        _hasPromptedThisSession = true;
        _showUpdateDialog(context, updateInfo);
      } else if (manual) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You are on the latest version of RentBox!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      debugPrint('[AppUpdateService] Error checking for updates: $e');
      if (manual && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not check for updates. Check server connection.'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  bool _isUpdateAvailable(AppUpdateInfo info) {
    if (info.versionCode > currentVersionCode) return true;
    return _compareSemver(info.version, currentVersion) > 0;
  }

  int _compareSemver(String a, String b) {
    final aParts = a.split('.').map((p) => int.tryParse(p) ?? 0).toList();
    final bParts = b.split('.').map((p) => int.tryParse(p) ?? 0).toList();

    for (int i = 0; i < 3; i++) {
      final aVal = i < aParts.length ? aParts[i] : 0;
      final bVal = i < bParts.length ? bParts[i] : 0;
      if (aVal > bVal) return 1;
      if (aVal < bVal) return -1;
    }
    return 0;
  }

  void _showUpdateDialog(BuildContext context, AppUpdateInfo info) {
    showDialog(
      context: context,
      barrierDismissible: !info.forceUpdate,
      builder: (ctx) {
        return PopScope(
          canPop: !info.forceUpdate,
          child: Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            elevation: 16,
            backgroundColor: Colors.white,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header Icon
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.system_update_rounded,
                      size: 38,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Title
                  Text(
                    'New Update Available!',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1E293B),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  // Version badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'v${info.version} • Current: v$currentVersion',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF4F46E5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Release notes box
                  if (info.releaseNotes.isNotEmpty) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "What's New:",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF475569),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: info.releaseNotes.map((note) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('✨ ', style: TextStyle(fontSize: 12)),
                                Expanded(
                                  child: Text(
                                    note,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12.5,
                                      color: const Color(0xFF334155),
                                      height: 1.35,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Action Buttons
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () async {
                        final uri = Uri.parse(info.downloadUrl);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'Download & Update',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),

                  if (!info.forceUpdate) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF64748B),
                      ),
                      child: Text(
                        'Maybe Later',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
