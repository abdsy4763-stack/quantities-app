import 'package:flutter/material.dart';

import '../engine/models.dart';
import 'format.dart';

class ProjectTotalScreen extends StatelessWidget {
  final ProjectReport report;
  const ProjectTotalScreen({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إجمالي المشروع')),
      body: Column(children: [
        Expanded(
          child: ListView.separated(
            itemCount: report.rows.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final r = report.rows[i];
              return ListTile(
                tileColor: r.price == 0 ? const Color(0x22FF0000) : null,
                title: Text(r.desc.trim(), maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                subtitle: Text('${r.code}  |  ${fmt(r.qty)} ${r.unit} × ${fmt(r.price)}'),
                trailing: Text(fmt(r.total), style: const TextStyle(fontWeight: FontWeight.bold)),
              );
            },
          ),
        ),
        Container(
          color: const Color(0xFF2C3E50),
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            const Text('إجمالي تكلفة المشروع', style: TextStyle(color: Colors.white)),
            const Spacer(),
            Text(fmt(report.total), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ]),
        ),
      ]),
    );
  }
}
