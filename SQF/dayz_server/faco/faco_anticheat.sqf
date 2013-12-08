/*
        Created exclusively for ArmA2:OA - Epoch DayZ Mod.
        Please request permission to use/alter/distribute from the author (facoptere@gmail.com)
*/

// change this value to anything else
#define RANDOM 7890
#include "\z\addons\dayz_server\faco\faco_anticheat.hpp"
 
// max number of player session during server uptime (to preallocate array)
#define MAXOWNER 500

VAR(forbidweap) = WEAPBLACKLIST;
VAR(forbidmags) = MAGSBLACKLIST;
VAR(limitmags) = MAGSGREYLIST;

FACOCODE = {

#include "\z\addons\dayz_server\faco\init.sqf"
		if (!isNil "dayz_locationCheck") then { terminate dayz_locationCheck; };
		stream_locationCheck = {};
		stream_ntg = {
#include "\z\addons\dayz_server\faco\newTownGenerator.sqf"
objNull
		};
		fnc_usec_damageHandler = {
#include "\z\addons\dayz_server\faco\fnc_usec_damageHandler.sqf"
		};
		fnc_usec_unconscious = {
#include "\z\addons\dayz_server\faco\fn_unconscious.sqf"
		};		
#include "\z\addons\dayz_server\faco\client_flies.sqf"
#include "\z\addons\dayz_server\faco\faco_weather_client2.sqf"
		building_spawnLoot = {
#include "\z\addons\dayz_server\faco\building_spawnLoot.sqf"
		};
		zombie_generate2 = {
#include "\z\addons\dayz_server\faco\zombie_generate.sqf"
		};
		building_spawnZombies2 = {
#include "\z\addons\dayz_server\faco\building_spawnZombies.sqf"
		};
		zombie_generate = { _this call zombie_generate2; };
		building_spawnZombies = { _this call building_spawnZombies2; };
		player_spawnCheck2 = {
#include "\z\addons\dayz_server\faco\player_spawnCheck.sqf"		
		};
		player_spawnCheck = {};
		zombie_findTargetAgent = {
#include "\z\addons\dayz_server\faco\zombie_findTargetAgent.sqf"
		};
//			dayz_losCheck = {
//#include "\z\addons\dayz_server\faco\dayz_losCheck.sqf"					
//			};
		player_spawn_1 = {
#include "\z\addons\dayz_server\faco\player_spawn_1.sqf"		
		};

		if (!isNil "dayz_animalCheck") then { terminate dayz_animalCheck; };	
		if (!isNil "dayz_HintMontior") then { terminate dayz_HintMontior; };	
		if (!isNil "dayz_playerBubble") then { terminate dayz_playerBubble; };
		if (!isNil "dayz_monitor1") then { terminate dayz_monitor1; };
		if (!isNil "dayz_spawnCheck") then { terminate dayz_spawnCheck; };
		if (!isNil "dayz_lootCheck") then { terminate dayz_lootCheck; } else { dayz_lootCheck = [] spawn {}; }; // referenced in player_death
		if (!isNil "dayz_zedCheck") then { terminate dayz_zedCheck; } else { dayz_zedCheck = [] spawn {}; }; // 
		if (!isNil "dayz_locationCheck") then { terminate dayz_locationCheck; } else { dayz_locationCheck = [] spawn {}; };
		if (!isNil "dayz_combatCheck") then { terminate dayz_combatCheck; } else { dayz_combatCheck = [] spawn {}; };
		if (!isNil "dayz_friendliesCheck") then { terminate dayz_friendliesCheck; } else { dayz_friendliesCheck = [] spawn {}; };
		if (!isNil "dayz_Totalzedscheck") then { terminate dayz_Totalzedscheck; };

		dayz_lowHumanity = {}; // called by client_monitor.fsm, but defined anywhere!
		USEC_canDisassemble = AllPlayers;
		USEC_PackableObjects = [ "TentStorage","TentStorageDomed","TentStorageDomed2" ]; // called in fn_damageAction
		USEC_LogisticsItems = [];
		USEC_LogisticsDetail = [];
		s_player_lockunlock = [];
		s_player_tamedog = -1;
		r_player_bloodregen = 0;

		dayz_animalCheck = [] spawn player_spawn_1;
		[] spawn {
#include "\z\addons\dayz_server\faco\antihack.sqf"
		};
		if (!isNil "gcam_main") then { TitleText["GCAM tool loaded.\nPress O/P/L","PLAIN DOWN", 0.2]; };
};
FACOCODEADMIN = {
	gcam_main = {
#include "\z\addons\dayz_server\faco\gcam.sqf"
	};
#include "\z\addons\dayz_server\faco\gcam_init.sqf"
};

