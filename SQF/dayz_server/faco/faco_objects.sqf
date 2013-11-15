/*
        Created exclusively for ArmA2:OA - Epoch DayZ Mod.
        Please request permission to use/alter/distribute from the author (facoptere@gmail.com)
*/

fa_setvehevent = {
	_v = _this select 0;
	_pos = _this select 1;
	_dir = _this select 2;
	_v addEventHandler ["GetIn",  compile ("diag_log(format[""FACO VEHEVENT %1 gets in "+(_v call fa_veh2str)+" at %2 as a %3"",(_this select 2) call fa_plr2str, (GetPosATL(_this select 2)) call fa_coor2str, _this select 1 ]);(_this select 0) call fa_antiesp_checkout;")];
 	_v addEventHandler ["GetOut",  compile ("diag_log(format[""FACO VEHEVENT %1 gets out "+(_v call fa_veh2str)+" at %2 as a %3"",(_this select 2) call fa_plr2str, (GetPosATL(_this select 2)) call fa_coor2str, _this select 1 ]);")];
	_v setVariable ["fatime", time]; // this can't be =0
	_v setVariable ["fapos", _pos];
	_v setVariable ["fadir", _dir];
};

fa_setFullMoon = {
	_sm_result = "CHILD:307:" call server_hiveReadWrite;
	_outcome = _sm_result select 0;
	if(_outcome == "PASS") then {
		_date = _sm_result select 1; 
		if(isDedicated) then { //2013/8/2
			_date = [2013,08,02,_date select 3,_date select 4];
			setDate _date;
			dayzSetDate = _date;
			publicVariable "dayzSetDate";
			diag_log ("HIVE: Local Time set to " + str(_date));
		};
	};
};

fa_deleteVehicle = {
	private ["_group"];
	_this removeAllMPEventHandlers "mpkilled";
	_this removeAllMPEventHandlers "mphit";
	_this removeAllMPEventHandlers "mprespawn";
	_this removeAllEventHandlers "FiredNear";
	_this removeAllEventHandlers "HandleDamage";
	_this removeAllEventHandlers "Killed";
	_this removeAllEventHandlers "Fired";
	_this removeAllEventHandlers "GetIn";
	_this removeAllEventHandlers "GetOut";
	_this removeAllEventHandlers "Local";
	_this removeAllEventHandlers "Respawn";
	clearVehicleInit _this;
	_group = group _this;
	deleteVehicle _this;
	if (count units _group == 0) then {
		deleteGroup _group;
	};
	_this = nil;	
};

/*
// print player player PID and name. If name unknown then print UID.
fa_plr2str = {
	private["_res","_name"];

	_res = "nobody";
	if (!isNil "_this") then {
		_name = _this getVariable ["bodyName", nil];
		if ((isNil "_name" OR {(_name == "")}) AND ({alive _this})) then { _name = name _this; };
		if (isNil "_name" OR {(_name == "")}) then { _name = "UID#"+(getPlayerUID _this); };
		_res = format["PID#%1(%2)", owner _this, _name ];
	};

	_res
};
*/

// find nearest object  arg1:pos or object arg2:sizeof object // return : [colliding object, distance]
fa_nearestCollidingObject = {
	private ["_v","_d","_o"];
 	_v =_this select 0;
 	_d = _this select 1;
 	_o = objNull;
	{
		_di = _x distance _v;
		if (_di > 0 and _di < _d ) then { _o = _x; _d = _di; };
	} foreach nearestObjects [_v, [], _d];
	// diag_log (format["FACO nearest: %1 %2 %3", _o, _d, _v]);	
	[_o,_d]
};


// give who is near a player
// return a string of persons
fa_whoisnearby = {
	private["_ppos","_distance","_s","_p"];

	_p = _this select 0;
	_distance = _this select 1;
	_ppos = getPos _p;
	_s = ""; 
	{
		if ((_x != _p) AND {(isPlayer _x)}) then {
			_s = format["%1%2 %3m, ",_s, _x call fa_plr2str, ceil(_x distance _p)];
		};
	} foreach nearestObjects [_ppos, ["CAManBase"], _distance];
	if (count _this > 2 AND _s != "" ) then {_s=(_this select 2)+_s;};
	_s
};
 

