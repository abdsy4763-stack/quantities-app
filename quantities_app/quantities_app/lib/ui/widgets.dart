import 'package:flutter/material.dart';

import 'format.dart';

class NumField extends StatefulWidget {
  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  const NumField({super.key, required this.label, required this.value, required this.onChanged});

  @override
  State<NumField> createState() => _NumFieldState();
}

class _NumFieldState extends State<NumField> {
  late final TextEditingController _c = TextEditingController(text: numText(widget.value));

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _c,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: widget.label, isDense: true, border: const OutlineInputBorder()),
      onChanged: (t) => widget.onChanged(parseNum(t)),
    );
  }
}

/// Searchable picker (replaces the Excel dropdown lists).
class PickerField extends StatelessWidget {
  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;
  const PickerField({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final r = await showModalBottomSheet<String>(
          context: context,
          isScrollControlled: true,
          builder: (_) => _PickerSheet(title: label, options: options),
        );
        if (r != null) onChanged(r == '\u0000' ? '' : r);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          border: const OutlineInputBorder(),
          suffixIcon: value.isEmpty ? const Icon(Icons.arrow_drop_down) : const Icon(Icons.check, size: 18),
        ),
        child: Text(
          value.isEmpty ? '—' : value.trim(),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _PickerSheet extends StatefulWidget {
  final String title;
  final List<String> options;
  const _PickerSheet({required this.title, required this.options});

  @override
  State<_PickerSheet> createState() => _PickerSheetState();
}

class _PickerSheetState extends State<_PickerSheet> {
  String q = '';

  @override
  Widget build(BuildContext context) {
    final shown = widget.options.where((o) => o.contains(q)).toList();
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.75,
          child: Column(children: [
            ListTile(
              title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.bold)),
              trailing: TextButton(
                onPressed: () => Navigator.pop(context, '\u0000'),
                child: const Text('بدون'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: TextField(
                decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'بحث'),
                onChanged: (t) => setState(() => q = t),
              ),
            ),
            Expanded(
              child: ListView.separated(
                itemCount: shown.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) => ListTile(
                  title: Text(shown[i].trim(), style: const TextStyle(fontSize: 14)),
                  onTap: () => Navigator.pop(context, shown[i]),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
