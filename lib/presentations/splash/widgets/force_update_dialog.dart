import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ForceUpdateDialog extends StatelessWidget {
  final String latestVersion;

  const ForceUpdateDialog({super.key, required this.latestVersion});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Update Required', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('A new version ($latestVersion) is available. Please update to continue using the app.'),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _openStore,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Update Now'),
            ),
          ),
        ],
      ),
    );
  }

  void _openStore() async {
    final url = Platform.isAndroid
        ? Uri.parse('https://play.google.com/store/search?q=swoot&c=apps')
        : Uri.parse('https://apps.apple.com/app/id6747494631');
    
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}