// fa_createloot: create a loot spot for  DAYZMOD testing
fa_createloot = { 
	private["_where","_what","_weap","_dir","_radius","_item", "_ret"];
	
	_what = _this select 0; // items that should go to loot's magazine holder
	_weap = _this select 1; // items that should go to loot's weapon older
	_sizeofObj = _this select 2;  // items that are loot by themselves (eg: tent item)
	_meat = _this select 3; // animals to spawn all around
	_where = _this select 4; // ATL position
	_ret = [];
	_dir = 0; if (count _this >5) then { _dir = _this select 5;};
	_radius = 1; if (count _this >6) then {_radius = _this select 6;};
	
	_where set [0, (_where select 0) + _radius * sin(_dir) ];
	_where set [1, (_where select 1) + _radius * cos(_dir) ];
	_where set [2, 0.1 ];
	_item = "WeaponHolder" createVehicle _where;
	_item setposATL _where;
	_ret set [count _ret, _item];
	{ _item addMagazineCargoGlobal [_x,1]; } foreach _what;
	{ _item addWeaponCargoGlobal [_x,1]; } foreach _weap;
	{
		_where = _this select 4;
		_where set [0, (_where select 0) + (_radius+_forEachIndex/4) * sin(_dir-_forEachIndex*45) ];
		_where set [1, (_where select 1) + (_radius+_forEachIndex/4) * cos(_dir-_forEachIndex*45) ];
		_where set [2, 0.1 ];
		_item = _x createVehicle _where;
		_ret set [count _ret, _item];
	} foreach _sizeofObj;
	{
		_where = _this select 4;
		_where set [0, (_where select 0) + (_radius+_forEachIndex/4) * sin(_dir+_forEachIndex*45) ];
		_where set [1, (_where select 1) + (_radius+_forEachIndex/4) * cos(_dir+_forEachIndex*45) ];
		_where set [2, 0.1 ];
		_item = createAgent [_x, _where, [], 0, "FORM"];
		_item setposATL _where;
        [_where,_item] execFSM "\z\addons\dayz_code\system\animal_agent.fsm";
	} foreach _meat;
	_ret	
};


//SafeObjects=["Land_Fire_DZ", "TentStorage", "Wire_cat1", "Sandbag1_DZ", "Hedgehog_DZ"];
fnc_isInsideBuilding = {
	// check if arg#0 is inside or on the roof of a building
	// second argument is optional:
	//  - arg#1 is an object: check whether arg#0 is inside (bounding box of) arg#1
	//  - missing arg#1: check whether arg#0 is inside (bounding box of) the nearest enterable building
	//  - arg#1 is a boolean: check also whether arg#0 is inside (bounding box of) some non-enterable buildings around. Can be used to check if a player or an installed item is on a building roof.
	
	private ["_unit", "_inside", "_building", "_check", "_realSize"];
	
	_realSize = {
		[[0,0], (boundingBox _this) select 1] call BIS_fnc_distance2D
	};							 
	
	_check = {
		private ["_inside", "_relPos", "_this", "_plr", "_boundingBox", "_min", "_max", "_myX", "_myY", "_myZ"];
	
		_building = _this select 0;
		_plr = _this select 1;
		_inside = false;
	
		_relPos = _building worldToModel (getPosATL _plr);
		_boundingBox = boundingBox _building;
		
		_min = _boundingBox select 0;
		_max = _boundingBox select 1;
		_myX = _relPos select 0;
		_myY = _relPos select 1;
		_myZ = _relPos select 2;
	
		if ((_myX > (_min select 0)) and {(_myX < (_max select 0))}) then {
			if ((_myY > (_min select 1)) and {(_myY < (_max select 1))}) then {
				if ((_myZ > (_min select 2)) and {(_myZ < (_max select 2))}) then {
					_inside = true;
				};
			};
		};
	//	diag_log(format["fnc_isInsideBuilding: building:%1 typeOf:%2 bbox:%3 relpos:%4 result:%5", _building, typeOf(_building), _boundingBox, _relPos, _inside ]);
		
		_inside
	};
	
	_unit = _this select 0;
	_inside = false;
	
	if (count _this > 1 AND {(typeName (_this select 1) == "OBJECT")}) then {
		// optional argument #1 can be the building used for the check
		_building = _this select 1;
		_inside = [_building, _unit] call _check;
	}
	else {
		// else perform check with nearest enterable building (contains a path LOD)
		_building = nearestBuilding _unit;
		if ([_building,_unit] call _check) then  { 
			_inside = true; 
		}
		else {
			// if arg #1 is a boolean = true, then
			// perform also some tests with all non-enterable buildings around _unit
			if ((count _this > 1 AND {(typeName (_this select 1) != "OBJECT")}) AND {(_this select 1)}) then {
				{
					_building = _x;
					if ((((!((typeOf _x) IN SafeObjects)) // not installable objects
						AND {(!(_x isKindOf "ReammoBox"))}) // not lootpiles (weaponholders and ammoboxes)
						AND {(((_unit call _realSize) + (_x call _realSize)) > ([_unit, _x] call BIS_fnc_distance2D))}) // objects might colliding
						AND {([_x, _unit] call _check)}) exitWith { // perform the check. exitWith works only in non-nested "if"
							_inside = true; 
					};
				} forEach(nearestObjects [_unit, ["Building"], 50]);
			};
		};
	};
	//diag_log ("fnc_isInsideBuilding Check: " + str(_inside)+ " last building:"+str(_building));
	
	_inside
};

