/*
        Created exclusively for ArmA2:OA - Epoch DayZ Mod.
        Please request permission to use/alter/distribute from the author (facoptere@gmail.com)
*/

//diag_frameno=0;
dayz_currentGlobalZombies=0;
dayz_currentGlobalAnimals=0;
dayz_CurrentNearByZombies=0;
dayz_spawnZombies=0;
p1_frameno=0;
p1_wasblocked=0;
p1_lowfpsCtr=0;
p1_checkInsideBuilding = {
        private ["_inside", "_relPos", "_this", "_point", "_boundingBox", "_min", "_max", "_myX", "_myY", "_myZ", "_offset"];

        _building = _this select 0;
        _point = _this select 1;
        _inside = false;
        _offset = 1; // shrink building boundingbox by this length.

        _relPos = _building worldToModel _point;
        _boundingBox = boundingBox _building;

        _min = _boundingBox select 0;
        _max = _boundingBox select 1;
        _myX = _relPos select 0;
        _myY = _relPos select 1;

        if ((_myX > (_min select 0)+_offset) and {(_myX < (_max select 0)-_offset)}) then {
			if ((_myY > (_min select 1)+_offset) and {(_myY < (_max select 1)-_offset)}) then {
				_inside = true;
			};
        };
        _inside
};

dayz_buriedZombies=[];
p1_checkBuriedZombies = {
	private ["_a","_c","_b","_node","_foot","_head","_z"];

	//_a = 0; _c=0;_b = objNull;
	_c = count dayz_buriedZombies;
	if (_c > 0) then { // give a zombie a little pitch if necessary
		_c = _c - 1;
		_node = dayz_buriedZombies select _c;
		_foot = _node select 0;
		_head = _node select 1; 
		_z = _node select 2;
		if (lineIntersects [_head, _foot,_z]) then {
			_z setPosASL _head;
			_z setVelocity [0,0,1];
			//diag_log format [ "ppos:%1 z:%2", getPosATL player, _z ]; 
		};
		dayz_buriedZombies resize _c;
	}
	else { // find potential buried zombies
		{
			_z = _x;
			_pos = (getPosATL _z);
			if ((alive _z) AND {(_pos select 2 < 0.05)}) then {
				//_a = _a + 1;
				_b = nearestBuilding _z;
				if ((!isNull _b) AND {([_b, _pos] call p1_checkInsideBuilding)}) then {
					//_c = _c+1;
					_foot = ATLtoASL _pos;
					_foot set [ 2, (_foot select 2) + 0.1 ];
					_head = +(_foot);
					_head set [ 2, (_foot select 2) + 1.5 ];
					dayz_buriedZombies set [ count dayz_buriedZombies, [_foot, _head, _z] ];
				};
			};
		} forEach ((getPosATL player) nearEntities ["zZombie_Base", 30]);
	};
	//diag_log format [ "alive+ground: %1, inbuilding: %2  plr in:%3 %4", _a, _c, [_b, getPosATL player] call p1_checkInsideBuilding, _b  ];
};

p1_epoch_dicloseCity = { // every 5 seconds
	private ["_world","_nearestCity","_town","_first"];
	
	_world = toUpper(worldName); //toUpper(getText (configFile >> "CfgWorlds" >> (worldName) >> "description"));
	_nearestCity = nearestLocations [getPos player, ["NameCityCapital","NameCity","NameVillage","NameLocal"],300];
	if (count _nearestCity > 0) then {
		_town = text (_nearestCity select 0); 
		if(dayz_PreviousTown == "Wilderness") then {
			dayz_PreviousTown = _town;
		};
		if(_town != dayz_PreviousTown) then {
			_first = [_world,_town,""] spawn BIS_fnc_infoText;
		};
		dayz_PreviousTown = _town;
	};
};

p1_resetBisLibs = {
	reactPlayer = {};
	BIS_selectRandomSentenceFunc = {};
	reactCore_Full = {};
	reactCore_Degenerated = {};

	BIS_Effects_Secondaries = {
#include "\z\addons\dayz_server\faco\secondaries.sqf"
	};
	BIS_Effects_AirDestruction = {
#include "\z\addons\dayz_server\faco\airdestruction.sqf"
	};
	BIS_Effects_EH_Killed = {
#include "\z\addons\dayz_server\faco\killed.sqf"
	};
	BIS_Effects_AirDestructionStage2 = {
#include "\z\addons\dayz_server\faco\AirDestructionStage2.sqf"
	};
};


