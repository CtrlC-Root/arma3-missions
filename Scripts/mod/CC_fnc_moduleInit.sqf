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

// initialize client and exit early
if (isServer) then {
  ["module", "init", "server: %1", [_name]] call CC_fnc_moduleLog;

  // initialize global and local module lists
  if (isNil "CC__modules" || isNil "CC__modules_local") then {
    CC__modules = [];
    CC__modules_local = [];
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

  // TODO: start the server worker if necessary
} else {
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