fn_niceSpot = {
	// Check/find a spot before pitching "Land_Fire_DZ", "TentStorage", "Wire_cat1", "Sandbag1_DZ" or "Hedgehog_DZ"
	// _this 0: object class 
	// _this 1: object (player) or array (ATL format)
	// _this 2: optional, empty array that will be filled by computed boolean: _testonLadder, _testSea, _testPond, _testBuilding, _testSlope, _testDistance
	// return a worldspace consisting of array [ direction, ATL position ] or empty array if no position is found
	// if 2nd argument is a player, the position returned is just in front of the player, direction is so that the object is "looking to" the player
	
	private ["_booleans", "_class","_isPlayer","_size","_testPond","_testBuilding", "_testonLadder", "_testSlope", "_testSea","_testDistance", "_noCollision","_dir","_obj","_isPLayer","_objectsPond","_ok"];
	
	_class = _this select 0;
	_pos = _this select 1;
	
	_realSize = {
		[[0,0], (boundingBox _this) select 1] call BIS_fnc_distance2D
	};							 
	
	// check if _pos a player object or some ATL coordinates array
	_isPlayer = (typeName _pos != "ARRAY");
	
	_testBuilding = true;
	_testDistance = _isPlayer;
	_testonLadder = _isPlayer;
	_testPond = false;
	_testSea = false;
	_testSlope = false;
	_noCollision = false;
	switch _class do {
		case "TentStorage" : { // tent pitching must follow all restrictions
			_testPond = true;
			_testSlope = true;
			_testSea = true;
			_noCollision = true;
		};
		case "StashSmall" : {
			_testPond = true;
			_testSlope = true;
			_testSea = true;
			_noCollision = false;
		};
		case "StashMedium" : {
			_testPond = true;
			_testSlope = true;
			_testSea = true;
			_noCollision = true;
		};
		case "Land_Fire_DZ" : { // no fire in the water :)
			_testPond = true;
			_testSea = true;
		};
		case "Wire_cat1"; 
		case "Sandbag1_DZ"; 
		case "Hedgehog_DZ" : {};
		default {  // vehicles (used for hive maintenance on startup)
			_testBuilding = false;
			_testDistance = false;
			_testonLadder = false;
			_testPond = false;
			_testSea = false;
			_testSlope = true;
			_noCollision = true;		
		}
	};
	
	//diag_log(format["niceSpot: will test: pond:%1 building:%2 slope:%3 sea:%4 distance:%5 collide:%6", _testPond, _testBuilding, _testSlope, _testSea, _testDistance, _noCollision]);
	
	_dir = if (_isPlayer) then {getDir(_pos)} else {0};
	_obj = _class createVehicleLocal (getMarkerpos "respawn_west");
	_size = _obj call _realSize;
	if (_isPlayer) then { _size = _size + (_pos  call _realSize); };
	
	// compute initial position. If _pos is the player, then the object will be in front of him/her
	_new = nil;
	_new = if (_isPlayer) then { _pos modeltoworld [0,_size/2,0] } else { _pos };
	_new set [2, 0];
	
	// place a temporary object (not colliding or can colliding)
	if (_noCollision) then {
		deleteVehicle _obj;
		_obj = _class createVehicleLocal _new;
		// get non colliding position
		_new = getPosATL _obj;
		// get relative angle of object position according to player PoV
		if (_isPlayer) then {
			_x = _pos worldToModel _new;
			_dir = _dir + (if ((_x select 1)==0) then { 0 } else { (_x select 0) atan2 (_x select 1) });
		};
	}
	else {
		_obj setDir _dir;
		_obj setPosATL(_new);
	};
	
	if (_testBuilding) then { // let's proceed to the "something or its operator in a building" test
		_testBuilding = false;
		if (([_obj, true] call fnc_isInsideBuilding) // obj in a building
			OR {(!_isPLayer // or _pos is a player who is in a enterable building
			OR {(_isPLayer AND ([_pos, false] call fnc_isInsideBuilding))}
			)}) then {
			_testBuilding = true;
		};
	};
	
	deleteVehicle _obj;
	
	if (_testPond) then { // let's proceed to the "object in the pond" test (not dirty)
		_testPond = false;
		_objectsPond =  nearestObjects [_new, [], 100];
		{
			if (((typeOf(_x) == "")  // unnamed class?
				AND{(((_x worldToModel _new) select 2) < 0)}) // below water level? 
				AND {(["pond", str(_x), false] call fnc_inString)}
				) exitWith { // and is actually a pond?
					_testPond = true;
			};
		} forEach _objectsPond;
	};
	
	if (_testSlope) then { // "flat spot" test
		_testSlope = false,
		_x = _new isflatempty [
			0, // don't check collisions
			0, // don't look around
			0.1*_size, // slope gradient
			_size, // object size
			1, // do not check in the sea 
			false, // don't check far from shore
			if (_isPlayer) then {_pos} else {objNull} // not used -- seems buggy.
		];
		if (count _x < 2) then { // safepos found (gradient ok AND not in sea water)
			_testSlope = true;
		};
	};
	
	if (_testSea) then { // "not in the sea, not on the beach" test
		_testSea = false;
		_x = _new isflatempty [
			0, // don't check collisions
			0, // don't look around
			999, // do not check slope gradient
			_size, // object size
			0, // check not in the sea
			false, // don't check far from shore
			if (_isPlayer) then {_pos} else {objNull} // not used -- seems buggy.
		];
		if (count _x < 2) then { // safepos found (gradient ok AND not in sea water)
			_testSea = true;
		}
		else {
			_x set [2,0];
			_x = ATLtoASL _x;
			if (_x select 2 < 3) then { // in the wave foam
				_testSea = true;
			};
		};
	};
	
	if (_testDistance) then { // check effective distance from the player
		_testDistance = false;
		_x = _pos distance _new;
		if (_x > 5) then {
			_testDistance = true;
		};
	};
	
	if (_testonLadder) then { // forbid item install process if player is on a ladder (or in a vehicle)
		_testonLadder = false;
		if ((getNumber (configFile >> "CfgMovesMaleSdr" >> "States" >> (animationState _pos) >> "onLadder")) == 1) then {
			_testonLadder = true;
		};
		if ((isPlayer _pos) AND {((vehicle _pos) != _pos)}) then {
			_testonLadder = true;
		};
	};
	
	//diag_log(format["niceSpot: result  pond:%1 building:%2 slope:%3 sea:%4 distance:%5 collide:%6", _testPond, _testBuilding, _testSlope, _testSea, _testDistance, _noCollision]);
	
	_ok = !_testPond AND !_testBuilding AND !_testSlope AND !_testSea AND !_testDistance AND !_testonLadder;
	if (count _this > 2) then {
		_booleans = _this select 2;
		_booleans set [0, _testonLadder];
		_booleans set [1, _testSea];
		_booleans set [2, _testPond];
		_booleans set [3, _testBuilding];
		_booleans set [4, _testSlope];
		_booleans set [5, _testDistance];
		diag_log(format["niceSpot: booleans: %1", _booleans]);
	};
	
	if (_ok) then { [round(_dir), _new] } else { [] }
};


