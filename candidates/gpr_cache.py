#!/usr/bin/env python3
"""Shadow the guest GPRs in locals within each straight-line run of a generated unit.

The generated code keeps every Allegrex register in ctx.gpr[] (memory): the
host compiler cannot hold one in a register across a guest store (a byte
store may alias anything) or a call. This pass rewrites a generated unit so
that, between a label and the next exit (goto, return, call), the registers
it touches live in locals r1..r31: loaded from ctx.gpr[] on first use, written
back before the exit. Conditional blocks ({ ... }) restore the state at their
closing brace; any line it does not understand flushes and forgets everything
first, so hand-written hooks stay correct.

Usage: gpr_cache.py <in.cpp> <out.cpp>
"""
import re, sys

READ = re.compile(r"ctx\.gpr\[(\d+)\]")
WRITE = re.compile(r"^(\s*)ctx\.gpr\[(\d+)\] = \(")
KNOWN_CTX = ("ctx.gpr[", "ctx.pc", "ctx.lo", "ctx.hi", "ctx.fpr", "ctx.vfpu", "ctx.set_fpr_bits",
             "ctx.fpu_float_to_word", "ctx.read_vfpu", "ctx.write_vfpu", "ctx.apply_vfpu",
             "ctx.eat_vfpu", "ctx.vfpu_scalar", "ctx.set_vfpu", "ctx.fpr_bits", "ctx.fcr31",
             "ctx.execute_vfpu")
ODD_WRITE = re.compile(r"ctx\.gpr\[\d+\]\s*(=(?!=)|\+=|-=|\|=|&=|<<=|>>=|\^=)|&ctx\.gpr")
EXIT_MARKS = ("goto ", "return;", "rt.invoke_chained", "rt.unsupported(")

def strip_known(line):
    s = line
    for k in KNOWN_CTX:
        s = s.replace(k, "")
    return s

def transform_function(lines):
    out = []
    loaded, dirty = set(), set()
    stack = []  # (loaded, dirty, conditional) per open brace
    def flush(indent):
        for n in sorted(dirty):
            out.append(f"{indent}ctx.gpr[{n}] = r{n};")
    def in_conditional():
        return any(c for _, _, c in stack)
    for line in lines:
        stripped = line.strip()
        indent = line[:len(line) - len(line.lstrip())]
        if re.match(r"^L_[0-9A-Fa-f]+:$", stripped) or stripped == "LOCAL_DISPATCH:":
            flush("    ")  # a fallthrough into the label leaves memory current
            loaded, dirty = set(), set()
            stack = []
            out.append(line)
            continue
        if stripped == "}" or stripped.startswith("} else"):
            if stack:
                l, d, conditional = stack.pop()
                if conditional:
                    loaded, dirty = l, d
            else:
                loaded, dirty = set(), set()
            out.append(line)
            continue
        is_exit = any(m in line for m in EXIT_MARKS)
        m = WRITE.match(line)
        odd = ODD_WRITE.search(line[m.end():] if m else line) is not None
        unknown = (("ctx" in strip_known(line)) and not is_exit) or odd
        if unknown:
            flush(indent)
            loaded, dirty = set(), set()
            out.append(line)
            continue
        rhs = line[m.end():] if m else line
        regs = {int(x) for x in READ.findall(rhs)}
        for n in sorted(regs):
            if n not in loaded:
                out.append(f"{indent}r{n} = ctx.gpr[{n}];")
                loaded.add(n)
        new = READ.sub(lambda mm: f"r{mm.group(1)}", rhs)
        if m:
            wn = int(m.group(2))
            new = f"{m.group(1)}r{wn} = (" + new
            loaded.add(wn); dirty.add(wn)
        if is_exit:
            flush(indent)
            out.append(new)
            if "rt.invoke_chained" in line or "rt.unsupported(" in line or not in_conditional():
                loaded, dirty = set(), set()
            continue
        out.append(new)
        opens = stripped.count("{") - stripped.count("}")
        if opens > 0:
            conditional = stripped.startswith("if (") or stripped.startswith("else") or stripped.startswith("} else")
            for _ in range(opens):
                stack.append((set(loaded), set(dirty), conditional))
        elif opens < 0:
            for _ in range(-opens):
                if stack:
                    l, d, conditional = stack.pop()
                    if conditional:
                        loaded, dirty = l, d
    return out

def main():
    src = open(sys.argv[1]).read().split("\n")
    out = []
    i = 0
    while i < len(src):
        line = src[i]
        if re.match(r"^void recomp_unit_\d+_entry\(", line) and line.rstrip().endswith("{"):
            out.append(line)
            out.append("    std::uint32_t " + ", ".join(f"r{n} = 0u" for n in range(1, 32)) + ";")
            out.append("    (void)r1;")
            body = []
            i += 1
            while i < len(src) and src[i] != "}":
                body.append(src[i]); i += 1
            out.extend(transform_function(body))
            out.append("}")
            i += 1
            continue
        out.append(line); i += 1
    open(sys.argv[2], "w").write("\n".join(out))

if __name__ == "__main__":
    main()
