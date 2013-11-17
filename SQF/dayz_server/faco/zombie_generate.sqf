/*
        Created exclusively for ArmA2:OA - Epoch DayZ Mod.
        Please request permission to use/alter/distribute from the author (facoptere@gmail.com)
*/

private ["_position","_unitTypes","_radius","_method","_agent"];

_position = _this select 0;
_doLoiter = _this select 1; // wander around
_unitTypes = _this select 2; // class of wanted models
//_maxControlledZombies = round(dayz_maxLocalZombies);

_cantSee = {
	private ["_isok"];

	_isok = true;
	_zPos = +(_this select 0);
	if (count _zPos < 3) exitWith {
		diag_log format["%1::_cantSee illegal pos %2", __FILE__, _zPos];
		false
	};
	_zPos = ATLtoASL _zPos;
	_fov = _this select 1; // players half field of view
	_safeDistance = _this select 2; // minimum distance. closer is wrong
	_farDistance = _this select 3; // distance further we won't check
	_zPos set [2, (_zPos select 2) + 1.7];
	{
		_xasl = getPosASL _x;
		if (_xasl distance _zPos < _farDistance) then {
			if (_xasl distance _zPos < _safeDistance) then {
				_isok = false;
			}
			else {
				_eye = eyePos _x; // ASL
				_ed = eyeDirection _x;
				_ed = (_ed select 0) atan2 (_ed select 1);
				_deg = [_xasl, _zPos] call BIS_fnc_dirTo;
				_deg = (_deg - _ed + 720) % 360;
				if (_deg > 180) then { _deg = _deg - 360; };
				if ((abs(_deg) < _fov) AND {( // in right angle sector?
						(!(terrainIntersectASL [_zPos, _eye]) // no terrain between?
						AND {(!(lineIntersects [_zPos, _eye]))}) // and no object between?
					)}) then {
					_isok = false;
				};
			};
		};
		if (!_isok) exitWith {false};
	} forEach playableUnits;

	_isok
};
_agent = objNull;
//if ((dayz_spawnZombies < _maxControlledZombies) and (dayz_CurrentNearByZombies < dayz_maxNearByZombies) and (dayz_currentGlobalZombies < dayz_maxGlobalZeds)) then {
	if ([_position, dayz_cantseefov, 30, dayz_cantseeDist] call _cantSee) then {
		//Check if anyone close
		//_tooClose = {isPlayer _x} count (_position nearEntities ["CAManBase",30]) > 0;
		//if (_tooClose) exitwith {
		//	diag_log ("Zombie_Generate: was too close to player.");
		//};

		//Add zeds if unitTypes equals 0
		if (count _unitTypes == 0) then {
			_unitTypes = []+ getArray (configFile >> "CfgBuildingLoot" >> "Default" >> "zombieClass");
		};

		// lets create an agent
		_type = _unitTypes call BIS_fnc_selectRandom;
		_radius = 0;
		_method = "NONE";
		//if (_doLoiter) then {
		//	_radius = 40;
		//	_method = "CAN_COLLIDE";
		//};
		
		//Check if point is in water
		if (surfaceIsWater _position) exitwith { Diag_log ("Location is in Water Abort"); };

		_agent = createAgent [_type, _position, [], _radius, _method]; 
		//sleep 0.001;

		//add to global counter 
		dayz_spawnZombies = dayz_spawnZombies + 1;
		dayz_CurrentNearByZombies = dayz_CurrentNearByZombies + 1;
		dayz_currentGlobalZombies = dayz_currentGlobalZombies +1;

		//Add some loot
		_loot = "";
		_array = [];
		//Add some loot
		_rnd = random 1;
		if (_rnd > 0.3) then {
			_lootType = configFile >> "CfgVehicles" >> _type >> "zombieLoot";
			if (isText _lootType) then {
				_array = []+ getArray (configFile >> "cfgLoot" >> getText(_lootType));
				if (count _array > 0) then {
					_loot = _array call BIS_fnc_selectRandomWeighted;
					if(!isNil "_array") then {
						_agent addMagazine _loot;
					};
				};
			};
		};

		_agent setVariable["agentObject",_agent];

		if (!isNull _agent) then {
			// sometime Z can be seen flying in very high speed while tp. Its altitude is set underground to hide that.
			/*
			_agtPos = getPosASL _agent; 
			_agtPos set [2, -3];
			_agent setPosASL _agtPos; 
			sleep 0.001;
			_agtPos = +(_position); 
			_agtPos set [2, -3];
			_agent setPosASL _agtPos; 
			sleep 0.001;
			*/
			_agent setDir random 360;
			_agent setPosATL _position;
			_agent setVelocity [0,0,1];
			//sleep 0.001;

			_position = getPosATL _agent;

			_favStance = (
				switch ceil(random(3^0.5)^2) do {
					case 3: {"DOWN"}; // prone
					case 2: {"Middle"}; // Kneel
					default {"UP"} // stand-up
				}
			);
			_agent setUnitPos _favStance;

			_agent setVariable ["stance", _favStance];
			_agent setVariable ["BaseLocation", _position];
			_agent setVariable ["doLoiter", true]; // true: Z will be wandering, false: stay still
			_agent setVariable ["myDest", _position];
			_agent setVariable ["newDest", _position];
			[_agent, _position] call zombie_loiter;
		};
		//add to monitor
		//dayz_zedMonitor set [count dayz_zedMonitor, _agent];
		
		//Disable simulation 
		//PVDZ_Server_Simulation = [_agent, false];
		//publicVariableServer "PVDZ_Server_Simulation";
		
		//Start behavior
		_id = [_position,_agent] execFSM "\z\AddOns\dayz_code\system\zombie_agent.fsm";
	};
//};
if (!isNull _agent) then {1} else {0}


			