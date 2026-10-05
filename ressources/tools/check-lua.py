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
import sys

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
        display = path.relative_to(repository_root) if path.is_absolute() else path
        compiled, error = compile_chunk(source, f"@{display}")
        if not compiled:
            failures.append((display, error))
            print(f"FAIL {display}\n       {error}")
        else:
            print(f"ok   {display}")

    print()
    if failures:
        print(f"!! {len(failures)} of {len(files)} file(s) failed to compile")
        return 1
    print(f"== all {len(files)} Lua file(s) compile")
    return 0


if __name__ == "__main__":
    sys.exit(main())
