CC_debug_init = {
  [
    "debug",
    CC__debug_serverInit,
    CC__debug_clientInit
  ] call CC_fnc_moduleInit;
};

CC__debug_serverInit = {
  // settings
  [
    [],
    { false; },
    { ""; }
  ];
};

CC__debug_clientInit = {
  // TODO: anything?
};

CC_debug_config = {
  params [
    ["_unit", player, [objNull]],
    ["_state", true, [true]]
  ];

  if (isNull _unit) exitWith {
    ["unit is null"] call BIS_fnc_error;
  };

  // verify the unit is a player
  private _players = ([] call BIS_fnc_listPlayers) - (entities "HeadlessClient_F");
  if (!(_unit in _players)) exitWith {
    ["unit not a player: %1", _unit] call BIS_fnc_error;
  };

  // configure the unit locally
  if (_state) then {
    [] remoteExec ["CC__debug_enable_local", _unit, false];
  }
  else {
    [] remoteExec ["CC__debug_disable_local", _unit, false];
  };
};

CC__debug_enable_local = {
  // verify the interface is disabled
  if (player getVariable ["cc_debug", false]) exitWith {
    ["debug interface is already enabled"] call BIS_fnc_error;
  };

  // variables
  player setVariable ["cc_debug", true];
  player setVariable ["cc_debug_hud", false];

  // add user actions
  private _actions = [player addAction [
    "DEBUG: Toggle Status HUD",
    CC__debug_toggle_hud,
    [],
    100,
    false,
    true,
    "",
    "(_originalTarget getVariable ['cc_debug', false]) && (_originalTarget == _this)"
  ]];

  // store user actions
  player setVariable ["cc_debug_actions", _actions];
};

CC__debug_disable_local = {
  // verify the interface is enabled
  if (!(player getVariable ["cc_debug", false])) exitWith {
    ["debug interface is already disabled"] call BIS_fnc_error;
  };

  // remove user actions
  {
    player removeAction _x;
  } forEach (player getVariable ["cc_debug_actions", []]);

  // clear variables
  player setVariable ["cc_debug_actions", nil];
  player setVariable ["cc_debug_hud", nil];
  player setVariable ["cc_debug", nil];
};

CC__debug_toggle_hud = {
  // verify the interface is enabled
  if (!(player getVariable ["cc_debug", false])) exitWith {
    ["debug interface is not enabled"] call BIS_fnc_error;
  };

  // toggle the hud
  private _enabled = !(player getVariable "cc_debug_hud");
  player setVariable ["cc_debug_hud", _enabled];

  // start the hud task if necessary
  if (_enabled) then {
    0 = [] spawn CC__debug_task_hud;
  };
};

CC__debug_task_hud = {
  // display debugging information
  waitUntil {
    // current fps and time
    private _msg = format [
      "FPS: %1\nTime: %2\n------------------------\n",
      round(diag_fps),
      round(time)
    ];

    // determine the target unit to display information about
    private _target = cursorObject;
    if (isNull _target) then {
      _target = player;
    };

    // target information
    private _targetConfig = (configFile >> "CfgVehicles" >> typeOf _target);
    private _targetPos = getPosATL _target;

    _msg = _msg + format [
      "%1 (%2)\n%3\n(X, Y): %4, %5\nZ: %6\n",
      _target,
      rating _target,
      getText (_targetConfig >> "displayName"),
      [_targetPos select 0] call CC_fnc_mathRound,
      [_targetPos select 1] call CC_fnc_mathRound,
      [_targetPos select 2] call CC_fnc_mathRound
    ];

    // display module status
    {
      // retrieve the status callback
      private _name = _x select 0;
      private _settings = _x select 1;
      private _statusTask = _settings select 2;

      // display the module status if available
      private _status = [] call _statusTask;
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
