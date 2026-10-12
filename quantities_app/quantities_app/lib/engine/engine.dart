import 'models.dart';
import 'rounding.dart';

/// Port of the VBA module (GenerateBlockTakeoff_WithWaste_Core +
/// WriteAggregatedTable + CalculateProjectTotal). Behaviour is kept identical,
/// including its quirks, so results match the Excel workbook line by line.
class Catalog {
  final List<CatalogItem> items;
  final Map<String, double> waste; // item code -> waste %
  final Map<String, List<String>> lists; // picker key -> item descriptions

  Catalog({required this.items, required this.waste, required this.lists});

  factory Catalog.fromJson(Map<String, dynamic> j) => Catalog(
        items: (j['items'] as List)
            .map((e) => CatalogItem.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        waste: (j['waste'] as Map).map((k, v) => MapEntry('$k', (v as num).toDouble())),
        lists: (j['lists'] as Map).map((k, v) =>
            MapEntry('$k', List<String>.from((v as List).map((e) => '$e')))),
      );

  static String clean(String s) {
    s = s.replaceAll('\r', '').replaceAll('\n', '').replaceAll(' ', ' ');
    return s.replaceAll(RegExp(' +'), ' ').trim();
  }

  /// VBA LookupItemWaste: exact code match first, then first description match
  /// (equal, or one contains the other). Unknown -> code "N/A", price 0.
  ({String code, String desc, String unit, double price}) lookup(String text) {
    final sc = clean(text);
    if (sc.isEmpty) return (code: 'N/A', desc: text, unit: '', price: 0);
    CatalogItem? found;
    final scU = sc.toUpperCase();
    for (final it in items) {
      if (clean(it.code).toUpperCase() == scU) {
        found = it;
        break;
      }
    }
    if (found == null) {
      final scL = sc.toLowerCase();
      for (final it in items) {
        final c = clean(it.desc);
        if (c.isEmpty) continue;
        final cl = c.toLowerCase();
        if (c == sc || cl.contains(scL) || scL.contains(cl)) {
          found = it;
          break;
        }
      }
    }
    if (found == null) return (code: 'N/A', desc: text, unit: '', price: 0);
    return (
      code: found.code.trim(),
      desc: found.desc.trim(),
      unit: found.unit.trim(),
      price: found.price,
    );
  }

  double wasteRate(String code) {
    final c = code.trim();
    if (c.isEmpty) return 0;
    return waste[c] ?? 0;
  }
}

class _Agg {
  final String code, desc, unit;
  final double price, pct;
  double base, waste, finalQty;
  _Agg(this.code, this.desc, this.unit, this.price, this.pct, this.base, this.waste, this.finalQty);
}

class TakeoffEngine {
  final Catalog catalog;
  TakeoffEngine(this.catalog);

  static const _kg = 'كغ';
  static const _m2 = 'م2';
  static const _lm = 'م.ط';

