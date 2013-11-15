/*
        Created exclusively for ArmA2:OA - Epoch DayZ Mod.
        Please request permission to use/alter/distribute from the author (facoptere@gmail.com)
*/

private ["_countpos","_lootChance","_index","_weights","_cntWeights","_itemType","_qty","_rnd","_iPos","_obj","_type","_config","_pos","_itemTypes","_positions","_bias", "_pos", "_pos_index", "_i", "_x", "_index", "_existing_loopiles_count", "_deleted_loopiles", "_local"];
_obj = _this;
_type = typeOf _obj;
_config = configFile >> "CfgBuildingLoot" >> _type;
_itemTypes = [] + getArray (_config >> "lootType");
_lootChance = getNumber (_config >> "lootChance");
_qty = 0; // effective quantity of spawned weaponholder
_pos = [] + getArray (_config >> "lootPos");
_countpos = count _pos;
_posidx = [];
for "_i" from _countpos-1 to 0 step -1 do {
	_posidx set [_i, _i];
};
_lootChance = _lootChance * 1.5;
_rnd = 0.5;
_existing_loopiles_count = 0;
_deleted_loopiles = 0;
_local = _obj getVariable [ "", false ];
for "_i" from _countpos to 1 step -1 do {
	_x = _posidx select floor random _i;
	_posidx = _posidx - [_x];
	_x = _pos select _x;
	if ((count _x == 3) AND {(dayz_currentWeaponHolders < dayz_maxMaxWeaponHolders)}) then {	
		_iPos = _obj modelToWorld _x;
		// local building (from towngenerator) -> don't delete previous, don't add another lootpile if previous exists
		_existing_loopiles_count = { if (!_local) then { deleteVehicle _x; _deleted_loopiles=_deleted_loopiles+1;false } else { true } } count (_iPos nearObjects ["ReammoBox", 2]);
		_rnd = random (1 - (_rnd - 0.5) / 10);
		if (((!_local) OR {(_local AND {(_existing_loopiles_count == 0)})}) AND {(_lootChance > _rnd)}) then {
			_index = dayz_CBLBase find _type;
			_weights = dayz_CBLChances select _index;
			_cntWeights = count _weights;
			_index = floor(random _cntWeights);
			_index = _weights select _index;
			_itemType = _itemTypes select _index;
			//[_itemType select 0, _itemType select 1, _iPos, 0.0] call spawn_loot;
			dayz_sg_newloot set [ count dayz_sg_newloot, [_itemType select 0, _itemType select 1, _iPos, 0.0] ];
			dayz_currentWeaponHolders = dayz_currentWeaponHolders + 1;
			_qty = _qty + 1;
		};
	};
};
/*
diag_log format [ "%1: loot for building %2%8. _lootChance:%3 unbiased:%4 deletedLootPiles:%7 newLootPiles:%5 lootpos:%6", __FILE__, 
	_obj, _lootChance, (getNumber (_config >> "lootChance")),
	_qty, _countpos, _deleted_loopiles,
	if (_local) then { "(local)" } else { "" }
];	
*/
_qty			