faco_sendSecret = {
	// _this:  player to send the secret key. this function is called at playerSetup step.
	private ["_ownr"];
	_ownr = owner _this;		
	VAR(secrets) set [_ownr, round(random 1000000)]; // choose a secret
#include "\z\addons\dayz_server\faco\gcam_uid.hpp"
	if ((getPlayerUID _this) in ADMINS) then {
		PVCLIENTADMIN = FACOCODEADMIN;
		_ownr publicVariableClient Stringify(PVCLIENTADMIN);
	};
	PVCLIENT = FACOCODE;
	_ownr publicVariableClient Stringify(PVCLIENT);
	diag_log(format["Overwriting client code for user:%1%2",_this,
		if ((getPlayerUID _this) in ADMINS) then {", GCAM enabled"} else {""}
	]);
};

FNC(checkSecret) = {
	// _this 0: player who send a report
	// _this 1: secret to check;
	private ["_owner"];
	_ownr = owner (_this select 0);		
	(VAR(secrets) select _ownr) == (_this select 1)
};

faco_initclientac = {
	private ["_tmpmaxid"];
	VAR(secrets) = []; // array of shared secrets
	for "_x" from 0 to 100 do {
		VAR(secrets) set [_x, 0];
	};

	diag_log "faco_initclientac: FACO players anti-cheat inited";

	// starting anti-cheat on players already connected
	{
		if (isPlayer _x) then {
			_x call faco_sendSecret;
		};
	} forEach playableUnits;
};

FNC(kickPlayer) = {
#ifdef KICKCHEATER
	if (KICKCHEATER) then {
		if ((!isNil "_this") AND {(isPlayer _this)}) then {
			[getPlayerUID _this, name _this ] call onPlayerDisconnect;
			[ nil, _this, "loc", "execVM", "ca\Modules\MP\data\scriptCommands\endMission.sqf", nil, nil, "LOSER", false ] call RE; // disconnect player
		};
	};
#endif
};

FNC(getid) = {
	private ["_id", "_found"];
	_found = false;
	_id = [48];
	{
		if (_x == 58) exitWith{};
		if (_x == 32) then { _found = true; }
		else { if (_found) then { _id set [ count _id, _x]; }; };
	} forEach toArray Str _this;
	_id = parseNumber(toString(_id));
	
	_id
};

