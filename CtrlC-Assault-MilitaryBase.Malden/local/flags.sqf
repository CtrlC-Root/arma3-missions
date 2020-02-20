CC_scenario_setFlag = {
  params [
    ["_name", "", [""]]
  ];

  if (_name == "") exitWith {
    ["name is empty"] call BIS_fnc_error;
  };

  // re-run this function on the server if we're not already there
  if (!isServer) exitWith {
    [_name] remoteExec ["CC_scenario_setFlag", 2, false];
  };

  // set the flag
  [CC__scenario_flags, _name, true] call BIS_fnc_setToPairs;
  publicVariable "CC__scenario_flags";
};

CC_scenario_clearFlag = {
  params [
    ["_name", "", [""]]
  ];

  if (_name == "") exitWith {
    ["name is empty"] call BIS_fnc_error;
  };

  // re-run this function on the server if we're not already there
  if (!isServer) exitWith {
    [_name] remoteExec ["CC_scenario_clearFlag", 2, false];
  };

  // clear the flag
  [CC__scenario_flags, _name, false] call BIS_fnc_setToPairs;
  publicVariable "CC__scenario_flags";
};

CC_scenario_checkFlag = {
  params [
    ["_name", "", [""]]
  ];

  if (_name == "") exitWith {
    ["name is empty"] call BIS_fnc_error;
  };

  private _value = [CC__scenario_flags, _name] call BIS_fnc_getFromPairs;
  if (isNull _value) exitWith {
    ["flag not found: %1", _name] call BIS_fnc_error;
  };

  _value;
};
