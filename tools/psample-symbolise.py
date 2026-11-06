#!/usr/bin/env python3
# Symbolise a psample profile of LCSNative.test: nm tables for the unstripped build, the console's libc and libMali.
# Make tables with: nm -n -C <file> | grep " [tTwWi] " | sed -E "s/\(anonymous namespace\)/{anon}/g; s/\(.*//"
# (nm -D for the stripped console libraries). Usage: psample-symbolise.py <profile> <LCSNative.syms> <libc.syms> <libMali.syms>
import sys, bisect, re
def load(path):
    syms = []
    for line in open(path):
        p = line.split(None, 2)
        if len(p) == 3 and re.match(r"^[0-9a-f]+$", p[0]): syms.append((int(p[0], 16), p[2].strip()))
    syms.sort(); return syms, [a for a, _ in syms]
tables = {"LCSNative": load(sys.argv[2]), "libc.so.6": load(sys.argv[3]), "libMali.so": load(sys.argv[4])}; tables["LCSNative.test"] = tables["LCSNative"]
def name(lib, off):
    if lib not in tables: return lib
    syms, addrs = tables[lib]
    i = bisect.bisect_right(addrs, off) - 1
    return (syms[i][1] + "+0x%x" % (off - syms[i][0])) if i >= 0 else lib + "+?"
agg = {}; out = []
for line in open(sys.argv[1]):
    line = line.rstrip()
    m = re.match(r"\s*([0-9.]+)% (caller |pair )?([A-Za-z0-9_.\-]+)\+0x([0-9a-f]+)(?: from ([A-Za-z0-9_.\-]+)\+0x([0-9a-f]+))?", line)
    if not m: out.append(line); continue
    pct, kind, lib, off = float(m.group(1)), (m.group(2) or "self ").strip(), m.group(3), int(m.group(4), 16)
    n = name(lib, off); ann = n
    if m.group(5): ann += " from " + name(m.group(5), int(m.group(6), 16))
    out.append(line + "   [" + ann + "]")
    fn = n.split("+0x")[0] if kind != "pair" else ann
    agg.setdefault(kind, {}); agg[kind][fn] = agg[kind].get(fn, 0) + pct
print("\n".join(out))
for kind in ("self", "caller", "pair"):
    if kind not in agg: continue
    print("\n== %s, aggregated by function ==" % kind)
    for fn, p in sorted(agg[kind].items(), key=lambda x: -x[1])[:45]: print("%5.1f%% %s" % (p, fn[:150]))