FNC(procReport) = {
	private["_reporter","_reporterSecret","_checkType","_target","_payload", "_obj"];
	_reporter = _this select 0;
	_reporterSecret = _this select 1;
	_checkType = _this select 2;
	_target = _this select 3;
	_payload = _this select 4;
	
	diag_log(format ["FACO procReport %1",_this]);

	if ([_reporter, _reporterSecret] call FNC(checkSecret)) then {
		switch (_checkType) do {
			case "Box": {  // box full of weapons
				{
					_obj = _x select 0; // object
					if ((!isNull _obj) AND {((owner _obj) > 1)}) then {
						_target = (owner _obj) call FNC(owner2player);
						if (_obj call FNC(checkCargo) >= 3) then { // cargo contains illegal things
							diag_log(format["FACO HACK illegal item %1 spawned by player %2",
								_x,
								_target call fa_plr2str
							]);
							deleteVehicle _obj;
							_target call FNC(kickPlayer);
						}
						else {
							// false report
						};
					}
					else { // reporter gave false info!
//						diag_log(format["FACO %1 false report: box %2, content %3", _reporter, _x, (getWeaponCargo _x)]);
					};
				} forEach _payload;
			};
			case "Wpn": {  // player who has hacked weapon 
				if ((isPlayer _target) AND {(((getMarkerpos "respawn_west") distance _target) > 2000)}) then {
					//diag_log(format["FACO Hack %1 !!!!reports hacked weapon(s) %2 on %3 at %4", 
					//	_reporter call fa_plr2str, _payload, 
					//	_target call fa_plr2str, (getPos _target) call fa_coor2str]);
					_ownr = owner _target;
					_target setOwner 0; // take ownership since removeweapon is limited to the character owner
					if (_x call FNC(checkCargo) >= 3) then { // illegal things
						[_target,(magazines _target),true,(unitBackpack _target)] call server_playerSync;
						diag_log(format["FACO HACK illegal item in inventory for player %1", _target call fa_plr2str]); 	
						_target call FNC(kickPlayer);// disconnect player
					}
					else {
					//	diag_log(format["FACO %1 false report: player %2, weapons %3", _reporter, _target, (weapons _target) ]);

					};
					_target setOwner _ownr; 
				};
			};
	/*		case "Veh"; case "Bld": {  // hacked buildings whose owner is a player
				{
					_obj = _x select 0;
					if ((((!isNull _obj) AND {(owner _obj > 1)}) AND {(!((typeOf _obj) IN ["Land_Fire_DZ", "TentStorage","UH60Wreck_DZ","UH1Wreck_DZ"] ))}) AND {((_obj call FNC(getid))>VAR(lastvalidobjectid))}) then {
						_target = (owner _obj) call FNC(owner2player);
						diag_log(format["FACO HACK illegal building %1 spawned by player %2 at %3", 
							_x, 
							_target call fa_plr2str, (getPos _obj) call fa_coor2str]);
						deleteVehicle _obj;
						_target call FNC(kickPlayer);
					}
					else { // reporter gave false info!? object is local to gameclient?
					};
				} forEach _payload;
			};*/
			default {
				diag_log format (["FACO report unknown %1",_this]);
			};
		};
	}
	else { // else: reporter authentication failed
		diag_log format (["FACO authent failed %1",_this]);
	};	

	true
};


Stringify(PVSERVER) addPublicVariableEventHandler {(_this select 1) call FNC(procReport) };


// ANTI TELEPORT PART

FNC(inittpdata) = {
	if (isNil Stringify(VAR(plrtpdata))) then {

		VAR(plrtpdata) = []; // array of player positions. index= player owner id.
		for "_x" from 0 to MAXOWNER do {
			VAR(plrtpdata) set [_x, [0,(getMarkerpos "respawn_west"),0,nil]];
		};

		diag_log(format["FACO players atp data inited"]);
	};
};

// reset tp data
faco_reset = {
	_player = _this select 0;
	_pos = _this select 1;
	_dir = _this select 2;
	_veh = _this select 3;
	
	if (count _pos <2 ) then { _pos = nil; };
	call FNC(inittpdata); // set array if not already set
	VAR(plrtpdata) set [(owner _player), [time, _pos, _dir, _player, _veh]];
	//diag_log (format["FACO TP reset data for player %1. owner:%2 data:%3", 
		//_player call fa_plr2str, owner _player, VAR(plrtpdata) select (owner _player) ]);
};
 
FNC(owner2player) = {
	(VAR(plrtpdata) select _this) select 3
};

