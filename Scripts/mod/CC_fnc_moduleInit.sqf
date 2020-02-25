/**
 * Initialize a module. This method should be called at the beginning of
 * all module init methods. The server init function will be called on
 * the server machine first. It can optionally return settings in the form of:
 * [
 *   string array of event names,
 *   server task function,
 *   debug status function,
 *   key value array of debug action names and functions
 * ]. After the server init function is called the module will be registered
 * on the server and the list of loaded modules will be sent to all clients.
 * Lastly the client init function will be called on all clients excluding
 * a dedicated server. It can optionally return settings in the form of:
 * [
 *   key value array of event handler names and functions
 * ].
 *
 * @param 0 module name
 * @param 1 server init function
 * @param 2 client init function
 */

params [
  ["_name", "", [""]],
  ["_serverInit", {[]}, [{}]],
  ["_clientInit", {[]}, [{}]]
];

// validate module name
if (_name == "") exitWith {
  ["empty module name"] call BIS_fnc_error;
};

// define the server task worker
private _serverTaskWorker = {
  // [[module name, [script handle, start time, elapsed time, last result]], ...]
  // last result -> true if task should run again
  CC__module_tasks = [];

  // manage server tasks while the module system is active
  while { !(isNil "CC__modules") } do {
    // start server tasks and track elapsed time for running tasks
    {
      // parse the module settings
      _x params ["_moduleName", "_moduleSettings"];
      _moduleSettings params ["_events", "_serverTask", "_statusTask"];

      // retrieve or create the cache entry
      private _state = [CC__module_tasks, _moduleName] call BIS_fnc_getFromPairs;
      if (isNil "_state") then {
        // scriptDone scriptNull -> true
        _state = [scriptNull, 0, 0, true];
        CC__module_tasks pushBack [_moduleName, _state];
      };

      // parse the state values
      _state params ["_script", "_startTime", "_elapsedTime", "_lastResult"];

      // check if the task is finished running
      if (scriptDone _script) then {
        // run the task again if the last result was true
        if (_lastResult) then {
          [[], _serverTask, _state] call CC_fnc_timedSpawn;
        };
      } else {
        // update the elapsed time
        _elapsedTime = time - _startTime;
        _state set [2, _elapsedTime];
      };
    } forEach CC__modules;

    // terminate tasks and prune cache entries
    CC__module_tasks = CC__module_tasks select {
      // parse the cache settings
      _x params ["_moduleName", "_state"];
      _state params ["_script", "_startTime", "_elapsedTime", "_lastResult"];

      // determine if the module is still loaded
      private _moduleIndex = [CC__modules, _moduleName] call BIS_fnc_findInPairs;
      private _moduleLoaded = (_moduleIndex >= 0);

      // prune the server task if the module is no longer loaded
      if (!_moduleLoaded) exitWith {
        // terminate the script if it's still running
        if (!(scriptDone _script)) then {
          [
            "module",
            "server_task",
            "terminating task for unloaded module: %1",
            [_moduleName]
          ] call CC_fnc_moduleLog;

          terminate _script;
        };

        [
          "module",
          "server_task",
          "pruning task for unloaded module: %1",
          [_moduleName]
        ] call CC_fnc_moduleLog;

        // drop the cache entry
        false;
      };

      // keep the cache entry
      true;
    };

    // rate limit to 10 Hz
    sleep (1.0 / 10.0);
  };

  // stop all running tasks
  {
    _x params ["_moduleName", "_state"];
    _state params ["_script", "_startTime", "_elapsedTime", "_lastResult"];

    if (!(scriptDone _script)) then {
      terminate _script;
    };
  } forEach CC__module_tasks;

  // erase variables
  CC__module_tasks = nil;
};

// initialize the module
if (isServer) then {
  // initialize the module's server state
  ["module", "init", "server: %1", [_name]] call CC_fnc_moduleLog;

  // initialize global and local module lists
  if (isNil "CC__modules" || isNil "CC__modules_local") then {
    CC__modules = [];
    CC__modules_local = [];
  };

  // start the module task worker
  if (isNil "CC__modules_server_task") then {
    ["module", "init", "starting task worker"] call CC_fnc_moduleLog;
    CC__modules_server_task = [] spawn _serverTaskWorker;
  };

  // check if the module is already initialized
  private _moduleIndex = [CC__modules, _name] call BIS_fnc_findInPairs;
  if (_moduleIndex >= 0) exitWith {
    ["module", "init", "already initialized: %1", [_name]] call CC_fnc_moduleLog;
  };

  // initialize the module on the server
  private _serverSettings = [] call _serverInit;
  _serverSettings params [
    ["_events", [], [[]]],
    ["_serverTask", {False}, [{}]],
    ["_statusTask", {""}, [{}]]
  ];

  // register the module globally and notify all clients
  [
    CC__modules,
    _name,
    [_events, _serverTask, _statusTask]
  ] call BIS_fnc_setToPairs;
  publicVariable "CC__modules";
} else {
  // initialize the module's client state
  ["module", "init", "client: %1", [_name]] call CC_fnc_moduleLog;

  // initialize the local module list
  if (isNil "CC__modules_local") then {
    CC__modules_local = [];
  };

  // check if the module is already initialized
  private _moduleIndex = [CC__modules_local, _name] call BIS_fnc_findInPairs;
  if (_moduleIndex >= 0) exitWith {
    ["module", "init", "already initialized: %1", [_name]] call CC_fnc_moduleLog;
  };

  // wait until the module has initialized on the server
  waitUntil { !(isNil "CC__modules") };
  waitUntil { ([CC__modules, _name] call BIS_fnc_findInPairs) >= 0 };
};

// nothing left to do for dedicated servers
if (isDedicated) exitWith {};

// debug
["module", "init", "local client: %1", [_name]] call CC_fnc_moduleLog;

// register the module locally
private _eventHandlers = [];
[CC__modules_local, _name, [_eventHandlers]] call BIS_fnc_setToPairs;

// initialize the module on the local client
[] call _clientInit;
