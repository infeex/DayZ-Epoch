/*
        Created exclusively for ArmA2:OA - Epoch DayZ Mod.
        Please request permission to use/alter/distribute from the author (facoptere@gmail.com)
*/

faw_param_routine= [] spawn { sleep 3600; };

if (!isNil "faw_snow_routine") then { 
	terminate faw_snow_routine; 
};
faw_snow_routine = [] spawn {
	private ["_fogs","_smoke","_ran","_obj","_velocity","_color","_alpha","_ps","_delay","_distance","_fov","_density","_velo","_dpos","_skypos", "_outdoor","_r","_a", "_pos", "_x"];
	/*
	"filmGrain" ppEffectEnable true;
	"filmGrain" ppEffectAdjust [0.02, 1, 1, 0.1, 1, false];
	"filmGrain" ppEffectCommit 5;
	*/

	waitUntil {!isNil "faw_directive"};
	_fogs = [];
	_pos = [0,0,0];
	_dpos = +(_pos);
	_skypos = +(_pos);
	for "_x" from 0 to 10 do {
		_smoke = "#particlesource" createVehicleLocal _pos;
		_smoke setParticleParams [
		  ["\Ca\Data\ParticleEffects\Universal\universal.p3d" , 16, 12, 13, 0], "", "Billboard", 3600, 5,
		  [0, 0, -6], [0, 0, 0], 1, 1.275, 1, 0,
		  [7,6], [[1, 1, 1, 0], [1, 1, 1, 0.04], [1, 1, 1, 0]], [1000], 1, 0, "", "", player
		];
		_smoke setParticleRandom [3, [55, 55, 0.2], [0, 0, -0.1], 2, 0.45, [0, 0, 0, 0.1], 0, 0];
		_smoke setParticleCircle [0.001, [0, 0, -0.12]];
		_smoke setDropInterval 0.01;
		_fogs set [ _x, _smoke ];
	}; 

	_distance = 25;
	_fov = 180;
//	diag_log format [ "%1 FAW snow routine unlocked", __FILE__ ];
	_olddensity = 0;
	_density = 0;
	_velo = 0;
	_outdoor = 0.5;
	while {true} do {
		_density = faw_directive select 5;
		if (_density == 0 AND {(_density == _olddensity)}) then {
//			diag_log "FAW no snow ...idle";
			sleep 5;
		}
		else {
			if (_density >= 0.8) then {
				setviewdistance 900;
				enableEnvironment false;
			}
			else {
				setviewdistance 1600;
				enableEnvironment true;
			};
			if (_outdoor > 0.5) then {
				_dpos = ATLtoASL positionCameraToWorld [0, 0.3, 1 + _outdoor * (random _distance)];
				_skypos = [(_dpos select 0)+ _outdoor * random 30, (_dpos select 1)+ _outdoor * random 30, (_dpos select 2)+30];
			}
			else {
				_dpos = eyePos player;
				_skypos = [_dpos select 0, _dpos select 1, (_dpos select 2) + 30];
			};
			if (lineIntersects [_dpos, _skypos]) then {
				_outdoor = 0;
			}
			else {
				_outdoor = 1;
			};
			if (_outdoor < 0.2) then { 
//				diag_log "FAW no snow indoor";
				sleep 1; 
			}
			else {
				for "_y" from 1 to 50 do {
					_velo = (5 * _velo + (speed player) / 3.6) / 6; // arma2 "speed" bug workaround
					_r0 = _distance + _velo;
					for "_x" from _density * _r0 * 2 * _outdoor to 1 step -1 do {
						_r =  random (_r0 + _x / 100) ; // arma2 "random" bug workaround
						_a = -(_fov/2) + random _fov; 
						_p = (0.7 + random 0.3) / (1 + 10 * rain); // flocks are melt (smaller, heavier) if it's rainy
						_dpos = positionCameraToWorld [
							_r * sin(_a) / 2,
							0.5 + _r *0.7, // default fov is 0.7 in ArmA
							_r * cos(_a) + _velo * 2 - _distance / 3 ];
						_dpos set [ 0, (_dpos select 0)-_r*(wind select 0)/2 ];
						_dpos set [ 1, (_dpos select 1)-_r*(wind select 2)/2 ];
						drop ["\ca\data\cl_water", "", "Billboard", 3600,  2+_r/2, _dpos , [0,0,0], 0, 0.0000001, 0, _p, [0.07*_p], [[1,1,1,0], [1,1,1,1], [1,1,1,1], [1,1,1,1]], [0,0], 0.2*_p, 1.2*_p, "", "", ""];
					};
//					diag_log format [ "FAW snow %1 , %2->%3, velo:%4, last pos:%5 outdoor:%6",_density*_r0/3.3 , _density, faw_target select 5, _velo, _dpos, _outdoor];
					sleep 0.1;
				};
			};
			if (_outdoor > 0.2 AND _density > 0.3) then {
				_dpos = [ _dpos select 0, _dpos select 1, 15 * (_density - 1) + 2 ];
			}
			else {
				_dpos = [0,0,0];
			};
			for "_x" from 0 to 2 do {
				(_fogs select _x) setPosATL (_dpos); 
				(_fogs select _x) setDir (15 + (direction (_fogs select _x)));
			}; 
			_olddensity = _density;
		};
	};
};

faw_init = nil;
faw_target = nil;
faw_directive = nil;
faw_temperature = 0;
drn_var_DynamicWeather_ServerInitialized = nil;
"drn_DynamicWeather_DebugTextEventArgs" addPublicVariableEventHandler {};
"drn_DynamicWeatherEventArgs" addPublicVariableEventHandler {};
"PVDZE_plr_SetWeather" addPublicVariableEventHandler {};
drn_var_DynamicWeather_Rain = 0;
faw_update_EH = {
		// faw_target,faw_directive,faw_init arrays:
		// time	clouds	rain	mist	wind	snow	windir 
		// 0	1		2		3		4		5		6	 
		private ["_x", "_args"];

		_args = _this select 1;
		_x = _args select 0;
		_x set [ 0, (_x select 0) + diag_tickTime ];
		faw_target = (+_x);
		_x = _args select 1;
		_x set [ 0, (_x select 0) + diag_tickTime ];
		faw_init = (+_x);
		faw_temperature = _args select 2;
};
"faw_PV" addPublicVariableEventHandler faw_update_EH;
