// Quiet Dawn - Configurable HUD. MIT.
#pragma once
#include <array>
#include <algorithm>
#include <cmath>
#include <cstdint>
#include <cstring>
#include <stdexcept>

namespace QuietDawn::CombatIcons {
enum Option : unsigned { Dot=1, Lock=2, Direction=4, Warning=8, Counter=16 };
enum class Sprite { None, Diamond, Padlock, Skull };
struct Plan {
    Sprite center{Sprite::None};
    int arrow{-1}; // Left, Right, Top, Bottom.
    bool parry{}, counter{}, valid{};
    bool shown() const { return center!=Sprite::None || arrow>=0; }
    bool base() const { return center==Sprite::Diamond || center==Sprite::Padlock; }
};
constexpr Plan choose(unsigned options,int icon,bool locked) {
    Plan p;
    if(options>31 || icon<0 || icon>13) return p;
    p.valid=true;
    if((options&Counter) && icon>=10) {
        constexpr std::array map{0,1,3,2};p.arrow=map[icon-10];p.counter=true;
    } else if((options&Direction) && icon>=1 && icon<=8) {
        constexpr std::array map{1,0,2,3};p.arrow=map[(icon-1)%4];p.parry=icon>=5;
    } else if((options&Warning) && icon==9) p.center=Sprite::Skull;
    else if((options&Lock) && locked) p.center=Sprite::Padlock;
    else if(options&Dot) p.center=Sprite::Diamond;
    return p;
}
// The production renderer and the native regression fixture share this order.
// Resolve everything needed by the chosen plan before changing presentation.
template<class Ops> bool render(Ops& ops,unsigned options,int icon,bool locked,bool warningStarted) {
    if(options==0) { ops.root(0);return false; }
    const auto p=choose(options,icon,locked);
    if(!p.valid) throw std::runtime_error("Combat icon state is outside the supported presentation enum");
    ops.prepare(p);
    ops.warningAnimation((options&Warning)!=0 && icon==9,warningStarted);
    if(p.arrow>=0) ops.arrowStyle(p.arrow,p.counter,p.parry);
    // Reticle, far reticle, two stock lock overlays, then four direction images.
    ops.visible(0,p.center!=Sprite::None);
    ops.visible(1,p.base());
    ops.visible(2,false);ops.visible(3,false);
    for(int i=0;i<4;++i) ops.visible(i+4,p.arrow==i);
    if(p.center!=Sprite::None) {
        ops.sprite(0,p.center);
        ops.white(0);
        if(p.base()) ops.sprite(1,p.center);
    }
    ops.root(p.shown()?1.f:0.f);
    return p.shown();
}

// Reflected field offsets and widths are validated at binding, never fixed to
// this game's current binary. These predicates are also exercised with moved
// fields, padding and genuine missing/type/bounds failures in native fixtures.
struct Span { int offset{},width{}; };
inline bool fits(Span s,int ownerBytes) {
    return s.offset>=0 && s.width>0 && ownerBytes>0 && s.offset<=ownerBytes && s.width<=ownerBytes-s.offset;
}
inline bool numeric(Span s,int ownerBytes) { return (s.width==4 || s.width==8) && fits(s,ownerBytes); }
inline double number(const void* base,Span s) {
    const auto p=static_cast<const uint8_t*>(base)+s.offset;
    if(s.width==8) { double v;std::memcpy(&v,p,8);return v; }
    float v;std::memcpy(&v,p,4);return v;
}
inline void number(void* base,Span s,double value) {
    auto p=static_cast<uint8_t*>(base)+s.offset;
    if(s.width==8) std::memcpy(p,&value,8);
    else {const float v=static_cast<float>(value);std::memcpy(p,&v,4);}
}
inline bool near(double a,double b) { return std::isfinite(a) && std::abs(a-b)<=1e-5*std::max(1.,std::abs(b)); }
inline bool dimension(double v) { return std::isfinite(v) && v>0 && v<=3.402823466e38; }
}