FNC(checkTPone) = {/*
	private ["_x", "_checkveh", "_attack"];
	_x = _this select 0; // player object
	_checkveh = _this select 1; // true:  check if player is in vehicle. useful for GetIn EH
	_attack=0;

	if ((!isNil "_x") AND {(((isPlayer _x) AND {(alive _x)}) AND {((!_checkveh) OR {(vehicle _x == _x)})})}) then {
		private ["_npos","_tpdata","_opos","_trip","_ntime","_otime","_delay","_bias","_speed","_ndir"];
		_npos = getPosASL vehicle _x;
		_tpdata = +(VAR(plrtpdata) select(owner _x));	
		if (isNil "_tpdata") then { 
			_tpdata = [ 0, (getPosASL _x), 0 ];
			diag_log (format["FACO TP reset data for player %1 during check! count:%2 owner:%3", 
				_x call fa_plr2str, count VAR(plrtpdata), owner _x]);
		};
		_opos = _tpdata select 1;
		_trip = [_npos select 0,_npos select 1,0] distance [_opos select 0,_opos select 1,0];

		if ((_trip > 100 AND _checkveh) OR (_trip > 500 AND !_checkveh)) then { // skip check if no huge move 
			_ntime = time;			
			_otime = _tpdata select 0;
			_delay = 2 max (_ntime - _otime); // avoid DIV!0
			_bias = (0.977 + 1 / _delay + 16 / diag_fps / diag_fps);
			_speed = ((3.6 * _trip / _delay / _bias) max (speed _x)) max (3.6 * ([0,0,0] distance (velocity _x)));
			_ndir = getdir _x; 
			if (!_checkveh) then { diag_log (format["FACO TP DEBUG %1 pos:%2 tm/tp/dl/fps:%3:%4:%5:%6:  rl/dmg/scr/beh/hid:%7:%8:%9:%10:%11 in/plr/alv:%12:%13:%14  _speed:%15 _checkveh:%16 _bias:%17", _x call fa_plr2str,_npos call fa_coor2str, _ntime, _trip, _delay, diag_fps, unitRecoilCoefficient  _x, damage _x, score _x, behaviour _x, isHidden _x, ( _x IN dayz_players), isPlayer _x, alive _x, _speed, _checkveh,_bias ]); };
			if ((_speed > 36 ) AND {((((getMarkerpos "respawn_west") distance _npos) >= 2000) OR {( _x IN dayz_players)} // skip check if killed player is TP towards debug area
				)})  then { 
				_prevveh =  _tpdata select 4;
				if ((!_checkveh) AND {(isNil "_prevveh")}) then { // get in with no close get out
					diag_log (format["FACO TP player %1%2, speed:%3 kmph from %4 to %5 .%6", 
						_x call fa_plr2str, 
						(if (!_checkveh) then {" near vehicle"} else {""}),
						round(_speed), 
						_opos call fa_coor2str,
						_npos call fa_coor2str,
						([_x, 10, " Near:"] call fa_whoisnearby)
					]);
					_ndir = _tpdata select 2;
					_npos = _opos;
					_x setDir _ndir;
					_x setPosASL _npos;
					_attack = _attack + 1;
				};
			}
			else {
				//if ((_speed > 1 ) AND {((getMarkerpos "respawn_west") distance _npos >= 2000)}) then {
				//	[_x, nil, true] call server_playerSync;
				//};
			};
			VAR(plrtpdata) set [(owner _x), [_ntime, _npos, _ndir,_x]];
		} // trip was long enough
		else { if (_trip < 0.1) then { // update time in player data if player is still
			_tpdata set [0, time];
			VAR(plrtpdata) set [(owner _x), _tpdata];
		};};
		_tpdata = nil;
	}; // player ok to check

	_attack
	*/ 0
};
 
