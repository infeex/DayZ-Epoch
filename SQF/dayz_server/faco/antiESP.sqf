/*
        Created exclusively for ArmA2:OA - Epoch DayZ Mod.
        Please request permission to use/alter/distribute from the author (facoptere@gmail.com)
*/

#define CONFIGBASE_VEHMAINTENANCE configFile >> "CfgPatches" >> "vehMaint"

fa_obj2str = {
	private["_res","_id", "_type"];

	_res = "anything";
	_id = "?";
	if ((!isNil "_this") AND {!(isNull _this)}) then {
		_id = _this getVariable ["ObjectID", nil];
		if (isNil "_id") then { 
			_id = _this getVariable ["ObjectUID", nil];
			if (isNil "_id") then { 
				_id = str(_this); 
			};
		};
		_id = format ["OID#%1", _id]; 
		_type = getText(configFile >> "CfgVehicles" >> (typeOf _this) >> "displayName");
		if (_type == "") then { _type = typeOf _this; };
		_res = format["%1(%2) at %3", _id, _type, getPosATL _this ];
	};

	_res
};

fa_antiesp_init = {
	private [ "_SWcorner", "_NEcorner" ];
	fa_antiesp_toAdd = [];
	fa_antiesp_toDel = [];
	fa_antiesp_newActive = [];
	fa_antiesp_currentActive = [];
	fa_antiesp_grid = [];
	fa_antiesp_grid resize 4096;
	_SWcorner = getArray(CONFIGBASE_VEHMAINTENANCE >> (worldName) >> "SWcorner");
	_NEcorner = getArray(CONFIGBASE_VEHMAINTENANCE >> (worldName) >> "NEcorner");
	fa_antiesp_minX=floor(_SWcorner select 0);
	fa_antiesp_minY=floor(_SWcorner select 1);
	fa_antiesp_cellX = ceil(((_NEcorner select 0) - fa_antiesp_minX) / 64);
	fa_antiesp_cellY = ceil(((_NEcorner select 1) - fa_antiesp_minY) / 64);
	fa_antiesp_nearbySize = 1.2 * (fa_antiesp_cellX max fa_antiesp_cellY);
	fa_antiesp_state = 0;
	fa_antiesp_lastScan = 0;
	fa_antiesp_quarantine_X = -500 + ((getMarkerPos "respawn_west") select 0);
	fa_antiesp_quarantine_Y = -500 + ((getMarkerPos "respawn_west") select 1);
	fa_antiesp_quarantine_index = 0;
	diag_log format [ "%1::inited  cell size: %2x%3", __FILE__,fa_antiesp_cellX, fa_antiesp_cellY ];
	fa_antiesp_start = false;
};

fa_antiesp_add = {
	private [ "_index" ];
	// _this -> object
	if (fa_antiesp_toAdd find _this < 0) then { // not already enqueued?
		_this call fa_antiesp_checkout; // remove object if already in grid
		if (_this call fa_antiesp_check) then {
			diag_log format [ "%1: Error, object %2 in debug, wont enqueue", __FILE__, _this call fa_obj2str ];
		}
		else {
			_index = _this getVariable [ "fa_antiesp_cellid", -1 ];
			if ((!isNil "_index") AND {(_index > 0)}) then {
				diag_log format [ "%1: Error, object %2 already in grid, wont enqueue", __FILE__, _this call fa_obj2str ];
			}
			else {
				fa_antiesp_toAdd set [ count fa_antiesp_toAdd, _this ]; // enqueue object, will be added in state 3.
				diag_log format [ "%1 enqueue added %2", __FILE__, _this];
			};
		};
	};
};

fa_antiesp_checkout = {
	private [ "_index", "_cell" ];
	if (fa_antiesp_toDel find _this < 0) then { // not already enqueued?
		_index = _this getVariable [ "fa_antiesp_cellid", -1 ];
		if ((!isNil "_index") AND {(_index > 0)}) then {
			fa_antiesp_toDel set [ count fa_antiesp_toDel, _this ]; // enqueue object, will be deleted in state 3.
			//diag_log format [ "%1 enqueue deleted %2", __FILE__, _this];
		}/*
		else {
			diag_log format [ "%1: Error, object %2 not in grid, wont dequeue", __FILE__, _this call fa_obj2str ];
		}*/;
	};
};

