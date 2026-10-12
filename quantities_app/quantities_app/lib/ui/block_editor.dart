import 'package:flutter/material.dart';

import '../data/block_store.dart';
import '../engine/engine.dart';
import '../engine/models.dart';
import 'report_screen.dart';
import 'widgets.dart';

class BlockEditor extends StatefulWidget {
  final Catalog catalog;
  final BlockStore store;
  final Block? block;
  const BlockEditor({super.key, required this.catalog, required this.store, this.block});

  @override
  State<BlockEditor> createState() => _BlockEditorState();
}

class _BlockEditorState extends State<BlockEditor> {
  late final Block b = widget.block == null
      ? Block(spaces: [Space()])
      : Block.fromJson(widget.block!.toJson()); // work on a copy
  late final String? originalName = widget.block?.name;

  static const _nameLimit = 27; // same limit as the VBA (sheet name + RAW_ prefix)

  Future<bool> _save() async {
    final name = b.name.trim();
    if (name.isEmpty) {
      _msg('يرجى كتابة اسم الكتلة أولاً.');
      return false;
    }
    if (name.length > _nameLimit) {
      _msg('اسم الكتلة طويل جداً (الحد الأقصى $_nameLimit حرفاً).');
      return false;
    }
    b.name = name;
    if (originalName != null && originalName != name) await widget.store.delete(originalName!);
    await widget.store.save(b);
    return true;
  }

  void _msg(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    final cat = widget.catalog;
    return Scaffold(
      appBar: AppBar(
        title: Text(originalName == null ? 'كتلة جديدة' : 'تعديل: $originalName'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'حفظ',
            onPressed: () async {
              if (await _save() && mounted) _msg('تم الحفظ');
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.calculate),
        label: const Text('توليد الحصر'),
        onPressed: () async {
          if (!await _save() || !mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ReportScreen(report: TakeoffEngine(cat).generate(b))),
          );
        },
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
        children: [
          TextFormField(
            initialValue: b.name,
            decoration: const InputDecoration(labelText: 'اسم الكتلة', border: OutlineInputBorder()),
            onChanged: (t) => b.name = t,
          ),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: NumField(label: 'الطول', value: b.length, onChanged: (v) => b.length = v)),
            const SizedBox(width: 8),
            Expanded(child: NumField(label: 'العرض', value: b.width, onChanged: (v) => b.width = v)),
            const SizedBox(width: 8),
            Expanded(child: NumField(label: 'الارتفاع', value: b.height, onChanged: (v) => b.height = v)),
          ]),
          const SizedBox(height: 10),
          StatefulBuilder(
            builder: (c, set) => Column(children: [
              PickerField(
                label: 'عزل الكتلة (السطح)',
                value: b.insulation,
                options: cat.lists['insulation'] ?? [],
                onChanged: (v) => set(() => b.insulation = v),
              ),
              const SizedBox(height: 10),
              PickerField(
                label: 'أعمال الواجهات',
                value: b.facade,
                options: cat.lists['facades'] ?? [],
                onChanged: (v) => set(() => b.facade = v),
              ),
            ]),
          ),
          const Divider(height: 28),
          Row(children: [
            const Text('الفراغات', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Spacer(),
            FilledButton.tonalIcon(
              onPressed: () => setState(() => b.spaces.add(Space())),
              icon: const Icon(Icons.add),
              label: const Text('فراغ'),
            ),
          ]),
          for (var i = 0; i < b.spaces.length; i++)
            _SpaceCard(
              key: ObjectKey(b.spaces[i]),
              space: b.spaces[i],
              index: i,
              catalog: cat,
              onDelete: () => setState(() => b.spaces.removeAt(i)),
              onDuplicate: () => setState(() => b.spaces.insert(i + 1, Space.fromJson(b.spaces[i].toJson()))),
            ),
        ],
      ),
    );
  }
}

class _SpaceCard extends StatefulWidget {
  final Space space;
  final int index;
  final Catalog catalog;
  final VoidCallback onDelete, onDuplicate;
  const _SpaceCard({
    super.key,
    required this.space,
    required this.index,
    required this.catalog,
    required this.onDelete,
    required this.onDuplicate,
  });

  @override
  State<_SpaceCard> createState() => _SpaceCardState();
}

class _SpaceCardState extends State<_SpaceCard> {
  Space get s => widget.space;

  Widget _row(List<Widget> kids) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(children: [
          for (var i = 0; i < kids.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(child: kids[i]),
          ]
        ]),
      );

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(top: 10),
      child: ExpansionTile(
        initiallyExpanded: widget.index == 0,
        title: Text(s.name.trim().isEmpty ? 'فراغ ${widget.index + 1}' : s.name),
        childrenPadding: const EdgeInsets.all(12),
        children: [
          _row([
            TextFormField(
              initialValue: s.name,
              decoration: const InputDecoration(labelText: 'اسم الفراغ', isDense: true, border: OutlineInputBorder()),
              onChanged: (t) => s.name = t,
            ),
            DropdownButtonFormField<String>(
              value: s.type.isEmpty ? 'إداري' : s.type,
              decoration: const InputDecoration(labelText: 'الوظيفة', isDense: true, border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'إداري', child: Text('إداري')),
                DropdownMenuItem(value: 'خدمي', child: Text('خدمي')),
              ],
              onChanged: (v) => s.type = v ?? 'إداري',
            ),
          ]),
          _row([
            NumField(label: 'الطول', value: s.length, onChanged: (v) => s.length = v),
            NumField(label: 'العرض', value: s.width, onChanged: (v) => s.width = v),
            NumField(label: 'الارتفاع', value: s.height, onChanged: (v) => s.height = v),
          ]),
          _row([
            NumField(label: 'عدد الأبواب', value: s.doorCount, onChanged: (v) => s.doorCount = v),
            NumField(label: 'ارتفاع الباب', value: s.doorH, onChanged: (v) => s.doorH = v),
            NumField(label: 'عرض الباب', value: s.doorW, onChanged: (v) => s.doorW = v),
          ]),
          _row([
            NumField(label: 'عدد النوافذ', value: s.winCount, onChanged: (v) => s.winCount = v),
            NumField(label: 'ارتفاع النافذة', value: s.winH, onChanged: (v) => s.winH = v),
            NumField(label: 'عرض النافذة', value: s.winW, onChanged: (v) => s.winW = v),
          ]),
          for (var i = 0; i < 8; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: PickerField(
                label: kItemLabels[i],
                value: s.items[i],
                options: widget.catalog.lists[kItemKeys[i]] ?? [],
                onChanged: (v) => setState(() => s.items[i] = v),
              ),
            ),
          Row(children: [
            TextButton.icon(onPressed: widget.onDuplicate, icon: const Icon(Icons.copy), label: const Text('نسخ')),
            const Spacer(),
            TextButton.icon(onPressed: widget.onDelete, icon: const Icon(Icons.delete_outline), label: const Text('حذف')),
          ]),
        ],
      ),
    );
  }
}
