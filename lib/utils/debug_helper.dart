import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DebugHelper {
  static void showConfigurationError(BuildContext context, String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Google Sign-In Configuration Error"),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "The app failed to sign in with Google (ApiException: 10). This is almost always a configuration mismatch in the Google Cloud Console.",
                style: TextStyle(color: Colors.redAccent),
              ),
              const SizedBox(height: 16),
              const Text("PLEASE VERIFY THE FOLLOWING IN GOOGLE CLOUD CONSOLE:", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildInfoRow("Package Name:", "com.example.frontend_game"),
              const SizedBox(height: 8),
              _buildInfoRow("SHA-1 Certificate:", "75:B1:3D:BD:FB:A4:C3:8D:AF:24:FB:F9:EE:EA:34:60:84:C0:C3:7E"),
              const SizedBox(height: 16),
              const Text("instructions:", style: TextStyle(fontWeight: FontWeight.bold)),
              const Text("1. Go to console.cloud.google.com/apis/credentials"),
              const Text("2. Open the 'Android' client."),
              const Text("3. Ensure the Package Name and SHA-1 match EXACTLY."),
              const Text("4. If they match, click 'Save' again."),
              const SizedBox(height: 16),
              const Text("Raw Error:"),
              Text(error, style: const TextStyle(fontSize: 10, fontFamily: 'monospace')),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("OK"),
          ),
          TextButton(
            onPressed: () {
               Clipboard.setData(const ClipboardData(text: "75:B1:3D:BD:FB:A4:C3:8D:AF:24:FB:F9:EE:EA:34:60:84:C0:C3:7E"));
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("SHA-1 Copied to Clipboard!")));
            },
            child: const Text("COPY SHA-1"),
          ),
        ],
      ),
    );
  }

  static Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        SelectableText(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace'),
        ),
      ],
    );
  }
}
