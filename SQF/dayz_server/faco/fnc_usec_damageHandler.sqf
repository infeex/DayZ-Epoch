 
scriptName "Functions\misc\fn_damageHandler.sqf";
/***********************************************************
	PROCESS DAMAGE TO A UNIT
	- Function
	- [unit, selectionName, damage, source, projectile] call fnc_usec_damageHandler;
************************************************************/
private ["_unit","_humanityHit","_myKills","_hit","_damage","_isPlayer","_unconscious","_wound","_isHit","_isInjured","_type","_hitPain","_isCardiac","_isHeadHit","_isMinor","_scale","_canHitFree","_rndPain","_rndInfection","_hitInfection","_lowBlood","_isPZombie","_source","_ammo","_unitIsPlayer","_isBandit"];
_unit = _this select 0;
_hit = _this select 1;
_damage = _this select 2;
_unconscious = _unit getVariable ["NORRN_unconscious", false];
_isPZombie = player isKindOf "PZombie_VB";
_source = _this select 3;
_ammo = _this select 4;
_type = [_damage,_ammo] call fnc_usec_damageType;

_isMinor = (_hit in USEC_MinorWounds);
_isHeadHit = (_hit == "head_hit");
//_evType = "";
//_recordable = false;
_isPlayer = (isPlayer _source);
_humanityHit = 0;
_myKills = 0;
_unitIsPlayer = _unit == player;

// anti-hack for local explosions (HelicopterExploSmall, HelicopterExploBig, SmallSecondary...) spawned by hackers
_breakaleg = (((_hit == "legs") AND {(_source==_unit)}) AND {((_ammo=="") AND {(!isNil "Dayz_freefall")})}) AND {(abs(time - (Dayz_freefall select 0))<1)};

if ( (!_breakaleg) AND {(((isNull _source) OR {(_unit == _source)}) AND {((_ammo == "") OR {({damage _x > 0.9} count((getposATL vehicle _unit) nearEntities [["Air", "LandVehicle", "Ship"],15]) == 0) AND (count nearestObjects [getPosATL vehicle _unit, ["TrapItems"], 30] == 0)})})}) exitWith {diag_log "argh";0};

//Publish Damage
	//player sidechat format["Processed damage for %1",_unit];
	//USEC_SystemMessage = format["CLIENT: %1 damaged for %2 (in vehicle: %5)",_unit,_damage,_isMinor,_isHeadHit,_inVehicle];
	//PublicVariable "USEC_SystemMessage";

/*
if (_isPlayer) then {
	if (_damage > 0.1) then {
		dayz_canDisconnect = false;
		//["PVDZE_plr_DiscAdd",getPlayerUID player] call callRpcProcedure;
		PVDZE_plr_DiscAdd = getPlayerUID player;
		publicVariableServer "PVDZE_plr_DiscAdd";
				
		dayz_damageCounter = time;
		
		//Ensure Control is visible
		_display = uiNamespace getVariable 'DAYZ_GUI_display';
		_control = 	_display displayCtrl 1204;
		_control ctrlShow true;
	};
};
*/

