/*****************************************************************************
 * Module support.                                                           *
 *****************************************************************************/

/**
 * Initialize a module. This method should be called at the beginning of
 * all module init methods.
 *
 * @locality global
 * @param 0 module name
 * @param 1 event names
 * @param 2 block that returns module status as string
 * @Param 3 kv array of debug action names and handlers
 */
CC_Module_init = {
  // retrieve parameters
  private ["_name", "_debug", "_events"];
  _name = [_this, 0, "", [""]] call BIS_fnc_param;
  _events = [_this, 1, [], [[]]] call BIS_fnc_param;
  _debugStatus = [_this, 2, {""}, [{}]] call BIS_fnc_param;
  _debugActions = [_this, 3, [], [[]]] call BIS_fnc_param;

  // validate module name
  if (_name == "") exitWith {
    ["Module", "init", "empty module name"] call CC_Module_debug;
  };

  // create the module list if it doesn't already exist
  if (isNil "CC__modules") then {
    CC__modules = [];
  };

  // debug
  ["Module", "init", "%1", [_name]] call CC_Module_debug;

  // check if the module is already initialized
  private "_moduleIndex";
  _moduleIndex = [CC__modules, _name] call BIS_fnc_findInPairs;

  if (_moduleIndex >= 0) exitWith {
    ["Module", "init", "already initialized"] call CC_Module_debug;
  };

  // create initial module events
  private "_eventHandlers";
  _eventHandlers = [];

  {
    _eventHandlers pushBack [_x, []];
  } forEach _events;

  // keep track of the module
  [
    CC__modules,
    _name,
    [_eventHandlers, _debugStatus, _debugActions]
  ] call BIS_fnc_setToPairs;

  // update clients
  publicVariable "CC__modules";
};

/**
 * Get loaded modules.
 *
 * @locality local
 * @returns list of loaded module names
 */
CC_Module_loaded = {
  private "_loaded";
  _loaded = [];

  // corner case: no loaded modules
  if (isNil "CC__modules") exitWith { _loaded };

  // retrieve module names
  {
    _loaded pushBack (_x select 0);
  } forEach CC__modules;

  // return module names
  _loaded;
};

/**
 * Get module events.
 *
 * @locality local
 * @param 0 module name
 * @returns array of event names
 */
CC_Module_events = {
  // retrieve parameters
  private "_name";
  _name = [_this, 0, "", [""]] call BIS_fnc_param;

  // validate parameters
  if (_name == "") exitWith {
    ["Module", "events", "missing module name"] call CC_Module_debug;
  };

  // retrieve the module
  private "_moduleIndex";
  _moduleIndex = [CC__modules, _name] call BIS_fnc_findInPairs;

  if (_moduleIndex < 0) exitWith {
    ["Module", "events", "no module %1", [_name]] call CC_Module_debug;
  };

  private "_module";
  _module = (CC__modules select _moduleIndex) select 1;

  // return the event names
  private "_events";
  _events = [];

  {
    _events pushBack (_x select 0);
  } forEach (_module select 0);

  _events;
};

/**
 * Add a module event.
 *
 * @locality global
 * @param 0 module name
 * @param 1 event name
 */
CC_Module_event_add = {
  // retrieve parameters
  private ["_name", "_event"];
  _name = [_this, 0, "", [""]] call BIS_fnc_param;
  _event = [_this, 1, "", [""]] call BIS_fnc_param;

  // validate parameters
  if (_name == "") exitWith {
    ["Module", "event add", "missing module name"] call CC_Module_debug;
  };

  if (_event == "") exitWith {
    ["Module", "event add", "missing event name"] call CC_Module_debug;
  };

  // debug
  ["Module", "event add", "%1, %2", [_name, _event]] call CC_Module_debug;

  // retrieve the module data
  private "_moduleIndex";
  _moduleIndex = [CC__modules, _name] call BIS_fnc_findInPairs;

  if (_moduleIndex < 0) exitWith {
    ["Module", "event add", "no module %1", [_name]] call CC_Module_debug;
  };

  private "_module";
  _module = (CC__modules select _moduleIndex) select 1;

  // check if the event already exists
  private ["_eventHandlers", "_eventIndex"];
  _eventHandlers = _module select 0;
  _eventIndex = [_eventHandlers, _event] call BIS_fnc_findInPairs;

  if (_eventIndex >= 0) exitWith {
    ["Module", "event add", "event %1 already exists", [_event]] call CC_Module_debug;
  };

  // add the new event
  _eventHandlers pushBack [_event, []];

  // update clients
  publicVariable "CC__modules";
};

