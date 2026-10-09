// Quiet Dawn - Configurable HUD. MIT.
#pragma once
namespace RC::LuaMadeSimple { class Lua; }
namespace QuietDawn::CombatIcons {
void registerLua(const RC::LuaMadeSimple::Lua&);
void stop();
void shutdown();
}
