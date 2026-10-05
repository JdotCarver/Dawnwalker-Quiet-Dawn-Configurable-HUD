#!/usr/bin/env python3
"""ressources/tools/check-lua.py

Syntax-check every Lua script this mod ships.

Why this exists
---------------
The mod only ever runs inside the game, under UE4SS. A syntax error therefore
costs a full game restart to discover, which is the slowest possible feedback
loop. Loading each file with a real Lua parser catches that class of mistake
in under a second instead.

What it does and does NOT prove
-------------------------------
It compiles each chunk, so it catches syntax errors and nothing else. It does
not execute anything, so runtime problems (a nil global, a bad require path, a
wrong field name) still need the game. Treat a pass as "this will load", not
as "this is correct".

The parser is pinned to Lua 5.4, the version UE4SS ships. Do not let it fall
back to lupa's default runtime: that is Lua 5.5, which made the `for` loop
variable const and so rejects several loops this codebase (and the vendored
ue4ss-common code) legitimately uses under 5.4.

Setup (once per sandbox):
    pip install --break-system-packages lupa

Usage:
    python3 ressources/tools/check-lua.py            # check the shipped scripts
    python3 ressources/tools/check-lua.py PATH ...   # check specific files/dirs
"""

import pathlib
import re
import sys

# Identifiers Lua or UE4SS provide, so using one before a same-named local is
# declared is not necessarily a mistake worth reporting.
AMBIENT = {
    "print", "pairs", "ipairs", "type", "tostring", "tonumber", "table", "math",
    "string", "os", "pcall", "xpcall", "error", "assert", "select", "require",
    "dofile", "load", "setmetatable", "getmetatable", "rawget", "rawset", "next",
    "unpack", "debug", "io", "coroutine", "_G", "_ENV", "self",
}

DECLARATION = re.compile(r"^local\s+(?:function\s+([A-Za-z_]\w*)|([A-Za-z_][\w,\s]*?))\s*(?:=|$|\()")
WORD = re.compile(r"[A-Za-z_]\w*")


def strip_noise(line):
    """Remove comments and string literals, approximately.

    Only good enough to stop quoted words and prose counting as code.
    """
    line = re.sub(r"--\[\[.*?\]\]", " ", line)
    line = re.sub(r"--.*$", " ", line)
    line = re.sub(r"'[^']*'", "''", line)
    line = re.sub(r'"[^"]*"', '""', line)
    return line


def check_declaration_order(source):
    """Find file-scope locals used on a line above their declaration.

    In Lua a name is global until its `local` is reached, so referencing a
    module-level helper before its declaration silently reads nil. Inside a
    closure that only runs later this is invisible: the call raises at
    runtime, and any surrounding pcall turns it into a wrong answer rather
    than an error. That is exactly how the fade clock broke -- the closure
    called valid() six lines before `local function valid` existed.

    Only column-zero declarations are considered. Locals in nested scopes
    have their own visibility rules and would produce noise.
    """
    lines = [strip_noise(line) for line in source.splitlines()]

    declared = {}
    for number, line in enumerate(lines, start=1):
        if not line.startswith("local"):
            continue
        match = DECLARATION.match(line)
        if not match:
            continue
        names = match.group(1) or match.group(2) or ""
        for name in (n.strip() for n in names.split(",")):
            if name and name not in declared:
                declared[name] = number

    problems = []
    for number, line in enumerate(lines, start=1):
        # Skip the declaration line itself; `local x = x` is a real idiom.
        if line.startswith("local"):
            continue
        for match in WORD.finditer(line):
            name = match.group()
            if name in AMBIENT or name not in declared or declared[name] <= number:
                continue
            # Field and method access is unrelated to the local of that name.
            before = line[:match.start()].rstrip()
            if before.endswith(".") or before.endswith(":"):
                continue
            # A table key, as in {from = current}, is not a variable read.
            after = line[match.end():].lstrip()
            if after.startswith("=") and not after.startswith("=="):
                continue
            problems.append((number, name, declared[name]))
    return problems


DEFAULT_TARGETS = [
    "package/Data/QuietDawnHUD/Scripts",
    "Optional",
]


def collect(targets):
    """Expand directories into the .lua files underneath them."""
    files = []
    for target in targets:
        path = pathlib.Path(target)
        if path.is_dir():
            files.extend(sorted(path.rglob("*.lua")))
        elif path.suffix == ".lua":
            files.append(path)
        else:
            print(f"!! not a Lua file or directory: {target}")
    return files


def main():
    try:
        # Match UE4SS. See the module docstring for why the default is wrong.
        from lupa import lua54
    except ImportError:
        print("!! lupa (with its Lua 5.4 runtime) is not installed. Run:")
        print("     pip install --break-system-packages lupa")
        return 2

    repository_root = pathlib.Path(__file__).resolve().parents[2]
    files = collect(sys.argv[1:] or DEFAULT_TARGETS)
    if not files:
        print("!! no Lua files found")
        return 2

    runtime = lua54.LuaRuntime()
    # `load` compiles without running, which is exactly the check we want: these
    # scripts call into UE4SS globals that do not exist outside the game.
    #
    # Always return exactly two values. lupa only hands back a tuple when Lua
    # returns more than one, so a bare `return load(...)` yields a function on
    # success and a 2-tuple on failure.
    compile_chunk = runtime.eval(
        "function(source, name)"
        "  local chunk, message = load(source, name)"
        "  return chunk ~= nil, message or ''"
        "end"
    )

    failures = []
    for path in files:
        source = path.read_text(encoding="utf-8", errors="replace")
        try:
            display = path.relative_to(repository_root) if path.is_absolute() else path
        except ValueError:
            # A path outside the repository, e.g. a scratch file being checked
            # by hand. Report it as given.
            display = path
        compiled, error = compile_chunk(source, f"@{display}")
        if not compiled:
            failures.append((display, error))
            print(f"FAIL {display}\n       {error}")
            continue
        ordering = check_declaration_order(source)
        if ordering:
            failures.append((display, "used before declaration"))
            print(f"FAIL {display}")
            for number, name, declared_at in ordering:
                print(f"       line {number}: '{name}' is read here but its local "
                      f"is declared on line {declared_at} -- it is nil at this point")
        else:
            print(f"ok   {display}")

    print()
    if failures:
        print(f"!! {len(failures)} of {len(files)} file(s) failed")
        return 1
    print(f"== all {len(files)} Lua file(s) compile, declaration order clean")
    return 0


if __name__ == "__main__":
    sys.exit(main())