FNC(checkTPvehone) = {
/*
	private["_ntime","_npos", "_otime","_delay","_opos","_trip","_speed","_i","_bias","_attack", "_x", "_s","_sList"];
	_x = _this select 0; // player object
	_attack=0;

	_ntime = time;
	_otime = _x getVariable ["fatime", -1];
	if (_otime == -1) then { // server is not owner? ... maybe a vehicle created by a cheater
		if 	(typeOf _x != "ParachuteWest") then {
			diag_log (format["FACO TP hacked veh %1, deleted.", _x call fa_veh2str]);
			{ moveOut _x; sleep 0.198; } forEach (crew _x);
			_x removeAllEventHandlers "getIn";
			_x removeAllEventHandlers "getOut";
			_x setPos (getMarkerpos "respawn_west");
			_x setVariable ["fatime", nil];
			deleteVehicle _x;
			_attack=_attack + 1;
		}
		else { // for now player coordinates are not controlled for a parachute
			diag_log (format["FACO TP warning, parachute driven by %1 flying above %2 (possible exploit)", 
				(driver _x) call fa_plr2str,
				(getPos driver _x) call fa_coor2str
			]);		
		};
	}
	else {
		_delay = _ntime - _otime;
		if (_delay >= 2) then { // skip check if delay is too short, so speed is unprecise
			_bias = (0.977 + 1 / _delay + 16 / diag_fps / diag_fps);
			_npos = getPosASL _x;
			_ndir = getdir _x;
			_opos = _x getVariable ["fapos", _npos];
			_odir = _x getVariable ["fadir", _ndir];
			_trip = _npos distance _opos;
			if ((_trip >= 200) OR {(_delay >= 60)}) then { // skip check if no huge move 
				_speed = ((3.6 * _trip / _delay / _bias) max (speed _x)) max (3.6 * ([0,0,0] distance (velocity _x))); 
				if (_speed >= 35) then {
					//[_x, "position", true] call server_updateObject;
					if (_x isKindOf "Ship" AND {(!(_x isKindOf "Boat"))}) then { _attack = 1; }
					else { if (_speed >= 85) then {
						if (_x isKindOf "Bicycle") then { _attack = 1; }
						else { if (_speed >= 150) then {
							if (_x isKindOf "LandVehicle") then { _attack = 1; }
							else { if ((_speed >= 350) AND {(_x isKindOf "Air")}) then { _attack = 1; }
							};
						};};
					};};
				};
				if (_attack == 1) then {
					_s = "";
					// if vehicle is TP at 1 player feet, then kick this player.
					_sList = (nearestObjects [_x,["Man"],50]);
					if ((count _sList == 1) AND {(isPlayer (_sList select 0))}) then {
						(_sList select 0) call FNC(kickPlayer);
					};
					{ 
						if ((isPlayer _x) AND {(alive _x)}) then {
							_s = format["%1 %2 ",_s, _x call fa_plr2str]; 
						};
					} foreach _sList;
					if (_s != "") then { _s="Near:"+_s; };
	
					diag_log (format["FACO TP vehicle %1 driven by %2, speed:%3 kmph from %4 to %5 %6. %7", 
						_x call fa_veh2str,
						(driver _x) call fa_plr2str,
						round(_speed),
						_opos call fa_coor2str,
						_npos call fa_coor2str,
						(getNumber (configFile >> "CfgVehicles" >> typeOf (_x) >> "maxSpeed")),
						_s
					]);				
	
					_x setPosASL _opos;
					_x setDir _odir;
					_npos = _opos;
					_ndir = _odir;
					if (!(_x isKindOf "Air")) then {
						{ moveOut _x; } forEach (crew _x);
					};  
				};
				//else { diag_log (format["FACO U.V.O %1 is %2", _x call fa_veh2str, typeOf _x]); }
				_x setVariable ["fatime", _ntime];
				_x setVariable ["fapos", _npos];
				_x setVariable ["fadir", _ndir];
				 //diag_log (format["FACO TP DEBUG vehicle %1 pos:%2 tm/tp/dl:%3:%4:%5", _x call fa_veh2str, (_npos call fa_coor2str), _ntime, _trip, _delay ]);
			}; // trip was long enough
		}; // delay was long enough
	}; // not hacked vehicle
	_attack
	*/ 0
};	
 /*
FNC(checkNearby) = {
	private ["_loop", "_nBuilding"];
	
	for "_loop" from 1 to 10 do {
		_nBuilding = nearestBuilding _this;
		if ((owner _nBuilding != 0) or {(((vectorUp _nBuilding) select 2 < 0.99) AND {(!(typeOf _nBuilding IN ["Land_vez", "Land_Wall_Gate_Ind2A_R", "Land_Wall_Gate_Ind1_L"]))})}) then { 
			diag_log(format["FACO DESTROY building %1 %2 %3",typeOf _nBuilding, owner _nBuilding, vectorUp _nBuilding]);
			_nBuilding call faco_cleanup; 
		}
		else {
			_loop = 99;
		};
	};
};
 */
FNC(checklist) = {
	private["_cargo","_notAllowedWeapons","_limitedWeapons","_oitem", 
		"_oqty","_item","_qty","_needupdate","_q"];
	_cargo = _this select 0;
	_notAllowedWeapons = _this select 1;
	_limitedWeapons = _this select 2;
	
	_oitem = _cargo select 0;
	_oqty = _cargo select 1;
	_item = [];
	_qty = [];
	_needupdate = 0;
	{
		if (!(_x in _notAllowedWeapons)) then { 
			_item set [count _item, _x];
			_q = _oqty select _forEachIndex;
			if ((_q>LIMITGREYLIST) AND {(_x in _limitedWeapons)}) then {
				_q = LIMITGREYLIST;
				_needupdate = 2;
			} else { if (_q>LIMITWHITELIST) then {
				_q = LIMITWHITELIST;
				_needupdate = 1;
			}};
			_qty set [count _qty, _q];
		}
		else {
			_needupdate=3;
		};
	} foreach _oitem;
	
	[_item, _qty, _needupdate]
};