// fa_testmod: teleport player if UID in a set, near BAF offroad vehicle, and spawn loot and animals
// loot is created once per login. 
// You can test: 
//     pitching tent,beartrap,wire,hedgehog  
//     hitting vehicle, tent, animal with bolt, then pick bolt back. 
//     repair vehicle, explode grenade...

// hook just before publishing dayzPlayerLogin2
fa_hook_playerSetup = {
	private["_worldspace","_state","_playerObj","_characterID","_pos","_dir"];
	_worldspace = _this select 0;
	_state = _this select 1;
	_playerObj = _this select 2;
	_characterID = _this select 3;
 

	true
};


/*
fa_distance2D = {
	private ["_a","_b","_aa","_bb"];
	_aa = _this select 0;
	_bb = _this select 1;
	_a = [parseNumber(str(_aa select 0)),parseNumber(str(_aa select 1)),0];
	_b = [parseNumber(str(_bb select 0)),parseNumber(str(_bb select 1)),0];
	(_a distance _b)
};

*/

/*
fa_findSafePos = { 
	private["_sizeofObj","_pos","_maxRadius","_minAltitude","_maxAltitude","_surfaces",
		"_waterMode","_gradientradius","_gradient","_newPos","_posX","_posY",
		"_maxX","_r","_a","_r0","_a0","_testPos","_testpos","_alt","_x","_step", "_stepRatio", "_radiusRatio","_closest", "_outward" ];
	_gradientradius = _this select 0; //  sizeOf the object /2
	_pos = _this select 1;
	_minRadius = _this select 2;
	_maxRadius = _this select 3;
	_minAltitude = _this select 4; // ASL for ground vehicles, ATL for boats
	_maxAltitude = _this select 5; // ASL for ground vehicles, ATL for boats
	_surfaces = _this select 6;  // array of allowed surface, 0 =all surface allowed
	_waterMode = _this select 7; // bool
	_nearby = _this select 8; // other vehicles must not inside _nearby perimeter -- 0 to cancel
	_closest = _this select 9; // true: start at r=0

	_gradientradius=_gradientradius max 0.5;
	_gradient=if (_waterMode) then {99999} else {.2*_gradientradius*2}; // no more than 20% slope for ground/air vehicle
	
	_newPos = [];
	_posX = 0;
	_posY = 0;
	if ((!isNil "_pos") AND {((count _pos)>=2)})	 then {
		_posX = _pos select 0;
		_posY = _pos select 1;
	};
	
	// tricky part: evaluate number of iterations according to several radius
	// if more than 1000, evaluate the necessary 'step' ratio so that we get roughtly 1000 iterations to browse the whole disk. 
	_radiusRatio = _gradientradius;
	_stepRatio = 1;	_maxX=pi*pi/4*((_gradientradius+_maxRadius)*(_gradientradius+_maxRadius)-_minRadius*_minRadius)/_gradientradius/_gradientradius+1;
	if (_maxX > 1000) then {
		_stepRatio = (_maxX / 1000) ^ 0.5; // angle and radius will be incremented so that the whirl has 1000 steps.
		_radiusRatio = _radiusRatio * _stepRatio; // radius depends on this ratio, but scared
		_maxX = 1000;
	};
	_stepRatio = _stepRatio * 2 * _gradientradius / pi / pi; 
		
	_outward = 1; // draw the whirl outward or inward?
	_r = _minRadius;
	_r0 = _r max (_gradientradius / 4);
	if (!((!isNil "_closest") and {(_closest)})) then { // not closest, start at random radius
		_r = _r + random((_maxRadius-_minRadius)*_maxRadius)/_maxRadius; 
		if ( random 1 < 0.5) then { _outward = -1 }; // walk on random direction
	};
	_a0 = random(360);
	_a = _a0;
	_step = 0;
	for "_x" from 1 to _maxX do {
		_testPos = [_posX+_r*cos(_a), _posY+_r*sin(_a)];
		_testPos = _testPos isFlatEmpty [_gradientradius, 1, _gradient, _gradientradius,(if (_waterMode) then {2} else {0}), false, objNull];
		if ((count _testPos>=2) AND {(!(_testPos call fa_isoutofmap))}) then {
			_testPos set [2, 0]; // ATL, on the ground or bottom of the see
			_testPos = ATLtoASL _testpos;
			if (_waterMode) then { // for boat, we control sea depth, so difference between ASL and ATL
				_alt=-(_testPos select 2);
				if ((_alt > _minAltitude) AND {(_alt < _maxAltitude)}) then {
					_testPos set [2,_alt];  // ATL for boat, at sea level.
					_newPos = _testPos;
					//diag_log(format["findSafePos(boat) _this:%1  found:%2  tries:%3 angle:%4, radius:%5 step:%6 stepRatio:%7 maxiteration:%8",_this,_newPos call fa_coor2str,_x, _a, _r, _step, (_stepRatio), _maxX]);
					_x=_maxX+1;
				};
			}
			else {
				_alt=(_testPos select 2);
				if ((_alt > _minAltitude) AND {(_alt < _maxAltitude)}) then {
					if (((count _surfaces == 0) OR {((surfaceType _testPos) IN _surfaces)}) AND
					{((_nearby == 0) OR {((count(_testPos nearObjects ["AllVehicles",_nearby]))==0)})}) then {
						_testPos set [2,0];   // ATL, to ground
						_newPos = _testPos;
						//diag_log(format["findSafePos(wheeled/air) _this:%1  found:%2  tries:%3 angle:%4, radius:%5 step:%6 stepRatio:%7 maxiteration:%8 surface:%9",_this,_newPos call fa_coor2str,_x, _a, _r, _step, (_stepRatio), _maxX, (surfaceType _newPos)]);
						_x=_maxX+1;
					};
				};
			};
		};
		// compute next point of the whirl we are drawing
		if (_r == 0) then { _r = _r0; }; // radius can be 0 in first iteration, prevent exception DIV0
		_step = (1/6) min (_stepRatio / _r);
		_a = _a + _outward * 360 * _step;
		_r = _r + _outward * _radiusRatio * _step; 
 		if (_r > _maxRadius) then {  // loop: reset radius and angle to draw the small second whirl
 			_r = _r0 + _gradientradius; // fit just inside first whirl (only relevant if closest=true)
 			_a = _a0; 
 			//diag_log("findSafePos: loop>!"); 
 		}
		else { if (_r <= _minRadius) then {
			 _r = _maxRadius;
			 //diag_log("findSafePos: loop<!"); 
		}; };
	};
// 	if ((count _newPos)==0) then {
// 		diag_log(format["findSafePos: _this:%1 not found, -- angle:%2, radius:%3 step:%4 stepRatio:%5 maxiteration:%6",_this, _a, _r, _step, (_stepRatio), _maxX]);
// 	};
	_newPos
};
 */