if (_unitIsPlayer) then {
	if (_hit == "") then {
		if ((_source != player) and _isPlayer) then {
		//Enable aggressor Actions
			if (_source isKindOf "CAManBase") then {
				_source setVariable["startcombattimer",1];	
			};
			_canHitFree = 	player getVariable ["freeTarget",false];
			_isBandit = (player getVariable["humanity",0]) <= -5000;
			_isPZombie = player isKindOf "PZombie_VB";
			
			if (!_canHitFree and !_isBandit and !_isPZombie) then {
				//Process Morality Hit
				_myKills = 0 max (1 - (player getVariable ["humanKills",0]) / 5);
				_humanityHit = -100 * _myKills * _damage;

				//["PVDZE_plr_HumanityChange",[_source,_humanityHit,30]] call broadcastRpcCallAll;
				if (_humanityHit != 0) then {
					PVDZE_plr_HumanityChange = [_source,_humanityHit,30];
					publicVariable "PVDZE_plr_HumanityChange";
				};
			};
		};
	};
	
	if (((!(isNil {_source})) AND {(!(isNull _source))}) AND {((_source isKindOf "CAManBase") AND {(!local _source )})}) then {
		if (diag_ticktime-(_source getVariable ["lastloghit",0])>2) then {
			private ["_sourceWeap"];
			_source setVariable ["lastloghit",diag_ticktime];
			_wpst = weaponState _source;

			_sourceDist = round(_unit distance _source);
			_sourceWeap = switch (true) do {
				case ((vehicle _source) != _source) : { format ["in %1",getText(configFile >> "CfgVehicles" >> (typeOf (vehicle _source)) >> "displayName")] };
				case (_ammo == "zombie") : { _ammo };
				case (_wpst select 0 == "Throw") : { format ["with %1 thrown", _wpst select 3] };
				case (["Horn", currentWeapon _source] call fnc_inString) : {"with suspicious vehicle "+str((getposATL _source) nearEntities [["Air", "LandVehicle", "Ship"],5])};
				case (["Melee", _wpst select 0] call fnc_inString) : { format ["with %2%1",_wpst select 0, if (_sourceDist>6) then {"suspicious weapon "} else {""}] }; 
				case ((_wpst select 0 == "") AND {(_wpst select 4 == 0)}) : { format ["with %1/%2 suspicious", primaryWeapon _source, _ammo] };
				case (_wpst select 0 != "") : { format ["with %1/%2 <ammo left:%3>", _wpst select 0, _ammo, _wpst select 4] };
				default { "with suspicious weapon" };
			};
			if (_ammo != "zombie") then { // don't log any zombie wounds, even from remote zombies
				PVDZ_sec_atp = [_unit, _source, _sourceWeap, _sourceDist];
				publicVariableServer "PVDZ_sec_atp";
			};
		};
	};
};

//PVP Damage
_scale = 200;
if (_damage > 0.4) then {
	if (_ammo != "zombie") then {
		_scale = _scale + 50;
	};
	if (_isHeadHit) then {
		_scale = _scale + 500;
	};
	if ((isPlayer _source) and !(player == _source)) then {
		_scale = _scale + 800;
		if (_isHeadHit) then {
			_scale = _scale + 500;
		};
	};
	switch (_type) do {
		case 1: {_scale = _scale + 200};
		case 2: {_scale = _scale + 200};
	};
	if (_unitIsPlayer) then {
		//Cause blood loss
		//Log Damage
		diag_log ("DAMAGE: player hit by " + typeOf _source + " in " + _hit + " with " + _ammo + " for " + str(_damage) + " scaled " + str(_damage * _scale));
		r_player_blood = r_player_blood - (_damage * _scale);
	};
};

//Record Damage to Minor parts (legs, arms)
if (_hit in USEC_MinorWounds) then {
	private ["_type"]; //DO NOT REMOVE THIS!! it prevents _type being set to "fracture"
	if (_ammo == "zombie") then {
		if (_hit == "legs") then {
			[_unit,_hit,(_damage / 6)] call object_processHit;
		} else {
			[_unit,_hit,(_damage / 4)] call object_processHit;
		};
	} else {
		if (_breakaleg) then {
			_nrj = ((Dayz_freefall select 1)*20) / 100;  // h=5m => nrj=1
				if (random(((1 + _nrj)^2) - 1) >= 1.5) then { // freefall from 5m => 1/2 chance to get hit legs registered
				//diag_log(format["%1 Legs damage registered from freefall. _damage:%2  _nrj:%3 (odds %4:1) freefall:%5",__FILE__, _damage, _nrj,(((1+_nrj)^2)-1)/1.5, Dayz_freefall, time]);
					[_unit,_hit,_damage] call object_processHit;
				}
				else {
					[_unit,"arms",(_damage / 6)] call object_processHit; // prevent broken legs due to arma bugs
				};
		}
		else {
			[_unit,_hit,(_damage / 2)] call object_processHit;
		};
	};
};


if (_unitIsPlayer) then {
//incombat
	_unit setVariable["startcombattimer", 1, false];	
};

