import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/spool_creator.dart';

class NewSpoolFormScreen extends StatefulWidget {
  final String nfcUid;
  final List<String> knownVendors;
  final List<String> knownMaterials;
  final String? prefillBrand;
  final String? prefillMaterial;
  final String? prefillColorHex;
  final int? prefillWeightTotal;
  final int? prefillExtruderTemp;
  final Future<void> Function(NewSpoolFormData) onSave;
  final VoidCallback onCancel;

  const NewSpoolFormScreen({
    super.key,
    required this.nfcUid,
    required this.knownVendors,
    required this.knownMaterials,
    this.prefillBrand,
    this.prefillMaterial,
    this.prefillColorHex,
    this.prefillWeightTotal,
    this.prefillExtruderTemp,
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<NewSpoolFormScreen> createState() => _NewSpoolFormScreenState();
}

class _NewSpoolFormScreenState extends State<NewSpoolFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _brand = TextEditingController(text: widget.prefillBrand ?? '');
  late final _material = TextEditingController(text: widget.prefillMaterial ?? '');
  late final _color = TextEditingController(text: widget.prefillColorHex ?? '');
  late final _weight = TextEditingController(
      text: (widget.prefillWeightTotal ?? 1000).toString());
  late final _temp = TextEditingController(
      text: widget.prefillExtruderTemp?.toString() ?? '');

  bool _busy = false;

  @override
  void dispose() {
    _brand.dispose();
    _material.dispose();
    _color.dispose();
    _weight.dispose();
    _temp.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await widget.onSave(NewSpoolFormData(
        brand: _brand.text.trim(),
        material: _material.text.trim(),
        colorHex: _color.text.trim().toLowerCase(),
        weightTotal: int.tryParse(_weight.text.trim()),
        extruderTemp: int.tryParse(_temp.text.trim()),
        nfcUid: widget.nfcUid,
      ));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String? _required(String? v, String required) =>
      (v == null || v.trim().isEmpty) ? required : null;

  String? _hex(String? v, String required, String invalid) {
    if (v == null || v.trim().isEmpty) return required;
    return RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(v.trim()) ? null : invalid;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.formTitle)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(children: [
            TextFormField(
              key: const Key('brand'),
              controller: _brand,
              decoration: InputDecoration(labelText: l10n.formBrand),
              validator: (v) => _required(v, l10n.formRequired),
            ),
            TextFormField(
              key: const Key('material'),
              controller: _material,
              decoration: InputDecoration(labelText: l10n.formMaterial),
              validator: (v) => _required(v, l10n.formRequired),
            ),
            TextFormField(
              key: const Key('color'),
              controller: _color,
              decoration: InputDecoration(labelText: l10n.formColor),
              validator: (v) => _hex(v, l10n.formRequired, l10n.formInvalidHex),
            ),
            TextFormField(
              key: const Key('weight'),
              controller: _weight,
              decoration: InputDecoration(labelText: l10n.formWeight),
              keyboardType: TextInputType.number,
            ),
            TextFormField(
              key: const Key('temp'),
              controller: _temp,
              decoration: InputDecoration(labelText: l10n.formTemp),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            if (_busy)
              const Center(child: CircularProgressIndicator())
            else
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onCancel,
                    child: Text(l10n.confirmCancel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _save,
                    child: Text(l10n.formSave),
                  ),
                ),
              ]),
          ]),
        ),
      ),
    );
  }
}