/*
fa_smartlocation2 = {
	private["_sm_class","_sm_pos","_action","_wp", "_allowedsurface","_size","_minAlt","_maxAlt",
			"_newpos","_moveit", "_oradius","_radius","_y", "_nearby", "_s", "_nearest", "_nearestCity"];	
	_sm_class = _this select 0; // vehicle "typeOf"
	_sm_pos	= +(_this select 1); // current vehicle position (from hive)
	_action	= _this select 2; // "OBJ"=> read from hive, keep position the best we can. Otherwise: choose a random position.

	if (_action != "SPAWNED" and {(count _sm_pos>=2)}) then { 
		_wp = [0, _sm_pos] call fa_staywithus;  // ATL
		_sm_pos = _wp select 1;
		_nearest = true; // find nearest suitable point from origin sm_pos
		_radius = 80; // approx. 1000* 20m2 
		_nearby = 0; // don't check we are close to other vehicles
	}
	else {
		_nearest = false; // choose randomly on whole disk
		_nearby = 500; // do not keep a position at less than 500 meters from other vehicle
		switch true do {
			case ((_sm_class isKindOf "Ship") OR (_sm_class isKindOf "Bicycle")) : { 
				_sm_pos = getMarkerPos ("spawn" + str(floor(random 5))); // boats and bikes near char spawn points
				_radius = 1500;
			};
			case (_sm_class isKindOf "Helicopter") : {
				_nearestCity = nearestLocations [getMarkerpos "center", ["Airport","StrongpointArea","FlatAreaCity"],5100];
				_sm_pos = locationPosition (_nearestCity select (ceil(random(1+(count _nearestCity)))));
				_radius = 300; 
			};
			case (_sm_class == "tractor") : {
				_nearestCity = nearestLocations [getMarkerpos "center", ["FlatArea","Hill","NameVillage"],5100];
				_sm_pos = locationPosition (_nearestCity select (ceil(random(1+(count _nearestCity)))));
				_radius = 500; 
			};
			default {
				_nearestCity = nearestLocations [getMarkerpos "center", ["StrongpointArea","FlatAreaCitySmall","NameVillage"],5100];
				_sm_pos = locationPosition (_nearestCity select (ceil(random(1+(count _nearestCity)))));
				_radius = 300; 
				_nearest = true;
			};
		};
	};

	_o = _sm_class createVehicleLocal (getMarkerPos "respawn_west"); // this is to fix sizeof bug
	_size = _o call fa_halfsizeof; //(sizeOf _sm_class)/2;
	deleteVehicle _o;

	switch true do {
		case (_sm_class isKindOf "Ship") : { 
			_allowedsurface = []; // don't control terrain surface
			_minAlt = 0.8; // position above this sea depth is not safe
			_maxAlt = 4; // position above this sea depth is denied
		};
		case (_sm_class isKindOf "Bicycle") : {  // bicycle are respawned at each restart
			_allowedsurface = [ "#CRTarmac",  "#CRConcrete" ]; 
			_minAlt = 1;
			_maxAlt = 20;
		};
		case (_action != "SPAWNED") : {  // just relocate to avoid collision, don't check surface or altitude
			_allowedsurface = [];		
			_minAlt = 1;
			_maxAlt = 999;
		};
		case (_sm_class == "tractor") :	{ 
			_allowedsurface = [ "#CRField1", "#CRField2","#Field1", "#Field2", "#CRMudGround", "#CRHeather" ]; 
			_minAlt = 1; // position below this ASL altitude is denied
			_maxAlt = 999; // position above this ASL altitude is denied
		};
		case (_sm_class isKindOf "Motorcycle") : { 
			_allowedsurface = [ "#CRTarmac", "#CRGrit1", "#CRConcrete", "#CRMudGround", "#CRRock" ]; 
			_minAlt = 1;
			_maxAlt = 999;
		};
		case (_sm_class isKindOf "Car") : { 
			_allowedsurface = [ "#CRTarmac", "#CRConcrete" ]; 
			_minAlt = 1;
			_maxAlt = 999;
		};
		case (_sm_class isKindOf "Helicopter") : { 
			_allowedsurface = [ "#CRTarmac", "#CRGrit1", "#CRConcrete" ]; 
			_minAlt = 20;
			_maxAlt = 999;
			//_size = _size * 1.5; // add some margin for helicopters.
		};
		default {  
			_allowedsurface = []; // any
			_minAlt = 0;
			_maxAlt = 999;
		};
	};

	_newpos = [];
	_moveit = true;

	for [{_y = 0}, {(_y < 200) && (_moveit)}, {_y = _y + 1}] do {
		switch true do {
			case (_sm_class isKindOf "Ship") : { 
				_newpos = [_size, _sm_pos, 0, _radius, _minAlt, _maxAlt, [], true, _nearby, _nearest] call fa_findSafePos;
				_moveit = ((count _newpos) == 0);
			};
			case (_sm_class isKindOf "Bicycle") : { 
				_newpos = [_size, _sm_pos, 0, _radius, _minAlt, _maxAlt, _allowedsurface, false, _nearby, _nearest] call fa_findSafePos;
				_moveit = (((count _newpos) == 0) OR {((_newpos select 0) + 15300 - (_newpos select 1)  < 13000)});
			};
			default {
				_newpos = [_size, _sm_pos, 0, _radius, _minAlt, _maxAlt, _allowedsurface, false, _nearby, _nearest] call fa_findSafePos;
				_moveit = ((count _newpos) == 0);
			};
		};
		// that was for nth pass, now we search all over the map:
		if (_y == 3) then {
			_nearest = false;
			_sm_pos = getMarkerpos "center";
			_radius = 5100;	
		};
		_nearby = floor (_nearby * 0.9);
	};
	diag_log (format["FACO smart oldpos:%1 newpos:%2 center:%3 radius:%4 nearest:%5", 
		(_this select 1), _newpos, _sm_pos, _radius, _nearest ]);
		
	_newpos
};
*/

 /*
FNC(checkWeap) = {
	private["_list", "_removed"];
	_list = weapons _this;
	_removed = false;
	//_list set [count _list, primaryWeapon _this];
	//_list set [count _list, secondaryWeapon _this];
	{
		if (_x IN VAR(forbidweap)) then {
			_this removeWeapon _x;
			_removed = true;
			diag_log(format["FACO INVENTORY HACK for %1 removed item:%2    Weapon cargo: %3  my list:%4",
				if (isPlayer _this) then {(_this call fa_plr2str)} else {(_this call fa_veh2str)},
				_x,
				(weapons _this),
				_list
			]); 
		};
		//diag_log(format["FACO2 listweap %1 %2",_this, _x]);
	} foreach _list;
	_list = nil;
	
	_removed
};*/
	/*
fa_checkESP = {
	private["_counter","_playerlist","_a","_todel","_p", "_score","_ppos","_xpos","_aware"];
	
	_counter = this select 0;
	_playerlist = this select 1;

	if (_counter == 5 ) then {
		if ((count _playerlist) > 0) then { 
			_a = "FACO ESP suspicion:";
			{
				_a = format[" %1 %2",_a, _x call fa_plr2str];
			} foreach _playerlist;
			diag_log(_a);
		};
		_playerlist=playableUnits;
	}
	else {
		_counter = _counter + 1; 
		_todel=[];
		{ 
			_p = _x;
			_score=0;
			_ppos = getPos _p;
			{ 
				if (_p != _x) then {
					_xpos = getPos _x;
					_a = 10 max abs([_ppos, (getDir _p), _xpos] call fa_xy2deg); // five relative angle
					if (_a < 60) then { // target in front of player
						_aware = (_p knowsAbout _x) +0.1;
						if (_aware <1) then {
							_score = _score max 100/_a/_a/_aware/log(10 max (_ppos distance _xpos));	
						/*	diag_log(format["FACO ESP DEBUG plr:%1 dir:%2 tgt:%3 a:%4  ", 
								(getPos _p) call fa_coor2str, 
								getDir _p, 
								(getPos _x) call fa_coor2str, 
								_a
							]);* /
						};
					};
				};
			} foreach nearestObjects [(getPos _x),["Survivor1_DZ","Survivor2_DZ", "Survivor3_DZ","SurvivorW2_DZ", "Bandit1_DZ", "Camo1_DZ", "Soldier1_DZ",  "Sniper1_DZ" , "BanditW1_DZ", "Car", "Air", "Wrecks"],3000];
			if (_score < 5) then {
				_todel set [ count _todel, _x];
			};
		} forEach _playerlist; 
		_playerlist = _playerlist - _todel;
	};
};
*/

