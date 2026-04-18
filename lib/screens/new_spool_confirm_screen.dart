import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/tag_reader.dart';

class NewSpoolConfirmScreen extends StatefulWidget {
  final TagReadResult tag;
  final Future<void> Function() onConfirm;
  final VoidCallback onCancel;

  const NewSpoolConfirmScreen({
    super.key,
    required this.tag,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  State<NewSpoolConfirmScreen> createState() => _NewSpoolConfirmScreenState();
}

class _NewSpoolConfirmScreenState extends State<NewSpoolConfirmScreen> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final s = widget.tag.spool!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.confirmNewSpoolTitle)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.confirmNewSpoolHint, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            _row(l10n.formBrand, s.brand ?? '—'),
            _row(l10n.formMaterial, s.type ?? '—'),
            _row(l10n.formColor, s.colorHex ?? '—'),
            _row(l10n.formWeight, '${s.weightTotal ?? 1000}'),
            _row(l10n.formTemp, s.minTemp?.toString() ?? '—'),
            const SizedBox(height: 8),
            _row('NFC-UID', widget.tag.nfcUid),
            const Spacer(),
            if (_busy) const Center(child: CircularProgressIndicator())
            else Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onCancel,
                  child: Text(l10n.confirmCancel),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () async {
                    setState(() => _busy = true);
                    try {
                      await widget.onConfirm();
                    } finally {
                      if (mounted) setState(() => _busy = false);
                    }
                  },
                  child: Text(l10n.confirmNewSpoolCreate),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          SizedBox(width: 120, child: Text(label, style: const TextStyle(color: Colors.grey))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ]),
      );
}
