CC_scenario_waypointSet = {
  params [
    ["_group", grpNull, [grpNull]],
    ["_points", [], [[]]]
  ];

  // validate parameters
  if (isNull _group) exitWith {
    ["group is null"] call BIS_fnc_error;
  };

  if (count _points == 0) exitWith {
    ["points array is empty"] call BIS_fnc_error;
  };

  // re-run this function on the server if we're not already there
  if (!isServer) exitWith {
    [_group, _points] remoteExec ["CC_scenario_waypointSet", 2, false];
  };

  // add the group to each waypoint list
  {
    // retreive the list of groups or create a new empty one for this waypoint
    private _groups = [];
    private _index = [CC__scenario_waypoints, _point] call BIS_fnc_findInPairs;
    if (_index >= 0) then {
      _groups = ((CC__scenario_waypoints select _index) select 1);
    } else {
      CC__scenario_waypoints pushBack [_point, _groups];
    };

    // add the group to the list if not already present
    _groups pushBackUnique _group;
  } forEach _points;

  // publish the list
  publicVariable "CC__scenario_waypoints";
};

CC_scenario_waypointClear = {
  params [
    ["_group", grpNull, [grpNull]],
    ["_point", "", [""]]
  ];

  // validate parameters
  if (isNull _group) exitWith {
    ["group is null"] call BIS_fnc_error;
  };

  if (_point == "") exitWith {
    ["point is an empty string"] call BIS_fnc_error;
  };

  // re-run this function on the server if we're not already there
  if (!isServer) exitWith {
    [_group, _point] remoteExec ["CC_scenario_waypointClear", 2, true];
  };

  // retrieve the list of registered groups for the waypoint
  private _groups = [CC__scenario_waypoints, _point] call BIS_fnc_getFromPairs;
  if (isNil "_groups") exitWith {
    ["invalid waypoint %1", _point] call BIS_fnc_error;
  };

  // remove the group from the list of registered groups and publish it
  // only if the group is already in the list
  if (_group in _groups) then {
    _groups = _groups - [_group];
    [CC__scenario_waypoints, _point, _groups] call BIS_fnc_setToPairs;
    publicVariable "CC__scenario_waypoints";
  };
};

CC_scenario_waypointCheck = {
  params [
    ["_group", grpNull, [grpNull]],
    ["_point", "", [""]]
  ];

  // validate parameters
  if (isNull _group) exitWith {
    ["group is null"] call BIS_fnc_error;
  };

  if (_point == "") exitWith {
    ["point is an empty string"] call BIS_fnc_error;
  };

  // retrieve the list of groups for this waypoint
  private _groups = [CC__scenario_waypoints, _point] call BIS_fnc_getFromPairs;
  if (isNil "_groups") exitWith {
    ["point not found: %1", _point] call BIS_fnc_error;
  };

  // remove the group from the list if it's present
  if (_group in _groups) then {
    // globally
    [_group, _point] call CC_scenario_waypointClear;

    // locally
    _groups = _groups - [_group];
  };

  // waypoint is complete if we're not waiting on any other groups
  (count _groups) == 0;
};
