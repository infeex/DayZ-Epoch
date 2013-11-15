/*
        Created exclusively for ArmA2:OA - DayZMod.
        Please request permission to use/alter/distribute from the author (facoptere@gmail.com)
*/

private ["_looted","_zombied","_dis", "_i", "_type", "_config", "_canSpawn", "_islocal", "_age", "_minBuildingDis", "_building", "_nearby", "_minareadis", "_vehicle" ];

_vehicle = vehicle player;
_speed = (velocity _vehicle) distance [0,0,0];
if (_speed > 12) exitWith {};
if ((_vehicle != player) AND {((count crew _vehicle > 1) AND {(driver _vehicle != player)})}) exitWith {};

diag_log (format["%1 Local.Agents: %2/%3, NearBy.Agents: %8/%9, Global.Agents: %6/%7, W.holders: %10/%11, (radius:%4m %5fps).","SpawnCheck",
	dayz_spawnZombies, dayz_maxLocalZombies, 200, round diag_fpsmin,dayz_currentGlobalZombies, 
	dayz_maxGlobalZeds, dayz_CurrentNearByZombies, dayz_maxNearByZombies, dayz_currentWeaponHolders,dayz_maxMaxWeaponHolders
	]);

_i = 0;	
_minareadis = 30;
{
	_building = _x;
	_type = typeOf _building;
	_dis = _building distance _vehicle;
	_minBuildingDis = _minareadis + (sizeof _type) / 2;
	if (_dis > _minBuildingDis) then {
		_config = configFile >> "CfgBuildingLoot" >> _type;
		_canSpawn = isClass (_config);
		if (_canSpawn) then {
			_islocal = _building getVariable ["", false];
			_nearby = -1;
			if ((dayz_currentWeaponHolders < dayz_maxMaxWeaponHolders) AND {((count (getArray (_config >> "lootPos"))) > 0)}) then {
				_looted = (_building getVariable ["looted",daytime]);
				_age = (daytime - _looted) * 3600;
				if (_age < -60) then { _age = _age + 3600 * 24; }; // midnight loop, assuming 60sec daytime drift
				if ((_age <= 0) or {(_age > 1800)}) then {
					_nearby = { _building distance vehicle _x < _minBuildingDis } count playableUnits;
					if (_nearby == 0) then {
						_building setVariable ["looted",daytime,!_islocal];					
						_building call building_spawnLoot;
					};
				};
			};
			if ((dayz_spawnZombies < dayz_maxLocalZombies) AND {(((dayz_currentGlobalZombies < dayz_maxGlobalZeds) AND {( _i < 5)}) /*AND {((dayz_CurrentNearByZombies < dayz_maxNearByZombies) AND {(getNumber (_config >> "maxRoaming") > 0)})}*/)}) then {
				_zombied = (_building getVariable ["zombieSpawn",daytime]);
				_age = (daytime - _zombied) * 3600;
				if (_age < -60) then { _age = _age + 3600*24; }; // midnight loop, assuming 60sec daytime drift
				if (((_age <= 0) or {(_age > 300)}) AND {(0 == count ((getPosATL _building ) nearObjects ["zZombie_Base", (sizeof typeof _building) / 2]))})then {
					if (_nearby == -1) then { // compute _nearby only if not already computed above
						_nearby = { _building distance vehicle _x < _minBuildingDis } count playableUnits;
					};
					if (_nearby == 0) then {
						_building setVariable ["zombieSpawn",daytime,!_islocal];
						_i = _i + ([_building] call building_spawnZombies2);
					};
				};
			};
		};
	};
} forEach nearestObjects [ getPosATL _vehicle, ["building", "SpawnableWreck"], _minareadis+70];
// ["SpawnableWreck","Land_HouseV_1I4", "Land_kulna", "Land_Ind_Workshop01_01", "Land_Ind_Garage01", "Land_Ind_Workshop01_02", "Land_Ind_Workshop01_04", "Land_Ind_Workshop01_L", "Land_Hangar_2", "Land_hut06", "Land_stodola_old_open", "Land_A_FuelStation_Build", "Land_A_GeneralStore_01a", "Land_A_GeneralStore_01", "Land_Farm_Cowshed_a", "Land_stodola_open", "Land_Barn_W_01", "Land_Hlidac_budka", "Land_HouseV2_02_Interier", "Land_a_stationhouse", "Land_Mil_ControlTower", "Land_SS_hangar", "Land_A_Pub_01", "Land_HouseB_Tenement", "Land_A_Hospital", "Land_Panelak", "Land_Panelak2", "Land_Shed_Ind02", "Land_Shed_wooden", "Land_Misc_PowerStation", "Land_HouseBlock_A1_1", "Land_Shed_W01", "Land_HouseV_1I1", "Land_Tovarna2", "Land_rail_station_big", "Land_Ind_Vysypka", "Land_A_MunicipalOffice", "Land_A_Office01", "Land_A_Office02", "Land_A_BuildingWIP", "Land_Church_01", "Land_Church_03", "Land_Church_02", "Land_Church_02a", "Land_Church_05R", "Land_Mil_Barracks_i", "Land_A_TVTower_Base", "Land_Mil_House", "Land_Misc_Cargo1Ao", "Land_Misc_Cargo1Bo", "Land_Nav_Boathouse", "Land_ruin_01", "Land_wagon_box", "Land_HouseV2_04_interier", "Land_HouseV2_01A", "Land_KBud", "Land_A_Castle_Bergfrit", "Land_A_Castle_Stairs_A", "Land_A_Castle_Gate", "Land_Mil_Barracks", "Land_Barn_W_02", "Land_sara_domek_zluty", "Land_HouseV_3I4", "Land_Shed_W4", "Land_HouseV_3I1", "Land_HouseV_1L2", "Land_HouseV_1T", "Land_telek1", "Land_Rail_House_01", "Land_HouseV_2I", "Land_Misc_deerstand", "Camp", "CampEast", "CampEast_EP1", "MASH", "Mi8Wreck_DZ", "UH1Wreck_DZ", "UH60Wreck_DZ", "USMC_WarfareBFieldhHospital", "Land_HouseV_1I3", "Land_HouseV_1L1", "Land_HouseV_1I2", "Land_HouseV_2L", "Land_houseV_2T2", "Land_HouseBlock_A1", "Land_HouseBlock_A2_1", "Land_HouseBlock_A3", "Land_HouseBlock_B5", "Land_HouseBlock_B6", "Land_HouseBlock_C1", "Land_HouseV2_01B", "Land_HouseV2_03", "Land_BoatSmall_2b", "Land_Farm_Cowshed_c", "Land_Farm_Cowshed_b", "Land_Barn_Metal", "Land_Ind_Expedice_1", "Land_A_CraneCon", "Land_Ind_Mlyn_03", "Land_Mil_Guardhouse", "Land_komin", "Land_Ind_Pec_01", "Land_Ind_SiloVelke_01", "Land_Misc_Garb_Heap_EP1", "Land_Shed_M02", "Fort_Barricade", "Land_Misc_Rubble_EP1", "Land_A_Crane_02b", "datsun01Wreck", "LADAWreck", "SKODAWreck", "UralWreck", "Land_Misc_GContainer_Big", "Land_Toilet", "Land_trafostanica_velka", "Misc_TyreHeap", "Land_GuardShed", "Land_tent_east", "RU_WarfareBFieldhHospital", "RU_WarfareBBarracks", "Land_ruin_corner_1", "Land_ruin_walldoor", "Land_A_Castle_Wall2_End_2", "Land_A_Castle_WallS_End", "Land_A_Castle_Wall2_30", "Land_A_Castle_WallS_10", "Land_Vysilac_FM", "Land_NAV_Lighthouse", "Land_sara_hasic_zbroj", "Land_A_Castle_Donjon", "Land_Dam_Conc_20", "Land_Dam_ConcP_20", "Land_Ind_Quarry", "Land_Misc_Scaffolding"]

if (dayz_spawnZombies < 10) then {
	_tmp = (random 180) - 90;
	_dis = 200;
	_point = player modelToWorld[sin(_tmp) * _dis, cos(_tmp) * _dis, 0];
	if ({ _point distance getPosATL vehicle _x < _dis - 25 } count playableUnits == 0) then {
		{
				_tmp = str(_x);
				if ((typeOf _x == "") AND {(
						(((["t_picea1s", _tmp, false] call fnc_inString) OR
						{(["t_picea2s", _tmp, false] call fnc_inString)})) OR
						{((["t_betula2w", _tmp, false] call fnc_inString) OR
						{(["b_craet2", _tmp, false] call fnc_inString)})})
				}) exitWith {
						[_x] call building_spawnZombies2;
				};
		} forEach (nearestObjects [_point, [], 25]);
	};
};
