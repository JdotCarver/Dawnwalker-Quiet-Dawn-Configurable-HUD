# Building the native HUD bridge

Use Windows x64, Visual Studio 2022's MSVC v143 C++ tools, the Windows 10/11 SDK, Git, and CMake 3.25 or newer. Build **Release** with the shared C runtime (`/MD`). The reference build uses MSVC 19.44.35228 and Windows SDK 10.0.26100.0.

The engine headers require GitHub access to Re-UE4SS/UEPseudo through the linked Epic Games account. They are not included in this repository or the mod archive.

```bat
git clone https://github.com/UE4SS-RE/RE-UE4SS.git RE-UE4SS
git -C RE-UE4SS checkout 97b7e501c19d8b2b7c662feee73aaa0dc1f0a4d1
git -C RE-UE4SS submodule update --init deps/first/Unreal
cmake -S native -B .local/native-build -A x64 -DUE4SS_SDK=C:/path/to/RE-UE4SS
cmake --build .local/native-build --config Release
```

Run the CMake commands from the Quiet Dawn - Configurable HUD repository. CMake retrieves pinned public header dependencies. The output is `.local/native-build/Release/main.dll` with the Visual Studio generator, or `.local/native-build/main.dll` with Ninja. The package payload is `Data/QuietDawnHUD/dlls/main.dll`. Install the packaged mod through Vortex.

## Compatibility boundary

This bridge uses the imported UE4SS C++ APIs without a DLL hash, version or fork-name gate. It uses the regular Lua hook route when the host already enables script dispatch. Sprint-prompt, claw-asset and combat-icon helpers remain independently available. Before using the private host action queue, the HUD adapter checks that the owner's main, async and hook Lua states match those supplied by the host lifecycle callback; a mismatch disables that adapter with a specific diagnostic.

The SDK pins RE-UE4SS `97b7e501c19d8b2b7c662feee73aaa0dc1f0a4d1` and UEPseudo `eb40a05f49509bdeb1ac39287032b60af585cca8`. `Framecore2b.def` lists only the host exports used by this bridge; it creates an import library, not a replacement UE4SS DLL. Review the source types and actual API/layout dependencies when an interface changes. Whole-file fingerprints identify tested evidence only; matching names alone do not prove that an incompatible C++ ABI will work.

## Dispatch and lifetime

The helper registers one post-callback through UE4SS's own `ProcessLocalScriptFunction` detour after the disabled standard Lua dispatcher has failed registration. It temporarily enables the host's in-memory installation flag for that call and restores it immediately. No INI is written. The underlying engine interception still runs for Blueprint calls; the native pointer table rejects functions outside Quiet Dawn's fixed HUD list before acquiring a queue lock or entering Lua.

The prompt-enable event delivers only its HUD context; its parameters are never decoded as resource values. The allowlist includes the time widget's event graph. The native filter accepts only the time-change entry (455), excluding initialization, dialogue previews and animation updates before Lua delivery.

Matching events copy scalar parameters and object identities into a 128-event queue. The largest resource drop survives a coalesced recovery or subsequent smaller fluctuation; player HUD events take priority over enemy-widget bursts. One host async action schedules a game-thread delivery chain. It revalidates each object and dispatches at most four callbacks per frame. It uses the host's registered Lua states, object converter, action queue and action lock, and never calls Lua directly from a native detour.

Identities contain an opaque address, object index and the serial number already assigned by the engine. The bridge never allocates serial numbers or constructs UE4SS weak/soft references. A native object-deletion listener invalidates matching function identities and removes queued events before the address or index can be reused, including when the serial is zero. A small atomic interest filter rejects unrelated deletions; collisions receive an exact address/index check under the queue lock. Deletion callbacks perform no UObject reads, Lua calls or allocations. Game-thread delivery checks the indexed object, its validity flags and any captured nonzero serial before constructing a Lua wrapper. Shutdown removes the listener and clears pending identities.

Widget replacement triggers finite, coalesced function rebinding. A save/session change clears pending events and refreshes function identities. No background thread, continuous readiness timer, widget-tree walk or global UObject scan is added. The helper remains loaded until the game exits; live DLL/Lua reload is unsupported.

Logging uses Quiet Dawn's existing `debugLogging` setting. Session summaries include captured/delivered/coalesced/dropped events, stale identities, failures and aggregate native capture time. Frame-time impact must be measured in the game; counts and compilation do not measure FPS.