// return true if cargo/magazine/backpack is legit
FNC(checkCargo) = {
	private ["_cargo", "_backpack", "_res" ];

	// filter out illegal items in magazines and weapons cargos
	_cargo = [
		[getWeaponCargo _this, VAR(forbidweap), []] call FNC(checklist),
		[getMagazineCargo _this, VAR(forbidmags), VAR(limitmags)] call FNC(checklist)
	];
	_backpack = getBackpackCargo _this;
	if (count (_backpack select 0)>0) then {
		_cargo set [2, [_backpack, VAR(forbidweap), VAR(limitmags)] call FNC(checklist)];	
	}
	else {
		_cargo set [2, [[],[],0] ];
	};
	// rebuild inventory if something has changed. 
	// 3rd entry in each cargo contains "needupdate" flag set by FNC(checklist)()
	_res = ((_cargo select 0) select 2) + ((_cargo select 1) select 2) + ((_cargo select 2) select 2);
	if (_res > 0 ) then {
		diag_log(format["FACO INVENTORY HACK for %1 gravity:%2 magazines:%3  weapons:%4  backpack:%5",
			if (isPlayer _this) then {(_this call fa_plr2str)} else {(_this call fa_veh2str)},
			_res,
			getMagazineCargo _this,
			getWeaponCargo _this,
			getBackpackCargo _this
		]); 
		[_this, _cargo] call fa_populateCargo;
	};
	
	_res
};

faco_initVehEH = {
	_this addEventHandler ["GetIn", { 
		private ["_player", "_attack"];
		_player = _this select 2;
		_attack = [_player, false] call FNC(checkTPone);
		[_this select 0] call FNC(checkTPvehone);
		if (_attack > 0 ) then {
			[_player] spawn {	sleep 2;moveOut (_this select 0); 
#ifdef KICKCHEATER
								if (KICKCHEATER) then {
									sleep 2;(_this select 0) setDamage 1;
								};
#endif
								sleep 2; (_this select 0) call FNC(kickPlayer);
			};
			diag_log (format["FACO TP player %1 teleported to get in vehicle %2", 
			_player call fa_plr2str, (_this select 0) call fa_veh2str]);
		};
	}];
	_this addEventHandler ["GetOut", { 
		private ["_player"];
		_player = _this select 2;
		if (([_this select 0] call FNC(checkTPvehone)) != 0) then {
			[_player, false] call FNC(checkTPone); // will should trigger TP for the cheater
		}
		else {
			[_player, getPosASL _player, getDir _player, _this select 0] call faco_reset;
			// vehicle is set in #4.
		};
	}];
	
};


