/*
        Created exclusively for ArmA2:OA - DayZMod.
        Please request permission to use/alter/distribute from the author (facoptere@gmail.com)
*/

private ["_cantSee", "_obj", "_recyAgt","_maxtoCreate","_spawnAreaRatio","_buildingType","_config","_unitTypes","_min","_max","_zombieChance","_num0","_num","_halfBuildingSize","_rnd","_clean","_x","_posList","_bsz_pos","_cantSee","_tmp","_wholeAreaSize","_minSector","_spawnSize","_minRadius","_rangeRadius","_rangeAngle","_minAngle","_i","_deg","_radius"];

_obj = _this select 0;
_buildingType = typeOf _obj;
_halfBuildingSize = (sizeOf _buildingType) / 2;
_config = configFile >> "CfgBuildingLoot" >> _buildingType;
if ((!isClass(_config)) OR {(typeName(_config) != "CONFIG")}) then {
        _buildingType = "(Default) "+str(_obj); // for logging purpose only
        _config = configFile >> "CfgBuildingLoot" >> "Default"; // spawn even on non lootable building
		_halfBuildingSize = 2;
};

_unitTypes = getArray (_config >> "zombieClass");
_min = getNumber (_config >> "minRoaming");
_max = getNumber (_config >> "maxRoaming");
_zombieChance = getNumber (_config >> "zombieChance");

_num0 = _min + floor(random(_max - _min + 1));
_num = _num0;

if (_num0 > 0) then {
	_posList = [] + (getArray (_config >> "zedPos"));
	for [{_num = _num0}, {(count _posList > 0) AND (_num >= 2 * _num0 / 3) AND (_num > 0)}, {}] do {
		_bsz_pos = _posList select floor random count _posList;
		if ((!isNil "_bsz_pos") AND {(count _bsz_pos == 3)}) then { // sometime pos from config is empty :(
			_posList = _posList - [_bsz_pos];
			_bsz_pos = _obj modelToWorld _bsz_pos;
			if (_bsz_pos select 2 < 0) then { _bsz_pos set [ 2, 0 ]; };
			//[_bsz_pos, true, _unitTypes] call zombie_generate;
			dayz_sg_newzed set [ count dayz_sg_newzed, [_bsz_pos, true, _unitTypes] ];
			_num = _num -1;
		};
	};
	// Add remaining Z as walking Zombies (outside the building)
	_wholeAreaSize = 15; // for external walking zombies, area size around building where zombies can spawn
	_minSector = 5; // in degree. Only the opposite sector of the building, according to Player PoV, will be used as spawn. put 360 if you want they spawn all around the building
	_spawnSize = (sizeOf "zZombie_Base") max (_halfBuildingSize / 2); // smaller area size inside the sector where findEmptyPosition is asked to find a spot
	_minRadius = _halfBuildingSize + _spawnSize + (_obj distance vehicle player);
	_rangeRadius = _spawnSize max (_wholeAreaSize - _spawnSize);
	_rangeAngle = _minSector max (2 * ((_halfBuildingSize - _spawnSize) atan2 (_obj distance vehicle player)));
	_minAngle = ([_obj, player] call BIS_fnc_dirTo) + 180 - _rangeAngle / 2;
	for [{_i = _num * 3}, {(_num > 0) AND (_i > 0)}, {_i = _i - 1}] do {
		_deg = _minAngle + random _rangeAngle;
		_radius = _minRadius + random _rangeRadius;
		_bsz_pos = getPosATL vehicle player;
		_bsz_pos = [(_bsz_pos select 0) + _radius * sin(_deg), (_bsz_pos select 1) + _radius * cos(_deg), 0];
		_bsz_pos = (+_bsz_pos) findEmptyPosition [0, _spawnSize, "zZombie_Base"];
		if ((count _bsz_pos >= 3) // check that findEmptyPosition found something for us
			AND {(!([_bsz_pos, true] call fnc_isInsideBuilding) // check position is outside any buildings
			AND {({alive _x} count (_bsz_pos nearEntities ["zZombie_Base", 1]) == 0)})} // check position is empty
		) then { 
			_bsz_pos set [2, 0]; // force on the ground
			//_num = _num -([_bsz_pos, true, _unitTypes] call zombie_generate);
			dayz_sg_newzed set [ count dayz_sg_newzed, [_bsz_pos, true, _unitTypes] ];
			_num = _num -1;
		};
	};
};
//diag_log format ["%1:   num:%3 maxnum:%4 type:%5", __FILE__, "", _num, _num0, _buildingType ];
(_num0 - _num)