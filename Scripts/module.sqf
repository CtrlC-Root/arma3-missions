/*****************************************************************************
 * Module support.                                                           *
 *****************************************************************************/

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
CC_Module_init = {
  // retrieve parameters
  params [
    ["_name", "", [""]],
    ["_serverInit", {[]}, [{}]],
    ["_clientInit", {[]}, [{}]]
  ];

  // validate module name
  if (_name == "") exitWith {
    ["module", "init", "empty module name"] call CC_Module_debug;
  };

  // initialize client and exit early
  if (isServer) then {
    ["module", "init", "server: %1", [_name]] call CC_Module_debug;

    // initialize global and local module lists
    if (isNil "CC__modules" || isNil "CC__modules_local") then {
      CC__modules = [];
      CC__modules_local = [];
    };

    // check if the module is already initialized
    private _moduleIndex = [CC__modules, _name] call BIS_fnc_findInPairs;
    if (_moduleIndex >= 0) exitWith {
      ["module", "init", "already initialized: %1", [_name]] call CC_Module_debug;
    };

    // initialize the module on the server
    private _serverSettings = [] call _serverInit;
    _serverSettings params [
      ["_events", [], [[]]],
      ["_serverTask", {False}, [{}]],
      ["_debugStatus", {""}, [{}]],
      ["_debugActions", [], [[]]]
    ];

    // register the module globally and notify all clients
    [
      CC__modules,
      _name,
      [_events, _serverTask, _debugStatus, _debugActions]
    ] call BIS_fnc_setToPairs;
    publicVariable "CC__modules";

    // TODO: start the server worker if necessary
  } else {
    ["module", "init", "client: %1", [_name]] call CC_Module_debug;

    // initialize the local module list
    if (isNil "CC__modules_local") then {
      CC__modules_local = [];
    };

    // check if the module is already initialized
    private _moduleIndex = [CC__modules_local, _name] call BIS_fnc_findInPairs;
    if (_moduleIndex >= 0) exitWith {
      ["module", "init", "already initialized: %1", [_name]] call CC_Module_debug;
    };

    // wait until the module has initialized on the server
    waitUntil { !(isNil "CC__modules") };
    waitUntil { ([CC__modules, _name] call BIS_fnc_findInPairs) >= 0 };
  };

  // nothing left to do for dedicated servers
  if (isDedicated) exitWith {};

  // debug
  ["module", "init", "local client: %1", [_name]] call CC_Module_debug;

  // register the module locally
  private _eventHandlers = [];
  [CC__modules_local, _name, [_eventHandlers]] call BIS_fnc_setToPairs;

  // initialize the module on the local client
  [] call _clientInit;
};

/**
 * Register a local event handler for a module event.
 *
 * @param 0 module name
 * @param 1 event name
 * @param 2 event handler
 */
CC_Module_event_register = {
  // retrieve parameters
  params [
    ["_name", "", [""]],
    ["_event", "", [""]],
    ["_handler", {}, [{}]]
  ];

  // validate parameters
  if (_name == "") exitWith {
    ["module", "event_register", "empty module name"] call CC_Module_debug;
  };

  if (_event == "") exitWith {
    ["module", "event_register", "empty event name"] call CC_Module_debug;
  };

  private _moduleIndex = [CC__modules, _name] call BIS_fnc_findInPairs;
  if (_moduleIndex < 0) exitWith {
    ["module", "event_register", "invalid module: %1", [_name]] call CC_Module_debug;
  };

  private _globalModule = (CC__modules select _moduleIndex) select 1;
  private _eventNames = _globalModule select 0;
  if (!(_event in _eventNames)) exitWith {
    [
      "module",
      "event_register",
      "invalid module event: %1", [_name, _event]
    ] call CC_Module_debug;
  };

  // register the event handler
  // XXX: assuming CC__modules and CC__modules_local keys are in the same order
  private _localModule = (CC__modules_local select _moduleIndex) select 1;
  private _localEvents = _localModule select 0;
  [_localEvents, _name, [_handler]] call BIS_fnc_addToPairs;
};

/**
 * Run local event handlers for a module event.
 *
 * @param 0 module name
 * @param 1 event name
 * @param 2 event handler arguments, defaults to []
 * @param 3 run handlers asynchronously, defaults to true
 * @returns array of script handles in asynchronous mode, otherwise array
 *          of event handler results
 */
