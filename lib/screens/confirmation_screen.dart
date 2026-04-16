import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'scan_screen.dart';

class ConfirmationScreen extends StatelessWidget {
  final bool success;
  final String message;
  final String? spoolLabel;
  final String? slotLabel;

  const ConfirmationScreen({
    super.key,
    required this.success,
    required this.message,
    this.spoolLabel,
    this.slotLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SpoolScan')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                success ? Icons.check_circle_outline : Icons.error_outline,
                size: 80,
                color: success ? Colors.green : Colors.red,
              ),
              const SizedBox(height: 24),
              Text(
                success ? AppLocalizations.of(context).confirmAssigned : AppLocalizations.of(context).confirmError,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: success ? Colors.green : Colors.red,
                ),
              ),
              if (success && spoolLabel != null && slotLabel != null) ...[
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(spoolLabel!,
                            style: const TextStyle(color: Colors.white70)),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.arrow_forward,
                                color: Colors.blue, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              'Slot $slotLabel',
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(AppLocalizations.of(context).confirmSpoolmanUpdated,
                            style:
                                const TextStyle(color: Colors.blue, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ],
              if (!success) ...[
                const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ],
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () => Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const ScanScreen()),
                  (route) => false,
                ),
                icon: const Icon(Icons.nfc),
                label: Text(AppLocalizations.of(context).confirmNextSpool),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
