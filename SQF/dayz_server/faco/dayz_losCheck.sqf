/*
        Created exclusively for ArmA2:OA - Epoch DayZ Mod.
        Please request permission to use/alter/distribute from the author (facoptere@gmail.com)
*/

				private [ "_cantSee", "_target", "_agent", "_cantSee", "_tPos", "_zPos", "_ed", "_deg", "_fov" ];
				_target = _this select 1; 
				_agent = _this select 0;
				_cantSee = true;
				_fov = 110;

// 				_lc_time = 10 * floor (diag_ticktime/10);
// 				if (isNil "lc_time") then { lc_time =_lc_time; lc_count = 0; lc_count2 = 0; };
// 				if (lc_time != _lc_time) then { 
// 					hint format [ "%1 > %2 %3/%4", lc_time, _lc_time, lc_count, lc_count2	 ]; 
// 					lc_time =_lc_time; lc_count = 0; lc_count2 = 0;
// 				};

				if ((diag_fpsmin >= 10) AND {((!isNull _target) and {!(isNull _agent)})}) then {
				/*	_zPos = [];
					if (!isNil "_damage") then { // called in attack -- prevent attack thru glass window
						_zPos = getPosASL _agent;
						_zPos set [2, 0.2 + (_zPos select 2) ];
					}
					else {
						_zPos = eyePos _agent;
					};
					_tPos = getPosASL vehicle _target; */
					_zPos = eyePos _agent;
					_zPos set [2, 0.2 + (_zPos select 2) ];
					_tPos = eyePos _target;
					_tPos set [2, 0.2 + (_tPos select 2) ];
					if (_tPos distance _zPos < 100) then {
						_ed = eyeDirection _agent;
						_ed = (_ed select 0) atan2 (_ed select 1);
						_deg = [_zPos, _tPos] call BIS_fnc_dirTo;
						_deg = (_deg - _ed + 720) % 360;
						if (_deg > 180) then { _deg = _deg - 360; };
						if (abs(_deg) < _fov) then {
							_cantSee = (terrainIntersectASL [_tPos, _zPos]) OR {(lineIntersects [_tPos, _zPos, _agent, vehicle _target])};
//							lc_count = lc_count +1;
						};
					};
				};
//				lc_count2 = lc_count2 +1;
				_cantSee
			
