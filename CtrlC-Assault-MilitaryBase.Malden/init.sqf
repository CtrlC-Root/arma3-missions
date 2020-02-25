// load modules and scenario
hintSilent "Loading scripts...";

private "_scripts";
_scripts = [
  "cc\init.sqf",
  "local\flags.sqf",
  "local\waypoints.sqf",
  "local\scenario.sqf"
];

{
  private "_script";
  _script = [] execVM _x;

  waitUntil {
    hintSilent format ["Loading script: %1", _x];
    scriptDone _script
  };
} forEach _scripts;

// initialize modules
hintSilent "Initializing modules...";
[] call CC_debug_init; // XXX: initialize debug module
[] call CC_debug_config; // XXX: enable debug interface for player

// initialize scenario
hintSilent "Initializing scenario...";
[] call CC_scenario_init;

// clear the screen
hintSilent "";