/**
 * Remove a module event.
 *
 * @locality global
 * @param 0 module name
 * @param 1 event name
 */
CC_Module_event_remove = {
  // retrieve parameters
  private ["_name", "_event"];
  _name = [_this, 0, "", [""]] call BIS_fnc_param;
  _event = [_this, 1, "", [""]] call BIS_fnc_param;

  // validate parameters
  if (_name == "") exitWith {
    ["Module", "event add", "missing module name"] call CC_Module_debug;
  };

  if (_event == "") exitWith {
    ["Module", "event add", "missing event name"] call CC_Module_debug;
  };

  // debug
  ["Module", "event remove", "%1, %2", [_name, _event]] call CC_Module_debug;

  // retrieve the module data
  private "_moduleIndex";
  _moduleIndex = [CC__modules, _name] call BIS_fnc_findInPairs;

  if (_moduleIndex < 0) exitWith {
    ["Module", "event add", "no module %1", [_name]] call CC_Module_debug;
  };

  private "_module";
  _module = (CC__modules select _moduleIndex) select 1;

  // remove the event
  private "_eventHandlers";
  _eventHandlers = _module select 0;
  [_eventHandlers, _event] call BIS_fnc_removeFromPairs;

  // update clients
  publicVariable "CC__modules";
};

/**
 * Add an event handler for a module event.
 *
 * @locality global
 * @param 0 module name
 * @param 1 event name
 * @param 2 event handler
 */
CC_Module_event_register = {
  // retrieve parameters
  private ["_name", "_event", "_handler"];
  _name = [_this, 0, "", [""]] call BIS_fnc_param;
  _event = [_this, 1, "", [""]] call BIS_fnc_param;
  _handler = [_this, 2, {}, [{}]] call BIS_fnc_param;

  // validate parameters
  if (_name == "") exitWith {
    ["Module", "event register", "missing module name"] call CC_Module_debug;
  };

  if (_event == "") exitWith {
    ["Module", "event register", "missing event name"] call CC_Module_debug;
  };

  // retrieve the module
  private "_moduleIndex";
  _moduleIndex = [CC__modules, _name] call BIS_fnc_findInPairs;

  if (_moduleIndex < 0) exitWith {
    ["Module", "event register", "no module %1", [_name]] call CC_Module_debug;
  };

  private "_module";
  _module = (CC__modules select _moduleIndex) select 1;

  // retrieve the event
  private ["_events", "_eventIndex"];
  _events = _module select 0;
  _eventIndex = [_events, _event] call BIS_fnc_findInPairs;

  if (_eventIndex < 0) exitWith {
    [
      "Module",
      "event register",
      "module %1 has no event %2",
      [_name, _event]
    ] call CC_Module_debug;
  };

  private "_event";
  _event = _events select _eventIndex;

  // add the event handler to the list
  (_event select 1) pushBack _handler;

  // update clients
  publicVariable "CC__modules";
};

/**
 * Run event handlers for a module event.
 *
 * @locality local
 * @param 0 module name
 * @param 1 event name
 * @param 2 event handler arguments, defaults to []
 * @param 3 run handlers asynchronously, defaults to true
 * @returns array of script handles in asynchronous mode, otherwise array
 *          of event handler results
 */