if (_damage > 0.1) then {
	if (_unitIsPlayer) then {
		//shake the cam, frighten them!
		//player sidechat format["Processed bullet hit for %1 (should only be for me!)",_unit];
		1 call fnc_usec_bulletHit;
	};
	if (local _unit) then {
		_unit setVariable["medForceUpdate",true,true];
	};
};
if (_damage > 0.4) then {	//0.25
	/*
		BLEEDING
	*/		
	_wound = _hit call fnc_usec_damageGetWound;
	_isHit = _unit getVariable[_wound,false];
	if (_unitIsPlayer) then {	
		_rndPain = 		(random 10);
		_rndInfection = (random 500);
		_hitPain = 		(_rndPain < _damage);
		if ((_isHeadHit) or (_damage > 1.2 and _hitPain)) then {
			_hitPain = true;
		};
		_hitInfection = (_rndInfection < 1);
		//player sidechat format["HitPain: %1, HitInfection %2 (Damage: %3)",_rndPain,_rndInfection,_damage]; //r_player_infected
		if (_isHit) then {
			//Make hit worse
			if (_unitIsPlayer) then {
				r_player_blood = r_player_blood - 50;
			};
		};
		if (_hitInfection) then {
			//Set Infection if not already
			if (_unitIsPlayer and !_isPZombie) then {
				r_player_infected = true;
				player setVariable["USEC_infected",true,true];
			};
			
		};
		if (_hitPain) then {
			//Set Pain if not already
			if (_unitIsPlayer) then {
				r_player_inpain = true;
				player setVariable["USEC_inPain",true,true];
			};
		};
		if ((_damage > 1.5) and _isHeadHit) then {
			[_source,"shothead"] spawn player_death;
		};
	};
	if(!_isHit) then {
		
		if(!_isPZombie) then {
			//Create Wound
			_unit setVariable[_wound,true,true];
			[_unit,_wound,_hit] spawn fnc_usec_damageBleed;
			usecBleed = [_unit,_wound,_hit];
			publicVariable "usecBleed";

			//Set Injured if not already
			_isInjured = _unit getVariable["USEC_injured",false];
			if (!_isInjured) then {
				_unit setVariable["USEC_injured",true,true];
			if ((_unitIsPlayer) and (_ammo != "zombie")) then {
					dayz_sourceBleeding = _source;
				};
			};
			//Set ability to give blood
			_lowBlood = _unit getVariable["USEC_lowBlood",false];
			if (!_lowBlood) then {
				_unit setVariable["USEC_lowBlood",true,true];
			};
			if (_unitIsPlayer) then {
				r_player_injured = true;
			};
		};
	};
};
if (_type == 1) then {
	/*
		BALISTIC DAMAGE		
	*/		
	if ((_damage > 0.01) and (_unitIsPlayer)) then {
		//affect the player
		[20,45] call fnc_usec_pitchWhine; //Visual , Sound
	};
	if (_damage > 4) then {
		//serious ballistic damage
		if (_unitIsPlayer) then {
			[_source,"explosion"] spawn player_death;
		};
	} else {
		if (_damage > 2) then {
			_isCardiac = _unit getVariable["USEC_isCardiac",false];
			if (!_isCardiac) then {
				_unit setVariable["USEC_isCardiac",true,true];
				r_player_cardiac = true;
			};
		};
	};
};
if (_type == 2) then {
	/*
		HIGH CALIBRE
	*/
	if (_damage > 4) then {
		//serious ballistic damage
		if (_unitIsPlayer) then {
			[_source,"shotheavy"] spawn player_death;
		};
	} else {
		if (_damage > 2) then {
			_isCardiac = _unit getVariable["USEC_isCardiac",false];
			if (!_isCardiac) then {
				_unit setVariable["USEC_isCardiac",true,true];
				r_player_cardiac = true;
			};
		};
	};
};

if (!_unconscious and !_isMinor and ((_damage > 2) or ((_damage > 0.5) and _isHeadHit))) then {
	//set unconsious
	[_unit,_damage] call fnc_usec_damageUnconscious;
};