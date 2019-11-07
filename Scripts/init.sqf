// wait for BIS functions to be loaded
waitUntil { !isNil "BIS_fnc_init" };

// load scripts
private "_scripts";
_scripts = [
  "cc\modules.sqf",
  "cc\multiplayer.sqf"
];

{
  // debug
  diag_log format ["CC: loading script: %1", _x];

  // execute the module script
  private "_script";
  _script = [] execVM _x;

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
