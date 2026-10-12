import 'package:flutter/material.dart';

import '../engine/models.dart';
import 'format.dart';

class ReportScreen extends StatelessWidget {
  final BlockReport report;
  const ReportScreen({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('حصر الكتلة: ${report.blockName}'),
          bottom: const TabBar(tabs: [Tab(text: 'التفصيل'), Tab(text: 'إجمالي الكتلة')]),
        ),
        body: TabBarView(children: [
          _list(
            report.rows
                .map((r) => _Line(r.desc, '${r.space}${r.spaceType.isEmpty ? '' : ' • ${r.spaceType}'}', r.unit,
                    r.finalQty, r.price, r.total, r.wastePct, r.code))
                .toList(),
            report.detailTotal,
            'إجمالي السعر للكتلة',
          ),
          _list(
            report.aggRows
                .map((r) => _Line(r.desc, '', r.unit, r.finalQty, r.price, r.total, r.wastePct, r.code))
                .toList(),
            report.aggTotal,
            'إجمالي السعر لكامل الكتلة (مجمّع)',
          ),
        ]),
      ),
    );
  }

  Widget _list(List<_Line> lines, double total, String totalLabel) {
    return Column(children: [
      Expanded(
        child: lines.isEmpty
            ? const Center(child: Text('لا توجد بنود.'))
            : ListView.separated(
                itemCount: lines.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final l = lines[i];
                  final zero = l.price == 0;
                  return ListTile(
                    tileColor: zero ? const Color(0x22FF0000) : null,
                    title: Text(l.desc.trim(), maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                    subtitle: Text([
                      l.code,
                      if (l.where.isNotEmpty) l.where,
                      '${fmt(l.qty)} ${l.unit} × ${fmt(l.price)}',
                      if (l.waste > 0) 'هدر ${fmt(l.waste, 0)}%',
                    ].join('  |  ')),
                    trailing: Text(fmt(l.total), style: const TextStyle(fontWeight: FontWeight.bold)),
                  );
                },
              ),
      ),
      Container(
        color: const Color(0xFF2C3E50),
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          Text(totalLabel, style: const TextStyle(color: Colors.white)),
          const Spacer(),
          Text(fmt(total), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        ]),
      ),
    ]);
  }
}

class _Line {
  final String desc, where, unit, code;
  final double qty, price, total, waste;
  _Line(this.desc, this.where, this.unit, this.qty, this.price, this.total, this.waste, this.code);
}
