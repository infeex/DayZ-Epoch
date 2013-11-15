/*
        Created exclusively for ArmA2:OA - Epoch DayZ Mod.
        Please request permission to use/alter/distribute from the author (facoptere@gmail.com)
*/

#include "faco_weather2.hpp"

faw_playerSetup = {
	private [ "_tmp", "_x", "_relative_target", "_relative_init" ];
	_relative_target = +(faw_target);
	_relative_target set [ 0, (_relative_target select 0) - diag_tickTime ];
	_relative_init = +(faw_init);
	_relative_init set [ 0, (_relative_init select 0) - diag_tickTime ];
	faw_PV = [ _relative_target, _relative_init, faw_temperature ];
	if (_this < 0) then {
		publicVariable "faw_PV";
#ifdef WEATHER_VERBOSE
		diag_log format [ "FAW broadcasting weather params:%1", faw_PV];
#endif
	}
	else {
		_this publicVariableClient "faw_PV";
#ifdef WEATHER_VERBOSE
		diag_log format [ "FAW setting weather params:%1 to player PID#%2", faw_PV, _this];
#endif
	};
};

"drn_AskServerDynamicWeatherEventArgs" addPublicVariableEventHandler {
	private ["_plr"];
	_plr = _this select 1;
	if ((!isNil "_plr") AND {((typeName _plr == "OBJECT") AND {(!isNull _plr)})}) then {
		(owner _plr) call faw_playerSetup;
	};
};