## Credits

The native integration uses [UE4SS](https://github.com/UE4SS-RE/RE-UE4SS), its UE adaptation headers, and Framecore's exported callback implementation. The build also uses fmt headers. License notices are included under `LICENSES/` in the mod repository and archive. ImGui, ImGuiColorTextEdit and Zydis/Zycore headers are required transitively by the UE4SS SDK; their implementations are not linked into this DLL.

The deferred event allowlist has 32 functions. IDs 25 and 26 observe the combat marker's directional and non-directional icon render helpers, covering changes that bypass event wrappers. Gameplay uses those events for bounded marker discovery, scaling and diagnostics. The combat-icon guard below applies presentation synchronously; Lua retains the deferred renderer when that guard is unavailable. Cleanup removes the marker lease before redrawing its current stock icon. ID 27 observes the timer's Update Time Display helper without decoding its DayTime parameter. Lua compares GetCurrentDay and GetCurrentDayTimeAsFloat from the cached TimeSystemImpl on HUD display events, retaining only numbers. The initial snapshot does not reveal the panel. Hidden-HUD reveals resume through existing preset/activation callbacks. Special-attack setup/finish use context-only events; the panel reads the stock cooldown display after delivery. Quickslot switching filters WBP_GameHUD graph entry 4146 before queueing; the Controls Legend filter remains entry 850. These entry offsets are verified in Steam build 25232147 assets and must be rechecked after asset changes. The Lua adapter bounds rebinding by the highest registered allowlist ID. No cooldown-update or Tick subscription is added.

## Live settings API

`_QDNSetLogging(enabled)` runs on the game thread and changes diagnostics under the existing queue mutex. It resets diagnostic counters when the flag changes while preserving queued events, event ownership, active hook bindings and delivery scheduling. The persistent Lua bridge uses this function for Logging Apply, without calling begin/stop.

Mod Setting Menu 1.0.6+ requires `HookProcessConsoleExec=1` in the loader profile. The mod archive does not supply that global INI.

## Sprint/Haste source suppression

`SprintPrompts.cpp` uses a separate native pre/post hook for `/Script/Dawnwalker.SprintAbility:ShowPrompt`. With the option enabled, only show requests from the exact `GA_OpenWorldSprint`, `GA_FastTravelHumanSprint` and `GA_FastTravelVampireSprint` classes are suppressed. The helper validates the reflected `PromptsArray` / `DWPromptQuery` layout, copies the array with the engine's property operations, supplies an initialized empty array during the original call, then restores and destroys the temporary values before returning. Game hide requests retain their normal behavior. Other ability properties and class defaults are untouched.

The call stack is capped at eight nested frames and each prompt list at eight entries. A replacement supplied by another hook is preserved. No array elements, FText wrappers or modified ability values are retained between calls; no ability search, construction hook, polling or raw game offsets are used. `_QDNSprintConfigure(enabled, logging)` controls the hook's active flag and finite initialization through the existing Lua worker. It is available independently of the standard/native HUD dispatch route when the required APIs and reflected prompt signatures are present.

For prompts already visible when the option is enabled, `_QDNIsSprintPrompt(fullName, address)` resolves and verifies the specific input widget, copies its original FText into an initialized native query block, and checks the `ST_InputNames` keys `Input_Sprint` and `Input_Haste`. It bypasses the Lua FText input conversion and destroys all query parameters before returning. The existing two-slot opacity worker handles hiding and conditional restoration. Other loaders retain localized-label detection. Metadata deletion disables the native helper; Lua sessions disable suppression during cleanup.

Logging reports suppression/restoration counts, failures and aggregate pre-callback time. These are diagnostics, not a measurement of game frame times. Native values and hooks remain subject to the exact host/build boundary above.

## Slash asset retention

`ClawAssets.cpp` exposes `_QDNClawRetain(slot, cueAddress, effectAddress)` and `_QDNClawRelease(slot, token)` independently of the standard/native HUD dispatch route. Two slots accept only the exact Shredded Touch cue defaults and Niagara systems. Constant-path lookups validate the supplied addresses and classes before rooting. Indexed identities and deletion notifications protect release against object replacement, including address/index reuse with a zero serial. Existing root flags are preserved; tokens prevent a stale cleanup from releasing a newer lease. The deletion listener is detached when both slots are released.

Lua loads a missing cue through `AssetRegistryHelpers:GetAsset` with `PackageName` and `AssetName`, the UE5 route used by the pinned UE4SS Blueprint loader. It checks initialization/load/post-load flags and retains the cue and original effect before clearing `OneShotEffect`. Preparation and suppression share one worker slice, at most one cue per frame. There are no additional gameplay hooks or per-hit queries. Lua also handles existing and newly constructed objects of the two exact cue classes. Enablement takes one object snapshot per class, followed by bounded processing through the existing worker. Conditional restoration uses the default's retained original system; construction events cover later objects without recurring searches. At most four objects are rooted while suppression owns the two effects; their referenced assets remain resident too. Session cleanup restores the original field before releasing its lease. Process teardown never accesses game objects from a non-game thread.

Other supported Lua hosts use the same bounded preparation and conditional restoration without native retention. Cosmetic cleanup failures are contained within that feature; strict cleanup behavior in the shared session library is unchanged. The diagnostic `clawMarks` timing includes preparation and overlaps the enclosing worker timing.

## Additional HUD routes

Event IDs 1â€“28 remain stable. IDs 29â€“32 add the combat marker graph's hard-lock entry 1370, the Focus prompt graph (context only), GameHUD crosshair text enablement and quickslot visibility. GameHUD event 23 preserves entry 4146 and also delivers Focus entries 2442, 2657 and 4026. Distinct entry values survive queue coalescing. Bindings validate the parameter kinds actually read; unavailable optional routes do not disable unrelated controls. Revalidate these graph entries against the relevant assets after game changes.

## Combat icon presentation

`CombatIcons.cpp` registers a separate `ProcessLocalScriptFunction` post observer through the existing UE4SS interception API. It works with either HUD event delivery route. Its pointer table matches the two stock icon renderers, the unblockable renderer, available marker event wrappers and selected marker graph entries (1370 lock, 952 icon change, 30 latent continuation, 582 clear, 41 distance). Other functions return before a lock or object lookup. Graph entries are semantic routing evidence, not a host-version gate; recheck the affected marker asset when its graph changes.

The existing Lua game-thread worker validates the marker's player/world, prepares reflected metadata and registers at most 64 marker leases. Only discovery and explicit settings changes find classes, functions and selected sprites. The drawing callback never calls Lua, reads settings files, searches objects, schedules work or polls. It applies one priority decision after stock drawing: enabled attack/counterattack/warning, then enabled hard-lock padlock, then enabled enemy diamond. It hides the stock lock overlays. A hidden warning's animation is stopped before the replacement is styled; an enabled warning keeps its stock animation. Near/far container animation and scale remain game/Lua responsibilities.

The guard validates the fields and input parameters it actually reads or calls: property kinds, bounds, Boolean masks, non-overlapping call storage and live indexed identities. It accepts inherited image/marker classes, moved fields, padding, float/double vector components and extra unrelated fields. Missing optional event wrappers and disabled arrow-style helpers do not block the remaining policy. It does not check whole-file hashes, host version strings or fork names. A missing required render contract disables this guard's affected work with a diagnostic while Lua recovery and unrelated HUD features remain available.

Atlas assignment uses `bMatchSize=false`; explicit positive finite cooked `BakedSourceDimension` values repair `Brush.ImageSize`, including an existing zero-size brush. Only changed dimensions invalidate layout. The host's incomplete interface argument cannot erase the size. No borrowed reflected struct is retained. Child/function/asset deletion invalidates cached identities without object reads or allocation in the deletion callback; zero-serial address reuse and stale cleanup tokens cannot affect a new marker. A drawing failure suspends that lease until bounded worker recovery. A failed first paint releases its partial ownership immediately.

Lua uses `_QDNCuesVersion`, `_QDNCuesConfigure(options, logLevel)`, `_QDNCuesApply(address, originalOpacity)`, `_QDNCuesRelease(address, token)`, `_QDNCuesStats` and `_QDNCuesStop`. The small API version belongs to the bundled Lua/native protocol. Cleanup is one marker per existing Session slice, restores owned opacity/visibility conditionally and redraws current stock presentation before the final stop. Logging Debug records native event/paint/write/repair/failure/stale counts and aggregate draw/setup time; normal logging avoids this timing work. Initial discovery and unsupported contracts retain the existing deferred limitations. Offline fixtures and operation counts do not establish live frame-time or visual performance.
