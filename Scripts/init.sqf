// wait for BIS functions to be loaded
waitUntil { !isNil "BIS_fnc_init" };

// load functions
private _functions = [
  "CC_fnc_arrayFlatten",
  "CC_fnc_mathRound"
];

{
  // debug
  diag_log format ["CC: loading function: %1", _x];

  // compile the function
  private _filename = format ["cc\util\%1.sqf", _x];
  private _function = compile preprocessFileLineNumbers _filename;

  // store the function in the mission namespace
  missionNamespace setVariable [_x, _function];
} forEach _functions;

// load scripts
private _scripts = [
  "cc\util\vehicle.sqf",

  "cc\module.sqf",
  "cc\mod\convoy.sqf"
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
