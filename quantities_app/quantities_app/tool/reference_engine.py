"""Faithful Python port of the VBA takeoff logic (GenerateBlockTakeoff_WithWaste_Core,
WriteAggregatedTable, CalculateProjectTotal). Used only to generate golden test
data for the Dart engine. Run: python3 tool/reference_engine.py"""
import json, re, random
from decimal import Decimal, ROUND_HALF_EVEN

SEED = json.load(open('assets/data/seed.json', encoding='utf8'))
ITEMS, WASTE = SEED['items'], SEED['waste']

def vround(x, n=2):
    """VBA Round: banker's rounding on the 15-significant-digit decimal value."""
    d = Decimal(format(x, '.15g'))
    return float(d.quantize(Decimal(1).scaleb(-n), rounding=ROUND_HALF_EVEN))

def clean(s):
    s = str(s or '').replace('\r', '').replace('\n', '').replace('\xa0', ' ')
    return re.sub(r' +', ' ', s).strip()

def lookup(text):
    sc = clean(text)
    out = dict(code='N/A', desc=text, price=0.0, unit='')
    if not sc: return out
    found = None
    for it in ITEMS:
        if clean(it['code']).upper() == sc.upper(): found = it; break
    if not found:
        for it in ITEMS:
            c = clean(it['desc'])
            if c and (c == sc or sc.lower() in c.lower() or c.lower() in sc.lower()):
                found = it; break
    if found:
        out = dict(code=found['code'].strip(), desc=found['desc'].strip(), price=found['price'], unit=found['unit'].strip())
    return out

def waste_rate(code):
    return WASTE.get(code.strip(), 0.0) if code.strip() else 0.0

def line(rows, agg, code, space, stype, desc, unit, base, price):
    pct = waste_rate(code)
    w = vround(base * pct / 100)
    f = vround(base + w)
    rows.append(dict(code=code, space=space, type=stype, desc=desc, unit=unit, final=f, price=price,
                     total=f * price, base=base, pct=pct, waste=w))
    k = (code, desc, unit)
    if k in agg:
        a = agg[k]; a['base'] += base; a['waste'] += w; a['final'] += f
    else:
        agg[k] = dict(code=code, desc=desc, unit=unit, price=price, base=base, waste=w, final=f, pct=pct)

def generate(block):
    rows, agg = [], {}
    L, W, H = block['L'], block['W'], block['H']
    name = block['name']
    if block.get('insulation'):
        it = lookup(block['insulation']); u = it['unit'] or 'م2'
        line(rows, agg, it['code'], 'الكتلة ' + name, 'عزل السطح', it['desc'], u, L * W, it['price'])
    if block.get('facade'):
        it = lookup(block['facade']); u = it['unit'] or 'م2'
        line(rows, agg, it['code'], 'الكتلة ' + name, 'أعمال الواجهات', it['desc'], u, 2 * (L + W) * H, it['price'])
    for sp in block['spaces']:
        if not sp['name'].strip(): continue
        l, w, h = sp['L'], sp['W'], sp['H']
        dc, dh, dw = sp['doorCount'], sp['doorH'], sp['doorW']
        wc, wh, ww = sp['winCount'], sp['winH'], sp['winW']
        da, wa = dc * dh * dw, wc * wh * ww
        dwt, wwt = dc * dw, wc * ww
        for col in range(12, 20):
            sel = sp['items'][col - 12].strip()
            if not sel: continue
            it = lookup(sel); unit = it['unit']; metal = unit.strip() == 'كغ'
            if col == 12: base = l * w; unit = unit or 'م2'
            elif col == 13: base = 2 * (l + w) * h - (da + wa); unit = unit or 'م2'
            elif col == 14: base = l * w; unit = unit or 'م2'
            elif col == 15:
                base = dc * dw * dh * 40 if metal else dc * dw * dh
                if not metal: unit = unit or 'م2'
            elif col == 16:
                base = wc * ww * wh * 20 if metal else wc * ww * wh
                if not metal: unit = unit or 'م2'
            elif col == 17: base = 2 * (l + w) - dwt; unit = unit or 'م.ط'
            elif col == 18: base = dwt + wwt; unit = unit or 'م.ط'
            else: base = 2 * (l + w) * h - (da + wa); unit = unit or 'م2'
            if base < 0: base = 0
            line(rows, agg, it['code'], sp['name'].strip(), sp['type'].strip(), it['desc'], unit, vround(base), it['price'])
    detail_total = sum(r['total'] for r in rows)
    agg_rows = []
    for a in agg.values():
        f = vround(a['final'])
        agg_rows.append(dict(code=a['code'], desc=a['desc'], unit=a['unit'], final=f, price=a['price'],
                             total=f * a['price'], base=vround(a['base']), pct=a['pct'], waste=vround(a['waste'])))
    return dict(rows=rows, detailTotal=detail_total, aggRows=agg_rows, aggTotal=sum(r['total'] for r in agg_rows))

