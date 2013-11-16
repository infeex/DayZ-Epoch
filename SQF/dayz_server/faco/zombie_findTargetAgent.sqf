/*
        Created exclusively for ArmA2:OA - Epoch DayZ Mod.
        Please request permission to use/alter/distribute from the author (facoptere@gmail.com)
*/


private ["_target","_targets","_localtargets","_remotetargets", "_remotetargets_changed", "_idx", "_values", "_penalty", "_idx" ];
_agent = _this;
if (isNull _agent) exitWith {ObjNull};
prev_target = objNull;
//if (isNil "prev_target") then { prev_target = objNull; };
//_target = prev_target;
_target = objNull;
_targets = [];
_values = [];
_range = 50;


_localtargets = _agent getVariable ["localtargets",[]];
if (isNil "_localtargets") then { _localtargets = []; }; // bug workaround?
_remotetargets = _agent getVariable ["remotetargets",[]];
_remotetargets_changed = false;

_searchNew = {
	if (isNil "last_searchNew") then { last_searchNew = 0; searchNew_targets = []; };
	if (diag_tickTime - last_searchNew > 5) then {
		//_agent setVariable ["last_searchNew",diag_tickTime];
		last_searchNew = diag_tickTime;
		searchNew_targets = [];
		searchNew_targets = searchNew_targets + ((getposATL _agent) nearObjects ["GrenadeHandTimedWest",_range]);
		searchNew_targets = searchNew_targets + ((getposATL _agent) nearObjects ["ThrownObjects",_range]);
		searchNew_targets = searchNew_targets + ((getposATL _agent) nearObjects ["LitObject",_range]);
		searchNew_targets = searchNew_targets + ((getposATL _agent) nearObjects ["SmokeShell",_range]);
	};
	//diag_log format ["%1 %2", _target, searchNew_targets ];
	_targets = _targets + searchNew_targets;
};

_findBest = {
	// give a weight to each target. lighter is better
	_values = [];
	_penalty = floor(sqrt(_range)/2); // 4 for a _range of 75 meters
	{
		// first, the further is the target, the worse it is
		_idx = floor(sqrt(_x distance _agent)/2);
		// give some bonus/malus according to object class and daylight
		_idx = 0 max (_idx + (switch true do {
			case (isNull _x): {_penalty};
			case (_idx > _penalty): {0};
			case (isPlayer _x): {-2*_penalty};
			case (_x call _checkKnown > 20): {_penalty};
			case (_x isKindOf "GrenadeHandTimedWest"): {-_penalty}; // assuming explosion is (will be) heard
			case (_x isKindOf "SmokeShell"): {-_penalty/(6-4*round sunOrMoon)}; // Zeds can't see smoke in dark
			case (_x isKindOf "RoadFlare"): {-_penalty/(1+2*round sunOrMoon)}; // sparkling flares are more attractive than players during the night			
			case (_x isKindOf "Chemlight"): {-_penalty/(2+4*round sunOrMoon)}; // Zeds can't see chemlights in daylight			
			default {-_penalty/3}; // tin can thrown
		})); 
		_values set [ _forEachIndex, _idx ];
	} forEach _targets;
	// most item in "values" should be between 0 (close and interesting) and 4 (far)
	// if above 4, the object went further the _range or got destroyed (isNull)
	
	// find lighter target and set "_target". use previous target as reference
	_idx = if (!isNull prev_target) then { _targets find prev_target } else { -1 };
	_idx = if (_idx >= 0) then { _values select _idx } else { _penalty };
	{
		if (_x > _penalty) then {
			_targets set [ _forEachIndex, objNull ];
		}
		else {
			if (_x < _idx) then {
				_idx = _x;
				_target = _targets select _forEachIndex;
			};
		};
	} forEach _values;
	// _target should be the best target, at least better than prev_target;
	// prev_target is kept otherwise
};

_checkKnown = {
	private [ "_ret", "_idx", "_iknowit", "_iknowitcount" ];
	_ret = 0;
	if ((!isNull _this) and {(!isPlayer _this)}) then {
		_iknowit = _agent getVariable [ "iknowit", [] ];
		_iknowitcount = _agent getVariable [ "iknowitcount", [] ];
		_idx = _iknowit find _this;
		if (_idx >= 0) then {
			_ret = _iknowitcount select _idx;
			if (isNil "_ret") then { _ret = 0; };
		};
	};
	//diag_log format [ "%1 %2 %3", _agent, _this, _ret ];
	_ret
};

_incrementknown = {
	if ((!isNull _target) and {(!isPlayer _target)}) then {
		_iknowit = _agent getVariable [ "iknowit", [] ];
		_iknowitcount = _agent getVariable [ "iknowitcount", [] ];
		_idx = _iknowit find _target;
		if (_idx >= 0) then {
			_count = _iknowitcount select _idx;
			if (isNil "_count") then { _count = 0; };
			if ((!isNil "_count") AND {(_count > 10)})then {
				_target = objNull;
			}
			else {
				_iknowitcount set [ _idx, 1 + _count ];
			};
		}
		else {
			_iknowit set [ count _iknowit, _target ];
			_iknowitcount set [ count _iknowit, 0 ];
		};
		_agent setVariable [ "iknowit", _iknowit ];
		_agent setVariable [ "iknowitcount", _iknowitcount ];	
	};
};

_refreshList = {
	{
		if ((!isNull _x) and {(_x != _target)}) then {
			if (local _x) then {
				_idx = _localtargets find _x;
				if (_idx < 0) then {
					if (_values select _forEachIndex < _range) then {
						_localtargets set [ count _localtargets, _x ];
					};
				}
				else {
					if (_values select _forEachIndex >= _range) then {
						_localtargets = _localtargets - [_x];
					};
				};
			}
			else {
				_idx = _remotetargets find _x;
				if (_idx < 0) then {
					if (_values select _forEachIndex < _range) then {
						_remotetargets_changed = true;
						_remotetargets set [ count _remotetargets, _x ];
					};
				}
				else {
					if (_values select _forEachIndex >= _range) then {
						// _remotetargets_changed = true; // we won't broadcast the change to save bandwidth
						_remotetargets = _remotetargets - [_x]
					};
				};
			};
		};
	} forEach _targets;
};

_targets = _localtargets + _remotetargets;
if (count _targets == 0) then {
	call _searchNew;
	if (count _targets > 0) then {
		call _findBest;
	};
}
else {
	call _findBest;
	if (isNull _target) then {
		call _searchNew;
		if (count _targets > 0) then {
			call _findBest;
		};
	};
};

call _incrementknown;

//diag_log format [ "_targets:%1 _values:%2 _target:%3", _targets, _values, _target];	

/*
call _refreshList;
if (!isNull _target) then {
	if (_target in _localtargets) then {
		_localtargets = _localtargets - [_target];
	};
	if (_target in _remotetargets) then {
		_remotetargets = _remotetargets - [_target];
		_remotetargets_changed = true;
	};
};
*/
/*
_agent setVariable ["localtargets",_localtargets];
if (_remotetargets_changed) then {
	if (count _remotetargets > 2) then { _remotetargets resize 2; };// limit target quantities
	_agent setVariable ["remotetargets",_remotetargets, true];
};
*/
//prev_target = _target;
_target
 			