CC_Module_event_fire = {
  // retrieve parameters
  params [
    ["_name", "", [""]],
    ["_event", "", [""]],
    ["_args", [], [[]]],
    ["_async", true, [true]]
  ];

  // validate parameters
  if (_name == "") exitWith {
    ["module", "event_fire", "empty module name"] call CC_Module_debug;
  };

  if (_event == "") exitWith {
    ["module", "event_fire", "empty event name"] call CC_Module_debug;
  };

  // retrieve the local module
  private _index = [CC__modules_local, _name] call BIS_fnc_findInPairs;
  if (_index < 0) exitWith {
    ["module", "event_fire", "invalid module: %1", [_name]] call CC_Module_debug;
  };

  private _localModule = (CC__modules_local select _index) select 1;

  // retrieve the event handlers
  private _localEvents = _localModule select 0;
  _index = [_localEvents, _event] call BIS_fnc_findInPairs;
  if (_index < 0) exitWith {
    [
      "module",
      "event_fire",
      "invalid module event: %1, %2",
      [_name, _event]
    ] call CC_Module_debug;
  };

  private _handlers = (_localEvents select _index) select 1;

  // run the event handlers asynchronously
  if (_async) exitWith {
    private "_scripts";
    _scripts = [];

    {
      _scripts pushBack ([_args, _x] spawn {
        (_this select 0) call (_this select 1);
      });
    } forEach _handlers;

    // return the script handles
    _scripts;
  };

  // run the event handlers synchronously
  private "_results";
  _results = [];

  {
    _results pushBack (_args call _x);
  } forEach _handlers;

  // return the handler results
  _results;
};

/**
 * Record a debug message in the system log and optionally send it to the
 * local player's screen using the system chat.
 *
 * @param 0 module name
 * @param 1 module function or relevant section of code
 * @param 2 message format string
 * @param 3 optional list of format values
 */
CC_Module_debug = {
  // retrieve parameters
  params [
    ["_module", "", [""]],
    ["_part", "", [""]],
    ["_msg", "", [""]],
    ["_args", [], [[]]]
  ];

  // validate parameters
  if (_module == "" || _part == "" || _msg == "") exitWith {
    diag_log format ["CC: module: debug: invalid arguments: %1", _this];
  };

  // format the message
  private "_final";
  _final = format [
    "CC: %1: %2: %3",
    toLower _module,
    toLower _part,
    format ([_msg] + _args)
  ];

  // write the message to the log file
  diag_log _final;

  // print messages in side chat on clients where the player has
  // debugging enabled
  if (isServer && isDedicated) exitWith {};
  if (local player && player getVariable ["cc_debug", false]) then {
    systemChat _final;
  };
};

/**
 * Enable the debug interface for a player unit.
 *
 * @param 0 player unit
 */
CC_Module_debug_enable = {
  // retrieve parameters
  params [
    ["_unit", player, [objNull]]
  ];

  // corner case: function called with default arguments on server so player is objNull
  // XXX: this seems to avoid the problem but the message below is never written to the log?
  if (isNull _unit) exitWith {
    ["module", "debug_enable", "null unit"] call CC_Module_debug;
  };

  // verify the unit is a player
  private "_players";
  _players = ([] call BIS_fnc_listPlayers) - (entities "HeadlessClient_F");

  if (!(_unit in _players)) exitWith {
    [
      "module",
      "debug_enable",
      "unit not a player: %1",
      [_unit]
    ] call CC_Module_debug;
  };

  // enable the interface on the local client
  [_unit] remoteExec ["CC__module_debug_enable_local", _unit, false];
};

/**
 * Enable the debug interface for a local unit.
 *
 * @param 0 local unit
 */