CC_Module_event_fire = {
  // retrieve parameters
  private ["_name", "_event", "_args", "_async"];
  _name = [_this, 0, "", [""]] call BIS_fnc_param;
  _event = [_this, 1, "", [""]] call BIS_fnc_param;
  _args = [_this, 2, [], [[]]] call BIS_fnc_param;
  _async = [_this, 3, true, [true]] call BIS_fnc_param;

  // validate parameters
  if (_name == "") exitWith {
    ["Module", "event fire", "missing module name"] call CC_Module_debug;
  };

  if (_event == "") exitWith {
    ["Module", "event fire", "missing event name"] call CC_Module_debug;
  };

  // retrieve the module
  private "_moduleIndex";
  _moduleIndex = [CC__modules, _name] call BIS_fnc_findInPairs;

  if (_moduleIndex < 0) exitWith {
    ["Module", "event fire", "no module %1", [_name]] call CC_Module_debug;
  };

  private "_module";
  _module = (CC__modules select _moduleIndex) select 1;

  // retrieve the event
  private ["_events", "_eventIndex"];
  _events = _module select 0;
  _eventIndex = [_events, _event] call BIS_fnc_findInPairs;

  if (_eventIndex < 0) exitWith {
    [
      "Module",
      "event fire",
      "module %1 has no event %2",
      [_name, _event]
    ] call CC_Module_debug;
  };

  private "_event";
  _event = _events select _eventIndex;

  // retrieve the event handlers
  private "_handlers";
  _handlers = _event select 1;

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
  private ["_module", "_part", "_msg", "_args"];
  _module = [_this, 0, "", [""]] call BIS_fnc_param;
  _part = [_this, 1, "", [""]] call BIS_fnc_param;
  _msg = [_this, 2, "", [""]] call BIS_fnc_param;
  _args = [_this, 3, [], [[]]] call BIS_fnc_param;

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
 * Enable the debug interface for a player.
 *
 * @locality global
 * @param 0 player unit
 */
CC_Module_debug_enable = {
  // retrieve parameters
  private "_unit";
  _unit = [_this, 0, player, [objNull]] call BIS_fnc_param;

  // corner case: function called with default arguments on server so player is objNull
  // XXX: this seems to avoid the problem but the message below is never written to the log?
  if (isNull _unit) exitWith {
    ["module", "debug enable", "ignoring call on dedicated server"] call CC_Module_debug;
  };

  // verify the unit is a player
  private "_players";
  _players = ([] call BIS_fnc_listPlayers) - (entities "HeadlessClient_F");

  if (!(_unit in _players)) exitWith {
    ["module", "debug player enable", "%1 not a player", [_unit]] call CC_Module_debug;
  };

  // verify the unit doesn't already have the interface enabled
  if (_unit getVariable ["cc_debug", false]) exitWith {
    ["module", "debug enable", "%1 already enabled", [_unit]] call CC_Module_debug;
  };

  // enable the player locally
  [_unit] remoteExec ["CC__module_debug_enable_local", _unit, false];
};

/**
 * Enable the debug interface for a local player.
 *
 * @locality local
 * @param 0 player unit
 */
CC__module_debug_enable_local = {
  // retrieve parameters
  private "_unit";
  _unit = _this select 0;

  // variables
  _unit setVariable ["cc_debug", true, true];
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
    private ["_name", "_settings", "_debugActions"];
    _name = _x select 0;
    _settings = _x select 1;
    _debugActions = _settings select 2;

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
 * Disable the debug interface for a player.
 *
 * @locality global
 * @param 0 player unit
 */
CC_Module_debug_disable = {
  // retrieve parameters
  private "_unit";
  _unit = [_this, 0, player, [objNull]] call BIS_fnc_param;

  // verify the unit has the interface enabled
  if (!(_unit getVariable ["cc_debug", false])) exitWith {
    ["Module", "debug player disable", "%1 already disabled", [_unit]] call CC_Module_debug;
  };

  // disable the player locally
  [_unit] remoteExec ["CC__module_debug_disable_local", _unit, false];
};

/**
 * Disable the debug interface for a local player.
 *
 * @locality local
 * @param 0 player unit
 */
CC__module_debug_disable_local = {
  // retrieve parameters
  private "_unit";
  _unit = _this select 0;

  // remove user actions
  {
    _unit removeAction _x;
  } forEach (_unit getVariable ["cc_debug_actions", []]);

  // variables
  _unit setVariable ["cc_debug_actions", []];
  _unit setVariable ["cc_debug_hud", false];
  _unit setVariable ["cc_debug", false, true];
};

/**
 * Debug user action to toggle the status HUD.
 *
 * @locality local
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
 *
 * @locality local
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
      _debugStatus = _settings select 1;

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
