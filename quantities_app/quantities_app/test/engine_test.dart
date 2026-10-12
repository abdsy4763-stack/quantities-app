import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quantities_app/engine/engine.dart';
import 'package:quantities_app/engine/models.dart';
import 'package:quantities_app/engine/rounding.dart';

void main() {
  final seed = jsonDecode(File('assets/data/seed.json').readAsStringSync(encoding: utf8));
  final golden = jsonDecode(File('test/golden.json').readAsStringSync(encoding: utf8));
  final engine = TakeoffEngine(Catalog.fromJson(Map<String, dynamic>.from(seed)));

  void near(num a, num b, String what) {
    expect((a - b).abs() < 1e-7, isTrue, reason: '$what: dart=$a golden=$b');
  }

  test('vbaRound = decimal banker's rounding (VBA Round)', () {
    expect(vbaRound(2.675), 2.68);
    expect(vbaRound(0.125), 0.12); // tie -> even
    expect(vbaRound(0.135), 0.14); // tie -> even
    expect(vbaRound(1.005), 1.0); // 1.005 -> tie -> even (1.00)
    expect(vbaRound(-2.5, 0), -2.0);
    expect(vbaRound(3.14159), 3.14);
  });

  group('golden cases (generated from the faithful Python port of the VBA)', () {
    final cases = golden['cases'] as List;
    for (var i = 0; i < cases.length; i++) {
      test('case $i', () {
        final c = Map<String, dynamic>.from(cases[i] as Map);
        final block = Block.fromJson(Map<String, dynamic>.from(c['block'] as Map));
        final exp = Map<String, dynamic>.from(c['expected'] as Map);
        final rep = engine.generate(block);

        final rows = exp['rows'] as List;
        expect(rep.rows.length, rows.length);
        for (var r = 0; r < rows.length; r++) {
          final e = Map<String, dynamic>.from(rows[r] as Map);
          final g = rep.rows[r];
          expect(g.code, e['code']);
          expect(g.space, e['space']);
          expect(g.unit, e['unit']);
          near(g.finalQty, e['final'], 'final[$r]');
          near(g.baseQty, e['base'], 'base[$r]');
          near(g.wasteQty, e['waste'], 'waste[$r]');
          near(g.price, e['price'], 'price[$r]');
          near(g.total, e['total'], 'total[$r]');
        }
        near(rep.detailTotal, exp['detailTotal'], 'detailTotal');

        final agg = exp['aggRows'] as List;
        expect(rep.aggRows.length, agg.length);
        for (var r = 0; r < agg.length; r++) {
          final e = Map<String, dynamic>.from(agg[r] as Map);
          final g = rep.aggRows[r];
          expect(g.code, e['code']);
          near(g.finalQty, e['final'], 'agg.final[$r]');
          near(g.baseQty, e['base'], 'agg.base[$r]');
          near(g.total, e['total'], 'agg.total[$r]');
        }
        near(rep.aggTotal, exp['aggTotal'], 'aggTotal');
      });
    }
  });

  test('project total across all golden blocks', () {
    final cases = golden['cases'] as List;
    final reports = cases.map((c) =>
        engine.generate(Block.fromJson(Map<String, dynamic>.from((c as Map)['block'] as Map))));
    final p = engine.projectTotal(reports);
    final exp = Map<String, dynamic>.from(golden['project'] as Map);
    final rows = exp['rows'] as List;
    expect(p.rows.length, rows.length);
    for (var i = 0; i < rows.length; i++) {
      final e = Map<String, dynamic>.from(rows[i] as Map);
      expect(p.rows[i].code, e['code']);
      near(p.rows[i].qty, e['qty'], 'qty[$i]');
      near(p.rows[i].total, e['total'], 'total[$i]');
    }
    near(p.total, exp['total'], 'project total');
  });
}
