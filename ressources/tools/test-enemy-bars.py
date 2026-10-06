#!/usr/bin/env python3
"""ressources/tools/test-enemy-bars.py

Exercise the two failure boundaries in QuietDawnEnemyBars without the game:

* UE4SS must never let a non-widget object reach a UMG-only method such as
  GetOwningPlayer; the worker drops that job after checking its exact class.
* A missing named child gets a short, finite readiness window. Retrying a
  permanently absent field hundreds of times delays unrelated HUD work without
  helping the widget appear.

Usage:
    python3 ressources/tools/test-enemy-bars.py
"""

import pathlib
import sys

REPOSITORY_ROOT = pathlib.Path(__file__).resolve().parents[2]
SCRIPT = REPOSITORY_ROOT / "package/Data/QuietDawnHUD/Scripts/QuietDawnEnemyBars.lua"

failures = []


def check(description, condition, detail=""):
    if condition:
        print(f"ok   {description}")
    else:
        failures.append(description)
        print(f"FAIL {description}" + (f"\n       {detail}" if detail else ""))


def main():
    try:
        from lupa import lua54
    except ImportError:
        print("!! lupa is not installed. Run:")
        print("     bash ressources/tools/setup.sh")
        return 2

    lua = lua54.LuaRuntime()
    module = lua.eval("function(path) return dofile(path) end")(str(SCRIPT))

    counts = {}
    warnings = []

    def count(key, amount=1):
        counts[key] = counts.get(key, 0) + (amount or 1)

    diagnostics = lua.table_from(
        {
            "debugLogging": True,
            "count": count,
            "logWarning": lambda message, *arguments: warnings.append((message, arguments)),
            "event": lambda *_: None,
            "wrap": lambda _, function: function,
        }
    )
    world = lua.table_from({"valid": True})
    controller = lua.table_from({"valid": True, "GetWorld": lambda *_: world})
    hooks = lua.table()
    context = lua.table_from(
        {
            "D": diagnostics,
            "config": lua.table_from(
                {
                    "hideEnemyHealthBars": True,
                    "hideEnemyEffectIcons": False,
                    "hideEnemyNames": True,
                    "hideEnemyDifficultyIcons": True,
                    "showEnemyMarker": False,
                }
            ),
            "Session": lua.table_from({"restore": lambda _: False}),
            "valid": lua.eval("function(object) return object ~= nil and object.valid == true end"),
            "sameObject": lua.eval("function(left, right) return left == right end"),
            "unwrap": lua.eval("function(value) return value end"),
            "opacity": lambda *_: None,
            "hooks": hooks,
            "reportHookError": lambda *_: None,
            "registerHook": lambda *_: (1, 1),
            "wake": lambda *_: None,
            "idle": lambda: True,
            "hud": lambda: lua.table_from({"valid": True}),
            "world": lambda: world,
            "controller": lambda: controller,
        }
    )
    bars = module.new(context)
    character_spec = bars.specs()[1]

    objects = lua.eval(
        """
        function(world, controller)
            local foreignCalls = {owner = 0}
            local foreignClass = {
                GetFName = function()
                    return {ToString = function() return 'BP_TransportWaypoint_C' end}
                end,
            }
            local foreign = {valid = true}
            function foreign:GetClass() return foreignClass end
            function foreign:GetOwningPlayer()
                foreignCalls.owner = foreignCalls.owner + 1
                error('a non-widget must never reach GetOwningPlayer')
            end

            local childCalls = {value = 0}
            local barClass = {
                GetFName = function()
                    return {ToString = function() return 'WBP_CombatCharacterBar_C' end}
                end,
            }
            local bar = {valid = true}
            function bar:GetClass() return barClass end
            function bar:GetFullName() return 'WBP_CombatCharacterBar_C_1' end
            function bar:GetWorld() return world end
            function bar:GetOwningPlayer() return controller end
            function bar:GetWidgetFromName(_)
                childCalls.value = childCalls.value + 1
                return nil
            end
            return foreign, foreignCalls, bar, childCalls
        end
        """
    )
    foreign, foreign_calls, bar, child_calls = objects(world, controller)

    bars.queue(foreign, character_spec)
    bars.step()
    check(
        "a foreign object is discarded before GetOwningPlayer",
        foreign_calls["owner"] == 0,
        f"GetOwningPlayer calls={foreign_calls['owner']}",
    )
    check(
        "the discarded foreign object is counted at Debug",
        counts.get("enemyHealthForeignObjectSkipped") == 1,
        f"count={counts.get('enemyHealthForeignObjectSkipped')}",
    )

    construct_hook = character_spec["path"] + ":Construct"
    update_hook = character_spec["path"] + ":UpdateTarget"
    hooks[construct_hook] = lua.table()
    hooks[update_hook] = lua.table()
    bars.queue(bar, character_spec, lua.table_from(["SegmentedHealthBar"]))
    # The two lifecycle hooks are registered first, one per worker slice;
    # then the single requested child receives its eight readiness attempts.
    for _ in range(10):
        bars.step()
    check(
        "a missing enemy child gets eight bounded readiness attempts",
        child_calls["value"] == 8,
        f"GetWidgetFromName calls={child_calls['value']}",
    )
    check(
        "readiness exhaustion reports one warning",
        len(warnings) == 1,
        f"warnings={len(warnings)}",
    )

    print()
    if failures:
        print(f"!! {len(failures)} check(s) failed")
        return 1
    print("== enemy-bar checks passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
