double _d(dynamic v) => v is num ? v.toDouble() : (double.tryParse('$v') ?? 0);

/// Column order of the 8 finishing pickers in a space (Control_Panel L..S).
const kItemKeys = <String>[
  'floors', // L  أعمال الأرضيات
  'walls', // M  نوع إكساء الجدران
  'ceilings', // N  نوع إكساء الأسقف
  'doors', // O  أعمال الأبواب
  'windows', // P  أعمال النوافذ
  'sills', // Q  نعلات
  'tyrolean', // R  براطيش
  'plaster', // S  طينة جدران
];

const kItemLabels = <String>[
  'أعمال الأرضيات',
  'نوع إكساء الجدران',
  'نوع إكساء الأسقف',
  'أعمال الأبواب',
  'أعمال النوافذ',
  'نعلات',
  'براطيش',
  'طينة جدران',
];

class CatalogItem {
  final int row;
  final String code, desc, unit, category;
  final double price;
  const CatalogItem({
    required this.row,
    required this.code,
    required this.desc,
    required this.unit,
    required this.price,
    required this.category,
  });
  factory CatalogItem.fromJson(Map<String, dynamic> j) => CatalogItem(
        row: (j['row'] as num).toInt(),
        code: j['code'] as String,
        desc: j['desc'] as String,
        unit: j['unit'] as String,
        price: _d(j['price']),
        category: j['category'] as String,
      );
}

class Space {
  String name, type;
  double length, width, height;
  double doorCount, doorH, doorW, winCount, winH, winW;
  List<String> items; // 8 entries, '' = none

  Space({
    this.name = '',
    this.type = 'إداري',
    this.length = 0,
    this.width = 0,
    this.height = 0,
    this.doorCount = 0,
    this.doorH = 0,
    this.doorW = 0,
    this.winCount = 0,
    this.winH = 0,
    this.winW = 0,
    List<String>? items,
  }) : items = items ?? List.filled(8, '');

  factory Space.fromJson(Map<String, dynamic> j) => Space(
        name: (j['name'] ?? '') as String,
        type: (j['type'] ?? '') as String,
        length: _d(j['L']),
        width: _d(j['W']),
        height: _d(j['H']),
        doorCount: _d(j['doorCount']),
        doorH: _d(j['doorH']),
        doorW: _d(j['doorW']),
        winCount: _d(j['winCount']),
        winH: _d(j['winH']),
        winW: _d(j['winW']),
        items: List<String>.from((j['items'] as List).map((e) => '$e')),
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'type': type,
        'L': length,
        'W': width,
        'H': height,
        'doorCount': doorCount,
        'doorH': doorH,
        'doorW': doorW,
        'winCount': winCount,
        'winH': winH,
        'winW': winW,
        'items': items,
      };
}

class Block {
  String name;
  double length, width, height;
  String insulation, facade;
  List<Space> spaces;

  Block({
    this.name = '',
    this.length = 0,
    this.width = 0,
    this.height = 0,
    this.insulation = '',
    this.facade = '',
    List<Space>? spaces,
  }) : spaces = spaces ?? [];

  factory Block.fromJson(Map<String, dynamic> j) => Block(
        name: (j['name'] ?? '') as String,
        length: _d(j['L']),
        width: _d(j['W']),
        height: _d(j['H']),
        insulation: (j['insulation'] ?? '') as String,
        facade: (j['facade'] ?? '') as String,
        spaces: ((j['spaces'] ?? []) as List)
            .map((e) => Space.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'L': length,
        'W': width,
        'H': height,
        'insulation': insulation,
        'facade': facade,
        'spaces': spaces.map((s) => s.toJson()).toList(),
      };
}

/// One detail line (columns A:K of the VBA report sheet).
class ReportLine {
  final String code, space, spaceType, desc, unit;
  final double finalQty, price, total, baseQty, wastePct, wasteQty;
  const ReportLine({
    required this.code,
    required this.space,
    required this.spaceType,
    required this.desc,
    required this.unit,
    required this.finalQty,
    required this.price,
    required this.total,
    required this.baseQty,
    required this.wastePct,
    required this.wasteQty,
  });
}

class AggLine {
  final String code, desc, unit;
  final double finalQty, price, total, baseQty, wastePct, wasteQty;
  const AggLine({
    required this.code,
    required this.desc,
    required this.unit,
    required this.finalQty,
    required this.price,
    required this.total,
    required this.baseQty,
    required this.wastePct,
    required this.wasteQty,
  });
}

class BlockReport {
  final String blockName;
  final List<ReportLine> rows;
  final double detailTotal;
  final List<AggLine> aggRows;
  final double aggTotal;
  const BlockReport({
    required this.blockName,
    required this.rows,
    required this.detailTotal,
    required this.aggRows,
    required this.aggTotal,
  });
}

class ProjectLine {
  final String code, desc, unit;
  final double qty, price, total;
  const ProjectLine({
    required this.code,
    required this.desc,
    required this.unit,
    required this.qty,
    required this.price,
    required this.total,
  });
}

class ProjectReport {
  final List<ProjectLine> rows;
  final double total;
  const ProjectReport({required this.rows, required this.total});
}