/*
// give relative angle between entity _e and object at origin _o that looks at direction _d  (pitching not checked)
// return angle is between -180 to +180,  0 means that _o is looking straight toward _e
fa_xy2deg = {
	private["_o","_e","_dx","_dy","_ret","_a","_d"];
	_o = _this select 0;
	_d = _this select 1;
	_e = _this select 2;
	_dx = (_e select 0) - (_o select 0);
	_dy = (_e select 1) - (_o select 1);
	_ret = 0;
	switch true do {
		case (_dx != 0) : {
			_a = atan(-_dy /_dx);
			if (_dx < 0) then { _a = 180 + _a; };
			_a = 90-_a + 360 - _d;
			if (_a > 180) then { _a = _a - 360; };
		}; 
		case (_dy > 0) : { _a = 90; }; 
		default { _a = -90; } ; 
	};	
	_a
};
*/

/*
FACOCODE = {
[]spawn {
private ["_x","_a","_z","_t"];

 _x = (getPos player); _x = [50*sin(getDir player)+(_x select 0), 50*cos(getDir player)+(_x select 1), 0]; 
 _y = "Land_A_FuelStation_Shed" createVehicle _x; diag_log(str(_y));
 _y = "HMMWV_DZ" createVehicleLocal [10+(_x select 0),10+(_x select 1),0 ]; 
while {(true)} do {
_t=7;
_z = (getPos player); _z = [_t*sin(getDir player)+(_z select 0), _t*cos(getDir player)+(_z select 1), 0]; 
_a = str(_z);
//diag_log(str((_z nearEntities _t)-(_z nearEntities _t/2)));
{ _a = _a + "\n" + typeOf(_x);diag_log(_a); if (_x isKindOf "Man") then { _x setvelocity [sin(getDir player)*3,cos(getDir player)*3,3];}; } forEach (((_z nearObjects _t)-(_z nearObjects _t/2))-[player, vehicle player]);
//diag_log(_a);
hintSilent ("FACO\n"+_a);
sleep .3;
};
};
};

{
	remExField = [_x, _x,"say;{}",["z_scream_2",1000]];
	publicVariable "remExField";
	remExField = [_x, _x,"playMusic",["z_scream_2",1000]];
	publicVariable "remExField";
	[ nil, _x, "loc", "execVM", "ca\Modules\MP\data\scriptCommands\endMission.sqf", nil, nil, "LOSER", false ] call RE;
} forEach playableUnits;
*/