if (!isNil "faw_main") then { 
	terminate faw_main;
};
faw_main = [] spawn {
	private ["_tick","_onedayticks","_moisture","_groundtemperature",
	"_skyid","_skyproba","_skyscenar","_skyscenarstep","_skyscenarrow",
	"_scenar_sun","_bias_sun","_scenar_clouds","_bias_clouds","_scenar_rain","_bias_rain",
	"_scenar_storm","_bias_storm","_scenar_mist","_bias_mist","_scenar_snow","_bias_snow",
	"_probalink","_myrand","_setWeather"];

	#ifdef WEATHER_TICK	
	_tick = WEATHER_TICK; // in seconds
	#else
	_tick = 60; // in seconds
	#endif
	_onedayticks = 1440 * 60 / _tick;
 
	_scenar_sun = [
	//step		time,rnd	overcast,rnd	rain,rnd	mist,rnd	wind,rnd	snow,rnd
	/*1*/	[	10,4,		0.2,0.2,		0,0,		-1,-1,		-1,-1,		0,0 		],
	/*2*/	[	30,15,		0.3,0.3,		0,0,		0.12,0.05,	0.2,0.1,	0,0			]
	];
	_bias_sun = {1};

	_scenar_clouds = [
	//step		time,rnd	overcast,rnd	rain,rnd	mist,rnd	wind,rnd	snow,rnd
	/*1*/	[	6,2,		0.7,0.2,		0,0,		-1,-1,		-1,-1,		-1,-1		],
	/*2*/	[	6,2,		0.87,0.07,		0,0,		0.3,0.1,	0.5,0.3,	0,0			],
	/*3*/	[	30,15,		0.87,0.07,		0,0,		0.3,0.1,	0.5,0.3,	0,0			]
	];
	_bias_clouds = {(1/3 + 2 * sunOrMoon / 3)};

	_scenar_rain = [
	//step		time,rnd	overcast,rnd	rain,rnd	mist,rnd	wind,rnd	snow,rnd
	/*1*/	[	6,4,		0.87,0.07,		-1,-1,		0.3,0.1,	-1,-1,		-1,-1		],
	/*2*/	[	10,4,		0.87,0.07,		0.2,0.1,	-1,-1,		0.5,0.2,	0,0			],
	/*3*/	[	13,4,		0.9,0.05,		0.5,0.2,	0.5,0.1,	0.2,0.1,	0,0			],
	/*4*/	[	13,4,		0.87,0.07,		0.1,0.1,	0.3,0.1,	-1,-1,		0,0			]
	];
	_bias_rain = {if (faw_temperature > 5) then {call _bias_clouds} else {0}};

	_scenar_storm = [
	//step		time,rnd	overcast,rnd	rain,rnd	mist,rnd	wind,rnd	snow,rnd
	/*1*/	[	5,1,		-1,-1,			0.1,0.1,	0.2,0.1,	0.9,0.2,	0,0			],
	/*2*/	[	4,1,		0.9,0.05,		0.9,0.02,	-1,-1,		0.2,0.1,	0,0			],
	/*3*/	[	4,1,		1,0,			-1,-1,		0.4,0.1,	0,0,		0,0			],
	/*4*/	[	15,1,		1,0,			0.9,0.1,	0.4,0.1,	1,0,		0,0			],
	/*5*/	[	15,2,		0.9,0.05,		0.4,0.3,	0.3,0.1,	0.2,0.1,	0,0			]
	];
	_bias_storm = {(0 max (faw_temperature - 15) / 15) * _moisture * 3 };

	_scenar_mist = [
	//step		time,rnd	overcast,rnd	rain,rnd	mist,rnd	wind,rnd	snow,rnd
	/*1*/	[	10,1,		0.5,0.05,		0,0,		-1,-1,		1,0,		-1,-1		],
	/*2*/	[	20,2,		0.75,0.05,		-1,-1,		0.8,0.1,	0,0,		0,0			],
	/*3*/	[	20,2,		0.4,0.05,		-1,-1,		0.3,0.1,	-1,-1,		-1,-1		]
	];
	_bias_mist = {0 max 4 * (0.1 max (10 - faw_temperature) / 10) * (3 * _moisture - 1) / 2 * (if (!(sunOrMoon  in [0,1])) then {4} else {call _bias_clouds})};

	_scenar_snow = [
	//step		time,rnd	overcast,rnd	rain,rnd	mist,rnd	wind,rnd	snow,rnd
	/*1*/	[	6,2,		0.7,0.1,		0,0,		-1,-1,		-1,-1,		-1,-1		],
	/*2*/	[	6,2,		0.9,0.05,		0,0,		0.8,0.02,	0.02,0.01,	1,0			],
	/*3*/	[	20,10,		0.9,0.05,		0,0,		0.8,0.02,	-1,-1,		1,0			],
	/*4*/	[	7,2,		0.8,0,			0.1,0.05,	0.67,0.05,	-1,-1,		0.2,0		]
	];
	_bias_snow = {(call _bias_clouds) min (0 max (5 - faw_temperature) / 5)};

	_probalink = [
	//			sun		clouds	rain	storm	mist	snow	scenario		bias			toString
	/*sun   */	[ 0.2,	0.2,	0,		0.2,	0.2,	0.2,    _scenar_sun,	_bias_sun,		"Clear" ],
	/*clouds*/	[ 0.2,	0,		0.2,	0,		0.2,	0.4,	_scenar_clouds,	_bias_clouds,	"Clouds" ],
	/*rain  */	[ 0.4,	0.2,	0,		0,		0.1,	0.3,	_scenar_rain,	_bias_rain,		"Rain" ],
	/*storm */	[ 0.5,	0.2,	0.1,	0,		0.2,	0,		_scenar_storm,	_bias_storm,	"Storm" ],
	/*mist  */	[ 0.1,	0.2,	0.1,	0,		0.2,	0.4,	_scenar_mist,	_bias_mist,		"Fog" ],
	/*snow  */	[ 0.3,	0.3,	0.1,	0,		0.1,	0.2,	_scenar_snow,	_bias_snow,		"Snow" ]
	];

	_myrand = {
		private [ "_x" ];
		_x  = _this select 1;
		_x - random(2 * _x)  + (_this select 0);
	};

	// INIT
	_groundtemperature = 0;
	#ifdef WEATHER_FOLLOWSEASONS
	_groundtemperature = -5 * cos(360 * (dateToNumber date));
	#endif
	#ifdef WEATHER_SOUTHEMISPHERE
	_groundtemperature = -_groundtemperature;
	#endif
	_groundtemperature = _groundtemperature + 15;

	faw_temperature = (1-cos((daytime-4)*15))*10 + _groundtemperature - 17.5 + random 15;
	faw_temperature = -5 max (35 min faw_temperature);
	_moisture = 0.33 + ((faw_temperature + 5) / 40 * random 0.66);

	_skyid = ceil random 3;
	_skyproba = _probalink select _skyid;
	_skyscenar = _skyproba select 6;
	_skyscenarstep =  (count _skyscenar) - 1;
	_skyscenarrow = [];
	faw_init = [ 0, random 0.7, 0, random 0.2, random 0.5, 0, 180 ];
	faw_target = +(faw_init);
	faw_directive = +(faw_init);
	faw_PV = nil;

	diag_log format [ "%1 date:%2 GndTemp:%3 Temp:%4 Moisture:%5  Initialization done", 
		__FILE__, date, _groundtemperature, faw_temperature, _moisture];

	// main loop
	while {true} do {
		private ["_curproba","_scenarbias","_sumproba","_bias_func","_cloud","_rain","_wind","_z","_y","_x"];

		// check if it's time to move to next step
		if (diag_tickTime > (faw_target select 0)) then {
			_skyscenarstep = _skyscenarstep + 1;
			if (_skyscenarstep == count _skyscenar) then {
				// imagine another sky
				_curproba = [];
				_scenarbias = [];
				_sumproba = 0;
				for "_x" from 0 to 5 do {
					_bias_func = (_probalink select _x) select 7;
					_scenarbias set [_x, call _bias_func];
					_y = (_skyproba select _x) * (call _bias_func);
					_curproba set [ _x, _y ];
					_sumproba = _sumproba + _y;
				};
				_sumproba = random _sumproba;
				for "_x" from 0 to 5 do {
					_sumproba = _sumproba - (_curproba select _x);
					if (_sumproba <= 0 ) exitWith {
						_skyid = _x;
						_skyproba = _probalink select _skyid;
						_skyscenar = _skyproba select 6;
						_skyscenarstep = 0;						
					};
				};
				diag_log format [ "WEATHER date:%1 GndTemp:%2 Temp:%3 Moisture:%4  Changing to ""%5""", 
					date, _groundtemperature, faw_temperature, _moisture, _skyproba select 8 ];
	#ifdef WEATHER_VERBOSE
				diag_log format [ "%5: changing sky to _skyid:%1 _skyscenarstep:%2 _scenarbias:%4 _curproba:%6", 
				_skyid, _skyscenarstep, _skyscenar, _scenarbias, date, _curproba];
	#endif
			};
			// set next step...
			faw_init = +(faw_target);
			faw_directive = +(faw_target);
			// set new forecast params
			_skyscenarrow = _skyscenar select _skyscenarstep;
			for "_x" from 0 to 11 step 2 do {
				_y = _skyscenarrow select _x;
				if (_y != -1) then {
					faw_target set [ _x / 2, [_y, _skyscenarrow select (_x + 1)] call _myrand ];
				};
			};
			// make Arma2 engine happy:
			// force cloud level according to rain level
			faw_target set [ 1, (faw_target select 1) max ((faw_target select 2)/2) ];
			// force fog level according to cloud or rain levels
			faw_target set [ 3, ((faw_target select 3) max ((faw_target select 2)/4)) max ((faw_target select 1)/4) ];
			faw_target set [ 6, 135 + random 180 ]; // wind direction
			faw_target set [ 0, diag_tickTime + _tick * (faw_target select 0)];
	#ifdef WEATHER_VERBOSE
			diag_log format [ "FAW Switching to step %1 for scenario %2, faw_target:%3", _skyscenarstep,  _skyproba select 8, faw_target];
	#endif
			-1 call faw_playerSetup;
		}
		else {
			// send params to clients every 5 minutes anyway
			if (((faw_target select 0)-diag_tickTime) % 300 < _tick) then { 
				-1 call faw_playerSetup;
			};	
		};
		// update directive
		_ratio = (diag_tickTime - (faw_init select 0)) / ((faw_target select 0) - (faw_init select 0));
		for "_x" from 1 to 6 do {
			_y = (faw_target select _x) - (faw_init select _x);
			_y = _y * _ratio;	
			_y = _y + (faw_init select _x);
			if (_x < 6) then { _y = 0 max (1 min _y); };
			faw_directive set [ _x, _y ];
		};
		// compute current temperature / ground temperature / moisture:
		_cloud = faw_directive select 1; 
		_rain = faw_directive select 2; 
		_wind = faw_directive select 4;  
		faw_temperature =  faw_temperature + (1/_onedayticks) * (
			(1.5 - sqrt(_cloud)) * (sunOrMoon - 0.5 -cos(daytime*15)) * 80 
			+(_groundtemperature - faw_temperature)
			-sqrt(_rain) * (1 + _wind) * 10
		);
		faw_temperature = -5 max (35 min faw_temperature);
		_groundtemperature = (_onedayticks * _groundtemperature + faw_temperature) / (_onedayticks + 1);
		_moisture = _moisture + (1/_onedayticks) * ((sqrt(_rain)) * (1 min (faw_temperature / 15))*5 - (_wind * sunOrMoon));
		_moisture = 0 max (1 min _moisture);
	#ifdef WEATHER_VERBOSE
		diag_log format [ "FAW tick %6 in step %1 for scenario %2, target:%3 directive:%4 init:%5   temp:%9 gnd:%7 mois:%8", 
			_skyscenarstep, _skyproba select 8, faw_target, faw_directive, faw_init, diag_tickTime,
			_groundtemperature, _moisture, faw_temperature
			];
	#endif
		sleep _tick;
	}; 
};