def project_total(reports):
    d = {}
    for rep in reports:
        for r in rep['rows']:
            k = (r['code'], r['desc'], r['unit'], r['price'])
            d[k] = d.get(k, 0.0) + r['final']
    rows = []
    for (c, de, u, p), q in d.items():
        q = vround(q); rows.append(dict(code=c, desc=de, unit=u, qty=q, price=p, total=q * p))
    return dict(rows=rows, total=sum(r['total'] for r in rows))

def rnd_block(rng, i):
    L = L_ = round(rng.uniform(8, 40), 2); W = round(rng.uniform(6, 25), 2); H = round(rng.choice([3, 3.2, 3.5, 4]), 2)
    lists = SEED['lists']; order = ['floors', 'walls', 'ceilings', 'doors', 'windows', 'sills', 'tyrolean', 'plaster']
    spaces = []
    for s in range(rng.randint(1, 6)):
        pick = lambda n: rng.choice(lists[n]) if rng.random() < .85 else ''
        spaces.append(dict(name=f'فراغ {s+1}' if rng.random() < .95 else '  ', type=rng.choice(['إداري', 'خدمي']),
            L=round(rng.uniform(2, 10), 3), W=round(rng.uniform(2, 8), 3), H=H,
            doorCount=rng.randint(0, 3), doorH=2.1, doorW=round(rng.choice([0.9, 1.0, 1.2]), 2),
            winCount=rng.randint(0, 4), winH=1.2, winW=round(rng.choice([1.0, 1.5, 2.0]), 2),
            items=[pick(n) for n in order]))
    # deliberately include the one item with a waste rate in some blocks
    waste_item = next(it for it in ITEMS if it['code'] in WASTE)
    if i % 3 == 0: spaces[0]['items'][0] = waste_item['desc']
    if i % 5 == 0: spaces[0]['doorCount'] = 0; spaces[0]['winCount'] = 0
    return dict(name=f'B{i}', L=L, W=W, H=H, insulation=rng.choice(lists['insulation']) if i % 2 == 0 else '',
                facade=rng.choice(lists['facades']) if i % 3 != 0 else '', spaces=spaces)

if __name__ == '__main__':
    rng = random.Random(20261012)
    cases, reports = [], []
    for i in range(40):
        b = rnd_block(rng, i); rep = generate(b); reports.append(rep)
        cases.append(dict(block=b, expected=rep))
    # edge: negative base clamp, tiny walls
    edge = dict(name='EDGE', L=3, W=3, H=2, insulation='', facade='', spaces=[dict(name='x', type='خدمي', L=1, W=1, H=2,
        doorCount=5, doorH=2.1, doorW=1, winCount=3, winH=1.2, winW=2,
        items=['', SEED['lists']['walls'][0], '', SEED['lists']['doors'][0], '', '', '', ''])])
    cases.append(dict(block=edge, expected=generate(edge)))
    reports.append(cases[-1]['expected'])
    out = dict(cases=cases, project=project_total(reports))
    json.dump(out, open('test/golden.json', 'w', encoding='utf8'), ensure_ascii=False)
    print('cases', len(cases), 'project rows', len(out['project']['rows']), 'project total', round(out['project']['total'], 2))
