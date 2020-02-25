// wait for BIS functions to be loaded
waitUntil { !isNil "BIS_fnc_init" };

// load functions
private _functions = [
  ["util", "CC_fnc_arrayFlatten"],
  ["util", "CC_fnc_arrayFormat"],
  ["util", "CC_fnc_mathRound"],
  ["util", "CC_fnc_vehicleContains"],
  ["util", "CC_fnc_vehicleUnloadUnit"],
  ["util", "CC_fnc_vehicleUnload"],
  ["util", "CC_fnc_addActions"],
  ["util", "CC_fnc_timedSpawn"],

  ["mod", "CC_fnc_moduleInit"],
  ["mod", "CC_fnc_moduleLog"],
  ["mod", "CC_fnc_moduleEventRegister"],
  ["mod", "CC_fnc_moduleEventFire"],

  ["convoy", "CC_fnc_convoyRecordRoute"],
  ["convoy", "CC_fnc_convoyShowRoute"]
];

{
  private _category = _x select 0;
  private _name = _x select 1;

  // debug
  diag_log format ["CC: loading function: %1 / %2", _category, _name];

  // compile the function
  private _filename = format ["cc\%1\%2.sqf", _category, _name];
  private _function = compile preprocessFileLineNumbers _filename;

  // store the function in the mission namespace
  missionNamespace setVariable [_name, _function];
} forEach _functions;

// load scripts
private _scripts = [
  "cc\debug\module.sqf"
];

{
  // debug
  diag_log format ["CC: loading script: %1", _x];

  // execute the module script
  private _script = [] execVM _x;

  // wait for the script to finish executing
  waitUntil {
    // notify the player what is currently loading
    hintSilent format ["Loading script: %1", _x];

    // loop until the script is done
    scriptDone _script;
  };
} forEach _scripts;

// done
hintSilent "";
