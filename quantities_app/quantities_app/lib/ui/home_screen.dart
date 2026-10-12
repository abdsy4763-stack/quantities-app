import 'package:flutter/material.dart';

import '../data/block_store.dart';
import '../engine/engine.dart';
import '../engine/models.dart';
import 'block_editor.dart';
import 'format.dart';
import 'project_total_screen.dart';
import 'report_screen.dart';

class HomeScreen extends StatefulWidget {
  final Catalog catalog;
  final BlockStore store;
  const HomeScreen({super.key, required this.catalog, required this.store});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Block> blocks = [];
  late final TakeoffEngine engine = TakeoffEngine(widget.catalog);

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final b = await widget.store.all();
    if (mounted) setState(() => blocks = b);
  }

  Future<void> _edit(Block? existing) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlockEditor(catalog: widget.catalog, store: widget.store, block: existing),
      ),
    );
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('حصر الكميات المعماري'),
        actions: [
          IconButton(
            tooltip: 'إجمالي المشروع',
            icon: const Icon(Icons.summarize),
            onPressed: blocks.isEmpty
                ? null
                : () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProjectTotalScreen(report: engine.projectTotal(blocks.map(engine.generate))),
                      ),
                    ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(null),
        icon: const Icon(Icons.add),
        label: const Text('كتلة جديدة'),
      ),
      body: blocks.isEmpty
          ? const Center(child: Text('لا توجد كتل بعد. أضف كتلة جديدة للبدء.'))
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 90),
              itemCount: blocks.length,
              itemBuilder: (_, i) {
                final b = blocks[i];
                final rep = engine.generate(b);
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    title: Text(b.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${b.spaces.length} فراغ • ${rep.rows.length} بند • الإجمالي ${fmt(rep.detailTotal)}'),
                    onTap: () => _edit(b),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      IconButton(
                        icon: const Icon(Icons.table_chart),
                        tooltip: 'التقرير',
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => ReportScreen(report: rep)),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        tooltip: 'حذف',
                        onPressed: () async {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (c) => AlertDialog(
                              title: Text('حذف الكتلة ${b.name}؟'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء')),
                                TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('حذف')),
                              ],
                            ),
                          );
                          if (ok == true) {
                            await widget.store.delete(b.name);
                            _reload();
                          }
                        },
                      ),
                    ]),
                  ),
                );
              },
            ),
    );
  }
}