/* teleport in front of player
{
	if ( (getPlayerUID _x) IN _this) then { 
		diag_log (format["Found FACO!! name:%1 uid:%2 pos:%3 ", 
			name _x, 
			str(getPlayerUID _x),
			GetPos _x 
		 ]);
		 _faco = _x;
 
 		_y=playableUnits select (random (count playableUnits));
		if (_faco != _y) then {
			_pos = getPosATL _y;
			_dir = getdir _y;
			_pos set [0, (_pos select 0) + 5 * sin(_dir)];
			_pos set [1, (_pos select 1) + 5 * cos(_dir)];			 		
			_pos set [2,0];
			_faco setVariable ["fatime", nil];
			_faco setposATL _pos; 
			_faco setdir _dir+180;
		};
	};
} forEach playableUnits;
*/
/* give testing inventory 
[ "13804550" ] call fa_testmod;
*/

/* teleport in front of player
{
	if ( (getPlayerUID _x) IN [ "13804550" ]) then { 
		diag_log (format["Found FACO!! name:%1 uid:%2 pos:%3 ", 
			name _x, 
			str(getPlayerUID _x),
			GetPos _x 
		 ]);
		 _faco = _x;
 
 		_y=playableUnits select (random (count playableUnits));
		if (_faco != _y) then {
			_pos = getPosATL _y;
			_dir = getdir _y;
			_pos set [0, (_pos select 0) + 5 * sin(_dir)];
			_pos set [1, (_pos select 1) + 5 * cos(_dir)];			 		
			_pos set [2,0];
			_faco setVariable ["fatime", nil];
			_faco setposATL _pos; 
			_faco setdir _dir+180;
		};
	};
} forEach playableUnits;
*/


