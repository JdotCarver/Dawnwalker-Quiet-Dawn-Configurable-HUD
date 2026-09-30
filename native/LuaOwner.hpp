// MIT. Validate the host-owned Lua state relationship used by the action queue.
#pragma once
namespace QuietDawn {
template<class Mod,class Lua>
bool matchesLuaOwner(const Mod* mod,const Lua& main,const Lua& async,const Lua* hook) {
    return mod && mod->m_main_lua==&main && mod->m_async_lua==&async && mod->m_hook_lua==hook;
}
}
