// this file is not uploaded to clients

/*
        Created exclusively for ArmA2:OA - Epoch DayZ Mod.
        Please request permission to use/alter/distribute from the author (facoptere@gmail.com)
*/

_nearbySize = 300; // look for cells around this radius
_chunkSize = 10; // how many objects to create per frame
switch true do {
	case (isNil "dayz_ntg_state"): { // init new town generator
			dayz_ntg_state = 0;
			dayz_ntg_follow = {player}; //use some code here, could be useful for GCAM to change the character to follow
			dayz_ntg_newActive = [];
			dayz_ntg_currentActive = [];
			dayz_ntg_var1 = 0;
			dayz_ntg_var2 = 0;
			dayz_ntg_grid = [];
			dayz_ntg_grid resize 4096;
			dayz_ntg_minX=50000;
			dayz_ntg_minY=50000;
			_maxX=-50000;
			_maxY=-50000;
			_townarray = configFile >> "CfgTownGenerator";
			for "_i" from (count _townarray)-1 to 0 step -1 do {
				_objectarray = (_townarray select _i);
				for "_j" from ((count _objectarray) - 1) to 0 step -1 do {
					_object = _objectarray select _j;
					if (isClass(_object)) then {
						_position = [] + getArray (_object >> "position");
						_x = _position select 0;
						_y = _position select 1;
						dayz_ntg_minX = dayz_ntg_minX min _x;
						dayz_ntg_minY = dayz_ntg_minY min _y;
						_maxX = _maxX max _x;
						_maxY = _maxY max _y;
					};
				};
			};
			dayz_ntg_minX = floor dayz_ntg_minX;
			dayz_ntg_minY = floor dayz_ntg_minY;
			dayz_ntg_cellX = ceil((_maxX - dayz_ntg_minX) / 64);
			dayz_ntg_cellY = ceil((_maxY - dayz_ntg_minY) / 64);
			for "_i" from (count _townarray)-1 to 0 step -1 do {
				_objectarray = (_townarray select _i);
				for "_j" from (count _objectarray) - 1 to 0 step -1 do {
					_object = _objectarray select _j;
					if (isClass(_object)) then {
						_position = [] + getArray (_object >> "position");
						_type = getText (_object >> "type");
						_dir = getNumber (_object >> "direction");
						//_onFire = getNumber (_object >> "onFire");
						_x = _position select 0;
						_y = _position select 1;
						_index = floor((_x - dayz_ntg_minX) / dayz_ntg_cellX) + floor((_y - dayz_ntg_minY) / dayz_ntg_cellY) * 64;
						_cell = dayz_ntg_grid select _index;
						if (isNil "_cell") then { _cell = []; dayz_ntg_grid set [ _index, _cell]; };
						_cell set [ count _cell, [ objNull, _type, _position, _dir/*, _onFire*/ ] ];
					};
				};
			};
		};
	case (dayz_ntg_state == 0): { // look for new cells to show and old cells to hide
			_character = call dayz_ntg_follow;
			_position = getPosASL vehicle _character;
			_x = _position select 0;
			_y = _position select 1;
			// shift postion to 1 second in the future:
			_velocity = velocity vehicle _character;
			_x = _x + (_velocity select 0);
			_y = _y + (_velocity select 1);
			dayz_ntg_newActive resize 0;
			for "_i" from (_y+_nearbySize) to (_y-_nearbySize) step -dayz_ntg_cellY do { 
				_iy = floor((_i - dayz_ntg_minY) / dayz_ntg_cellY);
				if ((_iy >= 0) AND {(_iy < 64)}) then {
					for "_j" from (_x-_nearbySize) to (_x+_nearbySize) step dayz_ntg_cellX do {
						//diag_log format [ "%1:  x y _i _j %1 %2 %3 %4", __FILE__, _x, _y, _i, _j ];
						_jx = floor((_j - dayz_ntg_minX) / dayz_ntg_cellX);
						if ((_jx >= 0) AND {(_jx < 64)}) then {
							if (abs((_j-_x)*(_i-_y)) < _nearbySize * _nearbySize) then {
								_index = _jx + _iy * 64;
								//diag_log format [ "%1:                            -> index=%2", __FILE__, _index ];
								_cell = dayz_ntg_grid select _index;
								if ((!isNil "_cell") AND {!(_index IN dayz_ntg_newActive)}) then {
									dayz_ntg_newActive set [ count dayz_ntg_newActive, _index ];
								};
							};
						};
					};
				};
			};
			dayz_ntg_state = 1;
			dayz_ntg_var1 = 0;
			dayz_ntg_var2 = 0;
			dayz_ntg_fps = diag_fpsmin;
			dayz_ntg_newSpawned = 0;
			dayz_ntg_newTextureSpawned = 0;
		};
	case (dayz_ntg_state == 1): { // show new cells, per shunk of _chunkSize objects
			if (dayz_ntg_var1 >= count dayz_ntg_newActive) then {
				dayz_ntg_state = 2;
				dayz_ntg_var1 = 0;
				dayz_ntg_var2 = 0;
				dayz_ntg_deleted = 0;
			}
			else {
				_index = -1;
				// don't wait to next frame to find a new cell to show
				while {dayz_ntg_var1 < count dayz_ntg_newActive} do {
					_index = dayz_ntg_newActive select dayz_ntg_var1;
					if !(_index IN dayz_ntg_currentActive) exitWith {};
					dayz_ntg_var1 = dayz_ntg_var1 +1;
					_index = -1;
					//dayz_ntg_var2 = 0;
				};
				if (_index >= 0) then {
					// create objects from cell index _index
					_cell = dayz_ntg_grid select _index;
					_imax = (count _cell) min (dayz_ntg_var2 + _chunkSize);
					//diag_log format ["%1: spawn cell #%2, %4 objects from #%3", __FILE__, _index, dayz_ntg_var2, _imax-dayz_ntg_var2 ];
					for "_i" from dayz_ntg_var2 to _imax-1 do {
						_x = _cell select _i;
						dayz_ntg_newSpawned = dayz_ntg_newSpawned + 1;
						if (0 == sizeOf (_x select 1)) then { dayz_ntg_newTextureSpawned = dayz_ntg_newTextureSpawned +1 ; };
						_object = (_x select 1) createVehicleLocal [0,0,0];
						_position = _x select 2;
						_object setDir (_x select 3);
						_object setPos [_position select 0,_position select 1,0];
						_object setPosATL _position;
						_object allowDamage false;
						//_onFire ...
						_object setVariable ["", true]; // SV used by player_spawnCheck, exists if object is local
						_x set [ 0, _object ]; // object reference for faster delete
					};
					dayz_ntg_var2 = _imax;
					if (_imax == count _cell) then {
						dayz_ntg_var1 = dayz_ntg_var1 +1;
						dayz_ntg_var2 = 0;
					};
				};
			};
		};	
	case (dayz_ntg_state == 2): { // hide whole cells
			if (dayz_ntg_var1 >= count dayz_ntg_currentActive) then {
				dayz_ntg_currentActive = +(dayz_ntg_newActive);
				dayz_ntg_state = 0;
				dayz_ntg_var1 = 0;
				if ((dayz_ntg_newSpawned > 0) or (diag_fpsmin < 10)) then {
					diag_log format [ "%1: spawned:%2 newTexture:%3 deleted:%4  fps: %5 -> %6%7", __FILE__,
						dayz_ntg_newSpawned, dayz_ntg_newTextureSpawned, dayz_ntg_deleted, dayz_ntg_fps, diag_fpsmin, if (diag_fpsmin < 10) then {"!! <<<<<<<<<<<<<<<<<<<"} else {""} ];
				};
			}
			else {
				_index = -1;
				// don't wait to next frame to find a new cell to hide
				while {dayz_ntg_var1 < count dayz_ntg_currentActive} do {
					_index = dayz_ntg_currentActive select dayz_ntg_var1;
					if !(_index IN dayz_ntg_newActive) exitWith {};
					dayz_ntg_var1 = dayz_ntg_var1 +1;
					_index = -1;
					//dayz_ntg_var2 = 0;
				};
				if (_index >= 0) then {
					//diag_log format ["%1: despawn cell #%2", __FILE__, _index ];
					// delete objects from cell index _x
					{
						deleteVehicle (_x select 0);
						_x set [ 0, objNull ];
						dayz_ntg_deleted = dayz_ntg_deleted +1;
					} forEach (dayz_ntg_grid select _index);
					//dayz_ntg_currentActive = dayz_ntg_currentActive - [_x];
				};
				dayz_ntg_var1 = dayz_ntg_var1 +1;
			};
		};
	default {};
}; // switch
//diag_log format ["%1: state:%2 cellWidth:%3 cellHeight:%4 var1:%5 var2:%6 currentActive:%7 newActive:%8", __FILE__,
//	dayz_ntg_state, dayz_ntg_cellX, dayz_ntg_cellY, dayz_ntg_var1, dayz_ntg_var2, dayz_ntg_currentActive, dayz_ntg_newActive ];








			