CC__module_debug_enable_local = {
  // retrieve parameters
  params [
    ["_unit", objNull, [objNull]]
  ];

  // variables
  _unit setVariable ["cc_debug", true];
  _unit setVariable ["cc_debug_hud", false];

  // add user actions
  private "_actions";
  _actions = [_unit addAction [
    "DEBUG: Toggle HUD",
    CC__module_debug_toggle_hud,
    [],
    0.1,
    false,
    true,
    "",
    "(_target getVariable ['cc_debug', false]) && (_target == _this)"
  ]];

  {
    // retrieve module debug actions
    private _name = _x select 0;
    private _settings = _x select 1;
    private _debugActions = _settings select 3;

    // create actions for module debug actions
    {
      // unpack the debug action
      private ["_action", "_handler"];
      _action = _x select 0;
      _handler = _x select 1;

      // create the user action and keep track of it's ID
      _actions pushBack (_unit addAction [
        format ["DEBUG [%1]: %2", toUpper _name, _action],
        _handler,
        [],
        0,
        false,
        true,
        "",
        "(_target getVariable ['cc_debug', false]) && (_target == _this)"
      ]);
    } forEach _debugActions;
  } forEach CC__modules;

  // store user actions
  _unit setVariable ["cc_debug_actions", _actions];
};

/**
 * Disable the debug interface for a player unit.
 *
 * @param 0 player unit
 */
CC_Module_debug_disable = {
  // retrieve parameters
  params [
    ["_unit", player, [objNull]]
  ];

  // disable the interface on the local client
  [_unit] remoteExec ["CC__module_debug_disable_local", _unit, false];
};

/**
 * Disable the debug interface for a local unit.
 *
 * @param 0 local unit
 */
CC__module_debug_disable_local = {
  // retrieve parameters
  params [
    ["_unit", objNull, [objNull]]
  ];

  // verify the interface is enabled
  if (!(_unit getVariable ["cc_debug", false])) exitWith {
    [
      "debug",
      "disable_local",
      "not enabled for unit: %1",
      [_unit]
    ] call CC_Module_debug;
  };

  // remove user actions
  {
    _unit removeAction _x;
  } forEach (_unit getVariable ["cc_debug_actions", []]);

  // variables
  _unit setVariable ["cc_debug_actions", []];
  _unit setVariable ["cc_debug_hud", false];
  _unit setVariable ["cc_debug", false];
};

/**
 * Debug user action to toggle the status HUD.
 */
CC__module_debug_toggle_hud = {
  // toggle the status hud
  private "_enabled";
  _enabled = !(player getVariable "cc_debug_hud");
  player setVariable ["cc_debug_hud", _enabled];

  // start the hud process if necessary
  if (_enabled) then {
    0 = [] spawn CC__module_debug_hud_local;
  };
};

/**
 * Display player and module debugging information using screen hints. This is
 * a task that needs to be spawned locally and will run until it's disabled
 * through a user action or when the debug interface is disabled entirely.
 */
CC__module_debug_hud_local = {
  // display debugging information
  private "_msg";
  waitUntil {
    // current fps and time
    _msg = format [
      "FPS: %1\nTime: %2\n------------------------\n",
      round(diag_fps),
      round(time)
    ];

    // determine the target unit to display information about
    private "_target";
    _target = cursorObject;
    if (isNull _target) then {
      _target = player;
    };

    // target information
    private ["_targetConfig", "_targetPos"];
    _targetConfig = (configFile >> "CfgVehicles" >> typeOf _target);
    _targetPos = getPosATL _target;

    _msg = _msg + format [
      "%1 (%2)\n%3\n(X, Y): %4, %5\nZ: %6\n",
      _target,
      rating _target,
      getText (_targetConfig >> "displayName"),
      (round (100 * (_targetPos select 0))) / 100,
      (round (100 * (_targetPos select 1))) / 100,
      (round (100 * (_targetPos select 2))) / 100
    ];

    // display module status
    {
      // retrieve the status callback
      private ["_name", "_settings", "_debugStatus"];
      _name = _x select 0;
      _settings = _x select 1;
      _debugStatus = _settings select 2;

      // display the module status if available
      private "_status";
      _status = [] call _debugStatus;

      if (_status != "") then {
        _msg = _msg + format [
          "------------------------\n>> %1\n%2\n",
          _name,
          _status
        ];
      };
    } forEach CC__modules;

    // display the HUD content
    hintSilent _msg;

    // run while debug mode is enabled and the status hud is enabled
    !(player getVariable "cc_debug") || !(player getVariable "cc_debug_hud");
  };

  // clear the screen
  hintSilent "";
};