  BlockReport generate(Block block) {
    final rows = <ReportLine>[];
    final agg = <String, _Agg>{};

    void line(String code, String space, String type, String desc, String unit,
        double base, double price) {
      final pct = catalog.wasteRate(code);
      final w = vbaRound(base * pct / 100);
      final f = vbaRound(base + w);
      rows.add(ReportLine(
        code: code,
        space: space,
        spaceType: type,
        desc: desc,
        unit: unit,
        finalQty: f,
        price: price,
        total: f * price,
        baseQty: base,
        wastePct: pct,
        wasteQty: w,
      ));
      final k = '$code\u0001$desc\u0001$unit'.toLowerCase();
      final a = agg[k];
      if (a != null) {
        a.base += base;
        a.waste += w;
        a.finalQty += f;
      } else {
        agg[k] = _Agg(code, desc, unit, price, pct, base, w, f);
      }
    }

    final name = block.name;
    final L = block.length, W = block.width, H = block.height;

    if (block.insulation.trim().isNotEmpty) {
      final it = catalog.lookup(block.insulation.trim());
      line(it.code, 'الكتلة $name', 'عزل السطح', it.desc, it.unit.isEmpty ? _m2 : it.unit, L * W, it.price);
    }
    if (block.facade.trim().isNotEmpty) {
      final it = catalog.lookup(block.facade.trim());
      line(it.code, 'الكتلة $name', 'أعمال الواجهات', it.desc, it.unit.isEmpty ? _m2 : it.unit,
          2 * (L + W) * H, it.price);
    }

    for (final sp in block.spaces) {
      final spaceName = sp.name.trim();
      if (spaceName.isEmpty) continue;
      final l = sp.length, w = sp.width, h = sp.height;
      final da = sp.doorCount * sp.doorH * sp.doorW;
      final wa = sp.winCount * sp.winH * sp.winW;
      final dwt = sp.doorCount * sp.doorW;
      final wwt = sp.winCount * sp.winW;

      for (var i = 0; i < 8; i++) {
        final sel = sp.items[i].trim();
        if (sel.isEmpty) continue;
        final it = catalog.lookup(sel);
        var unit = it.unit;
        final metal = unit.trim() == _kg;
        double base;
        switch (i + 12) {
          case 12: // floors
            base = l * w;
            if (unit.isEmpty) unit = _m2;
          case 13: // wall finish
            base = (2 * (l + w) * h) - (da + wa);
            if (unit.isEmpty) unit = _m2;
          case 14: // ceilings
            base = l * w;
            if (unit.isEmpty) unit = _m2;
          case 15: // doors
            base = metal ? sp.doorCount * sp.doorW * sp.doorH * 40 : sp.doorCount * sp.doorW * sp.doorH;
            if (!metal && unit.isEmpty) unit = _m2;
          case 16: // windows
            base = metal ? sp.winCount * sp.winW * sp.winH * 20 : sp.winCount * sp.winW * sp.winH;
            if (!metal && unit.isEmpty) unit = _m2;
          case 17: // sills
            base = (2 * (l + w)) - dwt;
            if (unit.isEmpty) unit = _lm;
          case 18: // marble thresholds
            base = dwt + wwt;
            if (unit.isEmpty) unit = _lm;
          default: // 19: wall plaster
            base = (2 * (l + w) * h) - (da + wa);
            if (unit.isEmpty) unit = _m2;
        }
        if (base < 0) base = 0;
        line(it.code, spaceName, sp.type.trim(), it.desc, unit, vbaRound(base), it.price);
      }
    }

    var detailTotal = 0.0;
    for (final r in rows) {
      detailTotal += r.total;
    }
    final aggRows = <AggLine>[];
    var aggTotal = 0.0;
    for (final a in agg.values) {
      final f = vbaRound(a.finalQty);
      final t = f * a.price;
      aggTotal += t;
      aggRows.add(AggLine(
        code: a.code,
        desc: a.desc,
        unit: a.unit,
        finalQty: f,
        price: a.price,
        total: t,
        baseQty: vbaRound(a.base),
        wastePct: a.pct,
        wasteQty: vbaRound(a.waste),
      ));
    }
    return BlockReport(
      blockName: name,
      rows: rows,
      detailTotal: detailTotal,
      aggRows: aggRows,
      aggTotal: aggTotal,
    );
  }

  /// CalculateProjectTotal: sums the final quantity per (code, desc, unit, price)
  /// over the detail lines of every block.
  ProjectReport projectTotal(Iterable<BlockReport> reports) {
    final d = <String, double>{};
    final meta = <String, ReportLine>{};
    for (final rep in reports) {
      for (final r in rep.rows) {
        final k = '${r.code}|${r.desc}|${r.unit}|${r.price}'.toLowerCase();
        d[k] = (d[k] ?? 0) + r.finalQty;
        meta.putIfAbsent(k, () => r);
      }
    }
    final rows = <ProjectLine>[];
    var total = 0.0;
    d.forEach((k, q) {
      final m = meta[k]!;
      final qty = vbaRound(q);
      final t = qty * m.price;
      total += t;
      rows.add(ProjectLine(code: m.code, desc: m.desc, unit: m.unit, qty: qty, price: m.price, total: t));
    });
    return ProjectReport(rows: rows, total: total);
  }
}