onEachFrame {
	private [ "_day", "_x", "_y", "_zed" ];

	if (deathHandled) then { onEachFrame {}; };

	if ((p1_wasblocked > 0) OR (p1_frameno % 30 == 0)) then {
		if ((getMarkerpos "respawn_west") distance (getPosATL vehicle player) < 2000) then {
			disableUserInput false;
			p1_wasblocked = p1_wasblocked +1;
			if (p1_wasblocked >= 5000) then {
				diag_log "Hey! Hey! Bad guy...";
				endMission "LOSER";
			};
		}
		else {
			if (p1_wasblocked > 0) then {
				if ((isNil "r_player_unconscious") OR {(!r_player_unconscious)}) then { disableUserInput true; };
				p1_wasblocked = 0;
			};
		};
	};

	//if (p1_frameno % 60 == 0) then { call fnc_usec_damageActions; };
	//if (p1_frameno % 60 == 12) then { call fnc_usec_selfActions; };

	if ((p1_lowfpsCtr < 50) AND {(diag_fpsmin < 10)}) exitWith { p1_lowfpsCtr = p1_lowfpsCtr +1; };
	p1_frameno=p1_frameno+1; // put this AFTER exitWith.
	if (diag_fpsmin < 10) then { p1_lowfpsCtr = p1_lowfpsCtr +1; };
	if (p1_lowfpsCtr >= 100) then {
		p1_lowfpsCtr = 2;
		hintSilent "LOW FPS, PLEASE CHANGE YOUR GRAPHIC SETTINGS";
	};
	if (diag_fpsmin >= 10) then { 
		if (p1_lowfpsCtr == 1) then { hintSilent ""; };
		p1_lowfpsCtr = 0 max (p1_lowfpsCtr -1); 
	};
	
	//if (p1_frameno % 3 == 0) then { call stream_ntg; }; // new town generator
	if (p1_frameno % 1625 == 1) then {
		call p1_resetBisLibs;

		_x = diag_fpsmin;
		dayz_currentGlobalZombies = 0;
		dayz_spawnZombies = 0;
		dayz_CurrentNearByZombies = 0;
		{
			dayz_currentGlobalZombies = dayz_currentGlobalZombies + 1;
			_dis = _x distance vehicle player;
			if (local _x) then {
				dayz_spawnZombies = dayz_spawnZombies + 1;
				if (_dis > 300) then {
					_zed = _x;
					if (0 == {((isPlayer _x) AND {((alive _x) AND {(_zed distance vehicle _x < 300)})})} count playableUnits) then {
						deleteVehicle _x;
						dayz_spawnZombies = dayz_spawnZombies - 1;
						dayz_currentGlobalZombies = dayz_currentGlobalZombies - 1;
					};
				};
			};
			if (_dis < 70) then {
				dayz_CurrentNearByZombies = dayz_CurrentNearByZombies + 1;
			};
		} forEach entities "zZombie_Base";
		//diag_log format [ "%1: update Zombies counters. fps: %2 -> %3%4",__FILE__,_x, diag_fpsmin,if (diag_fpsmin < 10) then {"!! <<<<<<<<<<<<<<<<<<<"} else {""}  ];
	};
	if (p1_frameno % 7500 == 0) then { 
		p1_frameno = 0;
		_x = diag_fpsmin;
		dayz_currentGlobalAnimals = count entities "CAAnimalBase"; 
		//diag_log format [ "%1: update dayz_currentGlobalAnimals. fps: %2 -> %3%4",__FILE__, _x, diag_fpsmin,if (diag_fpsmin < 10) then {"!! <<<<<<<<<<<<<<<<<<<"} else {""} ];
	};
	if (p1_frameno % 7500 == 5000) then { 
		[] spawn {
			_x = diag_fpsmin;
			call player_animalCheck;
			//diag_log format [ "%1: player_animalCheck. fps: %2 -> %3%4",__FILE__, _x, diag_fpsmin,if (diag_fpsmin < 10) then {"!! <<<<<<<<<<<<<<<<<<<"} else {""} ];
		}; 
		_day = round(365.25 * (dateToNumber date));
		if(dayz_currentDay != _day) then {
			dayz_sunRise = call world_sunRise;
			dayz_currentDay = _day;
		};
	};

	if (p1_frameno % 150 == 1) then {
		call p1_epoch_dicloseCity;
	};

	if (p1_frameno % 1500 == 0) then {
		_y = diag_fpsmin;
		dayz_currentWeaponHolders = count ((getPosATL vehicle player) nearObjects ["ReammoBox",250]);
		//diag_log format [ "%1: update dayz_currentWeaponHolders. fps: %2 -> %3",__FILE__, _y, diag_fpsmin,if (diag_fpsmin < 10) then {"!! <<<<<<<<<<<<<<<<<<<"} else {""} ];
	};

	if (p1_frameno % 5 == 4) then {
		dayz_maxNearByZombies = 20;
		dayz_maxGlobalZeds = 500;
		dayz_maxLocalZombies = 30 min floor (2 * dayz_maxGlobalZeds / (count playableUnits));  
		switch true do {
			case (isNil "dayz_sg_state"): { // init 
				dayz_sg_state = 0;
				dayz_sg_newzed = [];
				dayz_sg_newloot = [];
				dayz_sg_newlootSmall = [];
				dayz_sg_timer = diag_tickTime;
			};
			case (dayz_sg_state == 0): { // wait for its turn
				if (diag_tickTime - dayz_sg_timer > 2) then {
					dayz_sg_timer = dayz_sg_timer +2;
					dayz_sg_state = 1;
				};
			};
			case (dayz_sg_state == 1): { // fill up dayz_sg_newzed & dayz_sg_newloot
				dayz_sg_newzed resize 0;
				dayz_sg_newloot resize 0;
				dayz_sg_newlootSmall resize 0;
				call player_spawnCheck;
				dayz_sg_state = if (count dayz_sg_newloot + count dayz_sg_newzed != 0) then {2} else {0};
			};
			case (dayz_sg_state == 2): { // exhaust arrays: 1 loot and 1 zed per 5-frame call
				_x = count dayz_sg_newzed;
				_y = false;
				if (_x > 0) then {
					_x = _x -1;
					(dayz_sg_newzed select _x) call zombie_generate2;
					dayz_sg_newzed resize _x;
					_y = true;
				};
				_x = count dayz_sg_newloot;
				if (_x > 0) then {
					_x = _x -1;
					(dayz_sg_newloot select _x) call spawn_loot;
					dayz_sg_newloot resize _x;
					_y = true;
				};
				_x = count dayz_sg_newlootSmall;
				if (_x > 0) then {
					_x = _x -1;
					(dayz_sg_newlootSmall select _x) call spawn_loot_small;
					dayz_sg_newlootSmall resize _x;
					_y = true;
				};
				if !_y then { dayz_sg_state = 0; }; // endless loop...
			};
		};
	};
	
	if (p1_frameno % 5 == 0) then { // weather
		if (!isNil "faw_target") then {
			_ratio = -1;
			if (!(isNil "faw_directive") AND {((faw_target select 0) - diag_tickTime <= 0)}) then { // we should have reached the forecast
				faw_directive = +(faw_target);
				//diag_log "WEATHER target reached";
			}
			else { // linear regression from init to target
				_ratio = (diag_tickTime - (faw_init select 0)) / ((faw_target select 0) - (faw_init select 0));
				faw_directive = [];
				for "_x" from 1 to 6 do {
					_y = (faw_target select _x) - (faw_init select _x);
					_y = _y * _ratio;
					_y = _y + (faw_init select _x);
					if (_x < 6) then { _y = 0 max (1 min _y); };
		//diag_log format [ "compute %8 time: faw_target:%1 faw_init:%2 ela:%3 ratio:%4   value: faw_target:%5 faw_init:%6 value:%7",
		//faw_target select 0,faw_init select 0,diag_tickTime - (faw_init select 0),_ratio,
		//faw_target select _x, faw_init select _x, _y,_x];
					faw_directive set [ _x, _y ];
				};
			};
			// change snow according to altitude (snow -> rain)
			if (faw_directive select 5 > 0) then {
				_player_temperature = faw_temperature + (350 - ((getPosASL player) select 2)) / 100;
				// todo: set dayz_temperature
				_remove =  1 min ((0 max (_player_temperature - 4)) / 2.5);
				if (_remove > 1) then {
					faw_directive set [ 2, 0.1 + (faw_directive select 5) * _remove / 10 ]; // more rain
					faw_directive set [ 5, (faw_directive select 5) * (1 - _remove) ]; // less snow
				};
			};
		
			_trunc = {
				private [ "_x" ];
				_x = _this + 0.0001;
				_x = str _x;
				_x = toArray _x;
				_x resize (5 min count _x);
				(toString _x)
			};
		/*	
			diag_log format [ "WEATHER   C:%1<%2<%3   R:%4<%5<%6   F:%7<%8<%9   %10", 
			(faw_init select 1) call _trunc, (faw_directive select 1) call _trunc, (faw_target select 1) call _trunc, 
			(faw_init select 2) call _trunc, (faw_directive select 2) call _trunc, (faw_target select 2) call _trunc, 
			(faw_init select 3) call _trunc, (faw_directive select 3) call _trunc, (faw_target select 3) call _trunc,
			_ratio call _trunc ]; */
			0 setRain (faw_directive select 2); 
			0 setFog (faw_directive select 3); 
			0 setOvercast (faw_directive select 1); 

			setWind [(faw_directive select 4) * sin(faw_directive select 6) * 10, 
				(faw_directive select 4) * cos(faw_directive select 6) * 10 , true];
		}
		else {
			//diag_log "Requesting weather params....";
			drn_AskServerDynamicWeatherEventArgs = player;
			publicVariableServer "drn_AskServerDynamicWeatherEventArgs";
		};
	};
	
	if (p1_frameno % 30 == 0) then {
		call p1_checkBuriedZombies;
	};
	if (p1_frameno % 30 == 15) then {
		call player_zombieCheck;
	};
};

"dayzSetDate" addPublicVariableEventHandler {
	private [ "_newdate", "_date" ];
	_newdate = _this select 1;
	_date = +(date); // [year, month, day, hour, minute].
	{
		if (_x != _newdate select _forEachIndex) exitWith {
			setDate _newdate;
			//diag_log format [ "%1: Setting date to %2, previous was %3. (fps min: %4)", __FILE__, _newdate, date, diag_fpsmin ];
		};
	} forEach _date;
};





			