fa_antiesp_realpos = {
	private ["_res","_index","_cell"];

	_res = _this getVariable [ "fa_realpos", nil ];
	if (isNil "_res") then {
		_res = getPosATL _this;
	};
	if (isNil "_res") exitWith { diag_log format [ "%1: Error, %2 not found in grid, maybe in debug? ", __FILE__, _this call fa_obj2str ]; };
	_res
};

// true = object moved to quarantine, do not update to hive, since position is wrong!
fa_antiesp_check = {
	private [ "_position" ];
	// _this -> object
	if (isNull _this) exitWith {false};
	_position = _this getVariable [ "fa_quarantine", nil ];
	if (isNil "_position") exitWith {false};
	(_this distance _position < 20)
};

fa_antiesp_microtask = {
private ["_chunkSize","_character","_position","_px","_py","_velocity","_radius","_iy","_i","_j",
"_jx","_index","_cell","_object","_vup","_tmp_pos","_quarantine_pos"];
	_chunkSize = 10; // how many objects to create per frame
	switch true do {
		case (fa_antiesp_state == 0): { // look for new cells to show and old cells to hide
				if (diag_tickTime - fa_antiesp_lastScan >= 1) then {
					fa_antiesp_lastScan = diag_tickTime;
					fa_antiesp_newActive resize 0;
					{
						if (isPlayer _x) then {
							_character = vehicle _x;
							_position = getPosATL _character;
							_px = _position select 0;
							_py = _position select 1;
							// shift postion to 1 second in the future:
							_velocity = velocity _character;
							_px = _px + (_velocity select 0);
							_py = _py + (_velocity select 1);
							_radius = fa_antiesp_nearbySize + 0.5 * ([0,0,0] distance _velocity);
							for "_i" from (_py+_radius) to (_py-_radius) step -fa_antiesp_cellY do { 
								_iy = floor((_i - fa_antiesp_minY) / fa_antiesp_cellY);
								for "_j" from (_px-_radius) to (_px+_radius) step fa_antiesp_cellX do {
									//diag_log format [ "%1:  x y _i _j %1 %2 %3 %4", __FILE__, _px, _py, _i, _j ];
									_jx = floor((_j - fa_antiesp_minX) / fa_antiesp_cellX);
									if (abs((_j-_px)*(_i-_py)) < fa_antiesp_nearbySize * fa_antiesp_nearbySize) then {
										_index = abs(_jx + _iy * 64) % 4096;
										//_cell = fa_antiesp_grid select _index;
										if !(_index IN fa_antiesp_newActive) then {
											fa_antiesp_newActive set [ count fa_antiesp_newActive, _index ];
										};
									};
								};
							};
						};
					} forEach playableUnits;
					fa_antiesp_state = 1;
					fa_antiesp_var1 = 0;
					fa_antiesp_var2 = 0;
					fa_antiesp_newSpawned = 0;
					//diag_log format [ "%1 active: %2",__FILE__,  fa_antiesp_newActive];
				};
			};
		case (fa_antiesp_state == 1): { // show a whole cell from new cells 
				if (fa_antiesp_var1 >= count fa_antiesp_newActive) then {
					fa_antiesp_state = 2; // switch to "move to quarantine" state
					fa_antiesp_var1 = 0;
					fa_antiesp_var2 = 0;
					fa_antiesp_deleted = 0;
				}
				else {
					_index = -1;
					// don't wait to next frame to find a new cell to show
					while {fa_antiesp_var1 < count fa_antiesp_newActive} do {
						_index = fa_antiesp_newActive select fa_antiesp_var1;
						_cell = fa_antiesp_grid select _index;
						if ((!isNil "_cell") AND {!(_index IN fa_antiesp_currentActive)}) exitWith {};
						fa_antiesp_var1 = fa_antiesp_var1 +1;
						_index = -1;
						//fa_antiesp_var2 = 0;
					};
					if (_index >= 0) then {
						diag_log format ["%1: show cell #%2", __FILE__, _index ];
						// move objects listed in cell index _index
						{
							if (!isNull _x) then {
								_position = _x getVariable [ "fa_realpos", nil ];
	//							_vup = _x select 2;
	//							if (count (_x getVariable ["fapos", []]) > 0) then {
	//								_x setVariable ["fapos", _position];
	//							};
								//_x setVectorUp _vup;
								if (isNil "_position") then {
									diag_log format [ "Error: fa_realpos undefined for %1, wont move",_x call fa_obj2str]; 
								}
								else {
									if (!(_x isKindOf "CAManBase") AND {(count crew _x > 0)}) then { diag_log("Error: crew in object "+str(_x)); };
									if (_x distance _position < 1) then { diag_log format ["Error: %1 already in its pos ", _x call fa_obj2str]; };
									if !(_x call fa_antiesp_check) then { 
										diag_log format [ "Error: should be in debug %1",_x call fa_obj2str];
										//_x call fa_antiesp_add; // reindex
									};
									_x setPosATL _position;
								};
							};
						} forEach (fa_antiesp_grid select _index);
						fa_antiesp_var1 = fa_antiesp_var1 +1;
					};
				};
			};	
		case (fa_antiesp_state == 2): { // move to quarantine a whole cell from cells to hide
				if (fa_antiesp_var1 >= count fa_antiesp_currentActive) then {
					fa_antiesp_currentActive = +(fa_antiesp_newActive);
					fa_antiesp_state = 3;
					fa_antiesp_var1 = 0;
				}
				else {
					_index = -1;
					// don't wait to next frame to find a new cell to hide
					while {fa_antiesp_var1 < count fa_antiesp_currentActive} do {
						_index = fa_antiesp_currentActive select fa_antiesp_var1;
						_cell = fa_antiesp_grid select _index;
						if ((!isNil "_cell") AND {!(_index IN fa_antiesp_newActive)}) exitWith {};
						fa_antiesp_var1 = fa_antiesp_var1 +1;
						_index = -1;
						//fa_antiesp_var2 = 0;
					};
					if (_index >= 0) then {
						diag_log format ["%1: hide cell #%2", __FILE__, _index ];
						// delete objects from cell index _x
						{
							if (!(isNull _x) AND {((_x isKindOf "CAManBase") OR {(count crew _x == 0)})}) then {
								_position = _x getVariable [ "fa_quarantine", nil ]; // quarantine pos
	//							if (count (_x getVariable ["fapos", []]) > 0) then {
	//								_x setVariable ["fapos", fa_antiesp_quarantine];
	//							};
								if (isNil "_position") then {
									diag_log format [ "Error: fa_quarantine undefined for %1, wont move to debug",_x call fa_obj2str]; 
								}
								else {
									if (_x distance _position < 1) then { diag_log format ["Error: %1 already in debug ", _x]; };
									_tmp_pos = [ 
										fa_antiesp_minX + fa_antiesp_cellX * (0.5+(_index % 64)), 
										fa_antiesp_minY + fa_antiesp_cellY * (0.5+floor(_index / 64)), 
										0 ];
									if (_x distance _tmp_pos > 400) then { 
										diag_log format [ "Error: not in its cell %1  %2",_x call fa_obj2str, _x distance _tmp_pos ]; 
										//_x call fa_antiesp_add; // reindex
									};
									_x allowDamage false;
									_x setPosATL _position;
								};
								fa_antiesp_deleted = fa_antiesp_deleted +1;
							};
						} forEach (fa_antiesp_grid select _index);
						//fa_antiesp_currentActive = fa_antiesp_currentActive - [_x];
					};
					fa_antiesp_var1 = fa_antiesp_var1 +1;
				};
			};
		case (fa_antiesp_state == 3): { // allow damage for swpawned item
				if (fa_antiesp_var1 >= count fa_antiesp_newActive) then {
					fa_antiesp_currentActive = +(fa_antiesp_newActive);
					fa_antiesp_state = if (fa_antiesp_start) then {4} else {0};
					fa_antiesp_var1 = 0;
				}
				else {
					_index = -1;
					// don't wait to next frame to find a new cell to show
					while {fa_antiesp_var1 < count fa_antiesp_newActive} do {
						_index = fa_antiesp_newActive select fa_antiesp_var1;
						_cell = fa_antiesp_grid select _index;
						if ((!isNil "_cell") AND {!(_index IN fa_antiesp_currentActive)}) exitWith {};
						fa_antiesp_var1 = fa_antiesp_var1 +1;
						_index = -1;
						//fa_antiesp_var2 = 0;
					};
					if (_index >= 0) then {
						diag_log format ["%1: show cell #%2", __FILE__, _index ];
						// move objects listed in cell index _index
						{
							if (!isNull _x) then {
								_x setVelocity [0, 0, 0];
								_x allowDamage true;
								fa_antiesp_newSpawned = fa_antiesp_newSpawned +1;
							};
						} forEach (fa_antiesp_grid select _index);
						fa_antiesp_var1 = fa_antiesp_var1 +1;
					};
				};
			};				
		case (fa_antiesp_state == 4): { // insert/delete objects stored in fa_antiesp_add/del into grid
				{
					if (!isNull _x) then {
						_index = _x getVariable [ "fa_antiesp_cellid", -1 ];
						if ((!isNil "_index") AND {(_index > 0)}) then {
							_cell = fa_antiesp_grid select _index;
							if (!isNil "_cell") then {
								_i = _cell find _x;
								if (_i < 0) then {
									diag_log format [ "Error: object %1 not in cell %2", _x  call fa_obj2str, _index ];
								}
								else {
									if (_x call fa_antiesp_check) then { // in quarantine
										_position = _x getVariable [ "fa_realpos", nil ];
										if (!isNil "_position") then {
											_x setPosATL _position;
										}
										else {
											diag_log format [ "%1 Error, unknown realpos for %2", __FILE__, _x call fa_obj2str];
										};
									};
									if (count _cell == 1) then {
										fa_antiesp_grid set [ _index, nil ]; // remove the whole cell
									}
									else {
										_cell = _cell - [_x];
									};
									_x setVariable [ "fa_antiesp_cellid", nil ];
									_x setVariable [ "fa_realpos", nil ];
									_x setVariable [ "fa_quarantine", nil ];
									diag_log format [ "%1 %2 dismiss, actual pos:%3", __FILE__, _x  call fa_obj2str, getPosATL _x];
								};
							};
						};
					};
				} forEach fa_antiesp_toDel;
				fa_antiesp_toDel resize 0;
				{
					_position = getPosATL _x;
					_px = _position select 0;
					_py = _position select 1;
					if (abs(_position select 2) < 0.1) then { _position set [2, 0]; }; 
					_index = abs(floor((_px - fa_antiesp_minX) / fa_antiesp_cellX) + floor((_py - fa_antiesp_minY) / fa_antiesp_cellY) * 64) % 4096;
					_quarantine_pos = [ 
						fa_antiesp_quarantine_X + 20 * (fa_antiesp_quarantine_index % 50), 
						fa_antiesp_quarantine_Y + 20 * floor(fa_antiesp_quarantine_index / 50), 
						0 ]; 
					fa_antiesp_quarantine_index = fa_antiesp_quarantine_index + 1;
					_cell = fa_antiesp_grid select _index;
					_x setVariable [ "fa_realpos", _position ];
					_x setVariable [ "fa_quarantine", _quarantine_pos ];
					if (isNil "_cell") then { _cell = []; fa_antiesp_grid set [ _index, _cell]; };
					_cell set [ count _cell, _x ];
					_x setVariable [ "fa_antiesp_cellid", _index ];
					if (fa_antiesp_currentActive find _index < 0) then {
						// move out to nowhere			
						_x allowDamage false;
	//					if (count (_x getVariable ["fapos", []]) > 0) then {
	//						_x setVariable ["fapos", fa_antiesp_quarantine];
	//					};
						_x setPosATL _quarantine_pos;
						diag_log format [ "%1: object %2 removed from cell #%3 realpos: %4",
						 __FILE__, _x  call fa_obj2str, _index, _position];
					};
				} forEach fa_antiesp_toAdd;
				fa_antiesp_toAdd resize 0;
				fa_antiesp_state = 0;
			}; 
		default {};
	}; // switch
	//diag_log format ["%1: state:%2 cellWidth:%3 cellHeight:%4 var1:%5 var2:%6 currentActive:%7 newActive:%8", __FILE__,
	//	fa_antiesp_state, fa_antiesp_cellX, fa_antiesp_cellY, fa_antiesp_var1, fa_antiesp_var2, fa_antiesp_currentActive, fa_antiesp_newActive ];
};







			