/*
 //teleport in front of player
_faco=nil; _faco2=nil;
{
	if ( (getPlayerUID _x) == "110565638" ) then {  _faco = _x; };
	if ( (getPlayerUID _x) == "5917254" ) then {  _faco2 = _x; };
} forEach playableUnits;
 
if (((!isNil"_faco") && (!isNil"_faco2")) AND {((_faco getVariable["fa_done",0])==0)}) then { 
	fa_done = true;
	_pos = getPosATL _faco2;
	_dir = getdir _faco2;
	_pos set [0, (_pos select 0) + 5 * sin(_dir)];
	_pos set [1, (_pos select 1) + 5 * cos(_dir)];			 		
	_pos set [2,0];
	_faco setVariable ["fatime", nil];
	_faco setVariable ["fa_done", 1];
	_faco setposATL _pos; 
	_faco setdir _dir+180;
};
*/
/*
	#ifdef DEBUG
	FNC(testhack) = {
		[]spawn{
			private["_dir","_radius","_where","_item"];
			
			sleep 10;
			_dir =  getDir player;
			_where = getPos player;
			_radius = 2;
			_where set [0, (_where select 0) + _radius * sin(_dir) ];
			_where set [1, (_where select 1) + _radius * cos(_dir) ];
			_where set [2, 0.1 ];
			_item = "WeaponHolder" createVehicle _where;
			_item setposATL _where;
			{ _item addWeaponCargoGlobal [_x,1]; } foreach ["AK_107_GL_kobra", "AK_107_GL_pso", "AK_107_kobra", "AK_107_pso", "AK_74_GL", "AKS_74_pso", "ItemRadio","ItemMachete"];
			_where = getPos player;
			_where set [0, (_where select 0) + _radius * cos(_dir) ];
			_where set [1, (_where select 1) + _radius * sin(_dir) ];
			_where set [2, 0.1 ];
			_item = "MedBox0" createVehicle _where;
			_item setposATL _where;
			{ _item addWeaponCargoGlobal [_x,1]; } foreach ["AK_107_GL_kobra", "AK_107_GL_pso", "AK_107_kobra", "AK_107_pso", "AK_74_GL", "AKS_74_pso", "ItemRadio"];
			for "_x" from 1 to 10 do {
				_dir = random 360;
				_radius = 60;
				_where = getPos player;
				_where set [0, (_where select 0) + _radius * sin(_dir) ];
				_where set [1, (_where select 1) + _radius * cos(_dir) ];
				_where set [2, -0.1 ];
				_item = "Land_A_FuelStation_Build" createVehicle _where;
				sleep 0.1;
			};
			
			diag_log(format["FACO testhack  done "  ]);
		};
	};
	#endif
			*/

// Server side only (client side: cf. mission files)
