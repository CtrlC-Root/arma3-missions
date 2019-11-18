// load modules and scenario
hintSilent "Loading scripts...";

private "_scripts";
_scripts = [
  "cc\init.sqf",
  "local\scenario.sqf",
  "local\nato_convoy.sqf",
  "local\nato_dialogue.sqf"
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
[] call CC_Convoy_init;

// initialize scenario
hintSilent "Initializing scenario...";
[] call CC_Scenario_init;

// clear the screen
hintSilent "";
