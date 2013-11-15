#include "faco_anticheat.hpp"
if(!isDedicated)then{Stringify(PVCLIENT)addPublicVariableEventHandler{
_initac={if(count _this>0)then{[] spawn (_this select 0);};;true};(_this select 1)call _initac;};};