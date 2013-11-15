
private ["_date", "_x", "_limit", "_period", "_state"];
_period = 60*5;
if (isnil "_state") then { _state=0; }; 

_dawnfadein = 0.62 + (random 20)/100;
_dawnfadeout = 0.1 + (random 20)/100;

diag_log "FACO MIST Starting...";
while {isServer} do {	 
	if (daytime >= 5.75 && daytime < 19.25) then {
		// during day light, lett DynamicWeather do his shitty task
		_state = 0; 
	}
	else { if (daytime >= 19.25 && _state < 1) then {  //
		300 setRain 0.0;
		drn_var_DynamicWeather_Rain = 0;
		drn_DynamicWeather_CurrentWeatherChange = "OVERCAST";
		_x = 0.65 + (random 8)/100;
		drn_DynamicWeather_WeatherTargetValue = _x;
		drn_DynamicWeather_WeatherChangeCompletedTime =drn_DynamicWeather_WeatherChangeStartedTime+450;
		_x = random 3;
		_x = _x * _x - 4.5;
		drn_DynamicWeather_WindX = drn_DynamicWeather_WindX + _x;
		drn_DynamicWeather_WindZ = drn_DynamicWeather_WindZ - _x;
		call drn_fnc_DynamicWeather_SetWeatherAllClients;	
		diag_log "FACO MIST Clouds set during twilight";
		_state = 1;
	}
	else { if (daytime >= 19.25 && _state < 2) then {  
		300 setRain 0.0;
		_x = 0.78 + (random 8)/100;
		drn_var_DynamicWeather_Rain = 0;
		drn_DynamicWeather_CurrentWeatherChange = "FOG";
		drn_DynamicWeather_WeatherTargetValue = _x;
		drn_DynamicWeather_WeatherChangeCompletedTime =drn_DynamicWeather_WeatherChangeStartedTime+450;
		drn_DynamicWeather_WindX=0;
		drn_DynamicWeather_WindZ=0;
		call drn_fnc_DynamicWeather_SetWeatherAllClients;	
		diag_log "FACO MIST Fog set during twilight";
		_state = 2;
	}
	else { if (daytime >= 20.25 && _state < 3 ) then {
		300 setRain 0.0;
		//setWind [0,0,true];
		drn_var_DynamicWeather_Rain = 0;
		drn_DynamicWeather_CurrentWeatherChange = "OVERCAST";
		drn_DynamicWeather_WeatherTargetValue = (random 50)/100;
		drn_DynamicWeather_WeatherChangeCompletedTime =drn_DynamicWeather_WeatherChangeStartedTime+450;
		//drn_DynamicWeather_WindX=0;
		//drn_DynamicWeather_WindZ=0;
		call drn_fnc_DynamicWeather_SetWeatherAllClients;
		diag_log "FACO MIST Stary night set";
		_state = 3;
	}
	else { if (daytime >= 20.25 || daytime < 3.25) then {
		300 setRain 0.0;
		drn_var_DynamicWeather_Rain = 0;
		drn_DynamicWeather_CurrentWeatherChange = "OVERCAST";
		drn_DynamicWeather_WeatherTargetValue = (random 50)/100;
		drn_DynamicWeather_WeatherChangeCompletedTime = drn_DynamicWeather_WeatherChangeStartedTime+450;
		call drn_fnc_DynamicWeather_SetWeatherAllClients;
	//	diag_log "FACO MIST Keeping a stary night";
		_state = 4;
	}
	else { if (daytime >= 3.25 && daytime < 4.25 && _state <= 5) then { //
		300 setRain 0.0;
		drn_var_DynamicWeather_Rain = 0;
		drn_DynamicWeather_CurrentWeatherChange = "FOG";
		drn_DynamicWeather_WeatherTargetValue = _dawnfadein;
		drn_DynamicWeather_WeatherChangeCompletedTime =drn_DynamicWeather_WeatherChangeStartedTime+(4.35-daytime)*3600;
		drn_DynamicWeather_WindX=0;
		drn_DynamicWeather_WindZ=0;
		call drn_fnc_DynamicWeather_SetWeatherAllClients;
		_state = 5;
		diag_log "FACO MIST Fog fade in at dawn set";
	}
	else { if (daytime >= 4.25 && daytime < 5.75 && _state <= 6) then { //
		drn_DynamicWeather_CurrentWeatherChange = "FOG";
		drn_DynamicWeather_WeatherTargetValue = _dawnfadeout;
		drn_DynamicWeather_WeatherChangeCompletedTime =drn_DynamicWeather_WeatherChangeStartedTime+(5.85-daytime)*3600;
		drn_DynamicWeather_WindX=5;
		drn_DynamicWeather_WindZ=5;
		call drn_fnc_DynamicWeather_SetWeatherAllClients;
		_state = 6;
		diag_log "FACO MIST Fog fade out at dawn set";
	};};};};};};};

	_limit = daytime;
	_limit = _limit + (_period - ((_limit * 3600) % _period))/3600; 
	while { (daytime < _limit) } do {
		//diag_log (format["FACO MIST dayhour: %1, fog: %2, rain: %3, wind: %4, clouds: %5, state:%6 ,_limit:%7",
		//	daytime, fog, rain, wind, overcast, _state,_limit]);
		sleep 60;
		if (daytime<1 && _limit>=24) then { _limit = _limit - 24; };
	};
};
diag_log "FACO MIST Stoping...";
 
