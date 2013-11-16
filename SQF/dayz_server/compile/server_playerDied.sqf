private ["_characterID","_minutes","_newObject","_playerID","_playerName","_infected","_victim","_victimName","_killer","_killerName","_weapon","_distance","_message","_loc_message","_key","_death_record"];
//[unit, weapon, muzzle, mode, ammo, magazine, projectile]
_characterID = 	_this select 0;
_minutes =		_this select 1;
_newObject = 	_this select 2;
_playerID = 	_this select 3;
_playerName = 	_this select 4;
_infected =		_this select 5;

_victim = _newObject;
_victimName = _victim getVariable["bodyName", "nil"];

_killer = _victim getVariable["AttackedBy", "nil"];
_killerName = _victim getVariable["AttackedByName", "nil"];

// when a zombie kills a player _killer, _killerName and _weapon will be "nil"
// we can use this to determine a zombie kill and send a customized message for that. right now no killmsg means it was a zombie.
if (_killerName != "nil") then
{
	_weapon = _victim getVariable["AttackedByWeapon", "nil"];
	_distance = _victim getVariable["AttackedFromDistance", "nil"];

	if (_victimName == _killerName) then 
	{
		_message = format["%1 killed himself",_victimName];
		_loc_message = format["PKILL: %1 killed himself", _victimName];
	}
	else 
	{
		_message = format["%1 was killed by %2 with weapon %3 from %4m",_victimName, _killerName, _weapon, _distance];
		_loc_message = format["PKILL: %1 was killed by %2 with weapon %3 from %4m", _victimName, _killerName, _weapon, _distance];
	};

	diag_log _loc_message;
	
	if(DZE_DeathMsgGlobal) then {
		[nil, nil, rspawn, [_killer, _message], { (_this select 0) globalChat (_this select 1) }] call RE;
	};
	/* needs customRemoteMessage 
	if(DZE_DeathMsgGlobal) then {
		customRemoteMessage = ['globalChat', _message, _killer];
		publicVariable "customRemoteMessage";
	};
	*/
	if(DZE_DeathMsgSide) then {
		[nil, nil, rspawn, [_killer, _message], { (_this select 0) sideChat (_this select 1) }] call RE;
	};
	if(DZE_DeathMsgTitleText) then {
		[nil,nil,"per",rTITLETEXT,_message,"PLAIN DOWN"] call RE;
	};

	// build array to store death messages to allow viewing at message board in trader citys.
	_death_record = [
		_victimName,
		_killerName,
		_weapon,
		_distance,
		ServerCurrentTime
	];
	PlayerDeaths set [count PlayerDeaths,_death_record];

	// Cleanup
	_victim setVariable["AttackedBy", "nil", true];
	_victim setVariable["AttackedByName", "nil", true];
	_victim setVariable["AttackedByWeapon", "nil", true];
	_victim setVariable["AttackedFromDistance", "nil", true];
};

// Might not be the best way...
/*
if (isnil "dayz_disco") then {
	dayz_disco = [];
};
*/

// dayz_disco = dayz_disco - [_playerID];
_newObject setVariable["processedDeath",diag_tickTime];

if (typeName _minutes == "STRING") then 
{
	_minutes = parseNumber _minutes;
};

diag_log ("PDEATH: Player Died " + _playerID);

if (_characterID != "0") then 
{
	_key = format["CHILD:202:%1:%2:%3:",_characterID,_minutes,_infected];
	//#ifdef DZE_SERVER_DEBUG_HIVE
	diag_log _key;
	//#endif
	_key call server_hiveWrite;
} 
else 
{
	deleteVehicle _newObject;
};
// FACO >>
diag_log format ["Player UID#%3 CID#%4 %1 as %5 died at %2", 
	_victim call fa_plr2str, (getPosATL _victim) call fa_coor2str,
	getPlayerUID _victim,_characterID,
	typeOf _victim
];

// _x = _newObject getVariable [ "attacker", ""];
// if (_x != "") then {
// 	_y = format ["\n\nLast attacker: %1", _x];
// 	[_newObject,_newObject,"loc",rTITLETEXT, _y,"PLAIN DOWN",5] call RE;
// 	diag_log format [ "On %1 screen: %2", name _newObject, _x];
// };

_newObject setVariable["noatlf4",0];
// << FACO 