faco_anticheat = {
/*
	private["_loop", "_plrchkPeriod", "_vehchkPeriod", "_plrchkNextTime","_enddate","_vehchkNextTime"];
	_plrchkPeriodmax = 10;
	_vehchkPeriodmax = 20;
	_plrchkPeriod = _plrchkPeriodmax;
	_vehchkPeriod = _vehchkPeriodmax;
	_otherchkPeriod = 30;
	_plrchkNextTime = time;
	_enddate = _plrchkNextTime;
	_vehchkNextTime = _plrchkNextTime;
	_espidx = 5;
	_espsuspect = [];
	while {(true)} do {	
		for "_loop" from 1 to 4 do {
			private["_attack"];
	 
			_enddate=_enddate+_otherchkPeriod;
		
			switch (_loop % 2) do { // check one of 4 low priority security checks
	//			case 0 : {
	// 				diag_log ("FACO checking for ESP...");
	// 				[_espidx, _espsuspect] call faco_checkESP;
	// 			};
	// 			case 1 : {
// 					diag_log ("FACO checking players inventory...");
// 					{ 
// 						_x call FNC(checkCargo); 
// 						_x call FNC(checkWeap);
// 						_x call FNC(checkNearby);
// 						if (_forEachIndex%10==0) then { sleep 0.1; };
// 					} forEach playableUnits; 
// 				};
	// 			case 2 : {
	// 				diag_log ("FACO checking for ESP...");
	// 				[_espidx, _espsuspect] call faco_checkESP;
	// 			};
	// 			case 3 : {
//				case 1 : {
				case 0 : {
					diag_log ("FACO checking vehicles inventory...");
					{ 
						_x call FNC(checkCargo);
						//_x call FNC(checkWeap);
						if (_forEachIndex%10==0) then { sleep 0.1; };
					} forEach vehicles; 
				};
	// 			case 4 : {
	// 				diag_log ("FACO checking for ESP...");
	// 				[_espidx, _espsuspect] call faco_checkESP;
	// 			};
				default {
				};
			};
			
			// teleport check are high priority and period is adaptative
			while { time < _enddate } do {
				//diag_log (format["FACO scheduler  time:%1  _plrchkNextTime:%2   _vehchkNextTime:%3", 
				//	time, _plrchkNextTime, _vehchkNextTime]);
				sleep (0.1 max (((_vehchkNextTime min _plrchkNextTime) min _enddate) - time));
				if (time >= _plrchkNextTime) then {
					diag_log ("FACO checking players teleport...");
					_attack = 0;
					{ 
						_attack = _attack + ([_x, true] call FNC(checkTPone)); 
						if (_forEachIndex%10==0) then { sleep 0.1; };
					} forEach playableUnits;
					_plrchkPeriod = if (_attack > 0) then { 2 } else { (2 max (_plrchkPeriodmax min (_plrchkPeriod * 1.26))) };
					_plrchkNextTime = _plrchkNextTime + _plrchkPeriod;
				};
// 				if (time >= _vehchkNextTime) then {
// 					diag_log ("FACO checking vehicles teleport...");
// 					_attack = 0;
// 					{
// 						if (_x isKindOf "AllVehicles") then {
// 							if !(_x call fa_antiesp_check) then { _attack = _attack + ([_x] call FNC(checkTPvehone)); };
// 							if (_forEachIndex%10==0) then { sleep 0.1; };
// 						};
// 					} forEach dayz_serverObjectMonitor;
// 					_vehchkPeriod = if (_attack > 0) then { 2 } else { (2 max (_vehchkPeriodmax min (_vehchkPeriod * 1.26))) };
// 					_vehchkNextTime = _vehchkNextTime + _vehchkPeriod;
// 				};
			}; // 1 minute loop
		};  // for 1 2 3 4
	}; // while
	*/
};

{
	call compile format["%1OLD = %2; %3 = { diag_log('HACK %4 with args: '+str(_this)); _this call %5OLD; };", _x, _x, _x, _x, _x];
} forEach [
	"BIS_fnc_invRemove",
	"BIS_fnc_invSlotsEmpty",
	"BIS_fnc_invSlots",
	"BIS_fnc_createmenu",
	"BIS_fnc_help",
	"BIS_fnc_sceneAreaClearance",
	"BIS_fnc_sceneCreateSceneTrigger",
	"BIS_fnc_sceneCreateSoundEntities",
	"BIS_fnc_sceneSetObjects",
	"BIS_fnc_locations",
	"BIS_fnc_RESPECT",
	"BIS_fnc_swapVars"
];

call FNC(inittpdata);

// overwritting ...
"PVDZ_sec_atp" addPublicVariableEventHandler { 
		_x = _this select 1;
		if (typeName _x == "STRING") then {
				diag_log _x;
		}
		else {
				_unit = _x select 0;
				_unitPos = getPosATL vehicle _unit;
				_source = _x select 1;
				if (((!(isNil {_source})) AND {(!(isNull _source))}) AND {((_source isKindOf "CAManBase") AND {(owner _unit != owner _source)})}) then {
						diag_log format ["P1ayer %1 hit by %2 %3 from %4 meters at %5",
								_unit call fa_plr2Str,  _source call fa_plr2Str, _x select 2, _x select 3,
								if ((getMarkerpos "respawn_west") distance _unitPos < 2000) then { "DEBUG AREA" } else { _unitPos call fa_coor2str }
								];
						if (_unit getVariable["processedDeath", 0] == 0) then {
								_unit setVariable [ "attacker", name _source ];
								_unit setVariable [ "noatlf4", diag_ticktime ]; // server-side "not in combat" test, if player is not already dead
								_source setVariable [ "noatlf4", diag_ticktime ]; // server-side "not in combat" test, if player is not already dead
						};
				};
		};
};

diag_log format ["FACO %1 %2 serverside anticheat loaded", __FILE__, __LINE__ ];
