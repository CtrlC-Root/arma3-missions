/******************************************************************************
 * Manage convoys of vehicles along pre-determined paths.                     *
 ******************************************************************************/

CC_Convoy_init = {
  [
    "convoy",
    [
      "start",
      "stop"
    ],
    CC__convoy_debug_status,
    [
      ["Toggle Recording", CC__convoy_record_toggle]
    ]
  ] call CC_Module_init;
};

/**************************************
 * Debug Interface                    *
 **************************************/

CC__convoy_debug_status = {
  private "_status";
  _status = [];

  if (player getVariable ["cc_convoy_record", false]) then {
    _status pushBack "Recording Enabled";
  } else {
    _status pushBack "Recording Disabled"
  };

  if ((vehicle player) != player) then {
    private ["_vehicle", "_points"];
    _vehicle = vehicle player;
    _points = _vehicle getVariable ["cc_convoy_points", []];

    if (_vehicle getVariable ["cc_convoy_record", false]) then {
      _status pushBack format ["Vehicle: Recording (%1)", count _points];
    } else {
      if ((count _points) > 0) then {
        _status pushBack format ["Vehicle: Stored (%1)", count _points];
      } else {
        _status pushBack "Vehicle: Idle";
      };
    };
  } else {
    _status pushBack "Vehicle: N/A";
  };

  _status joinString "\n";
};

CC__convoy_record_toggle = {
  // check if recording is enabled
  if (player getVariable ["cc_convoy_record", false]) exitWith {
    // debug
    ["convoy", "record_toggle", "disable"] call CC_Module_debug;

    // stop any active recording
    if ((vehicle player) != player) then {
      [vehicle player, false] call CC__convoy_record_control;
    };

    // remove enter and exit event handlers
    private "_handler";
    _handler = player getVariable "cc_convoy_enter_handler";
    player removeEventHandler ["GetInMan", _handler];

    _handler = player getVariable "cc_convoy_exit_handler";
    player removeEventHandler ["GetOutMan", _handler];

    // clear player variables
    player setVariable ["cc_convoy_enter_handler", nil];
    player setVariable ["cc_convoy_exit_handler", nil];
    player setVariable ["cc_convoy_record", nil];
  };

  // debug
  ["convoy", "record_toggle", "enable"] call CC_Module_debug;

  // register event handlers for entering and exiting cars
  private ["_enterHandler", "_exitHandler"];
  _enterHandler = player addEventHandler ["GetInMan", {
    params ["_unit", "_role", "_vehicle", "_turret"];
    private "_handler";
    _handler = _vehicle addEventHandler ["Engine", {
      _this call CC__convoy_record_control;
    }];

    _vehicle setVariable ["cc_convoy_handler", _handler];
  }];

  _exitHandler = player addEventHandler ["GetOutMan", {
    params ["_unit", "_role", "_vehicle", "_turret"];
    [_vehicle, false] call CC__convoy_record_control;

    private "_handler";
    _handler = _vehicle getVariable "cc_convoy_handler";
    _vehicle setVariable ["cc_convoy_handler", nil];
    _vehicle removeEventHandler ["Engine", _handler];
  }];

  // set player variables
  player setVariable ["cc_convoy_record", true];
  player setVariable ["cc_convoy_enter_handler", _enterHandler];
  player setVariable ["cc_convoy_exit_handler", _exitHandler];
};

CC__convoy_record_control = {
  params [
    ["_vehicle", objNull, [objNull]],
    ["_active", false, [false]]
  ];

  if (_active) then {
    ["convoy", "record_control", "%1 start", [_vehicle]] call CC_Module_debug;
    _vehicle setVariable ["cc_convoy_record", true];
    _vehicle setVariable ["cc_convoy_points", []];
    [_vehicle] spawn CC__convoy_record_task;
  } else {
    ["convoy", "record_control", "%1 stop", [_vehicle]] call CC_Module_debug;
    _vehicle setVariable ["cc_convoy_record", nil];
  };
};

CC__convoy_record_task = {
  params [
    ["_vehicle", objNull, [objNull]],
    ["_maxDistance", 2, [1]],
    ["_maxTime", 2, [1]]
  ];

  // debug
  ["convoy", "record_task", "%1: start", [_vehicle]] call CC_Module_debug;

  // record start point
  private ["_lastTime", "_lastPoint", "_points"];
  _lastTime = time;
  _lastPoint = position _vehicle;

  _points = [[0, 0, _lastPoint, 0]];
  _vehicle setVariable ["cc_convoy_points", _points];

  // record points as the player drives
  private ["_timeSinceLast", "_distanceFromLast"];
  while { _vehicle getVariable ["cc_convoy_record", false] } do {
    _timeSinceLast = time - _lastTime;
    _distanceFromLast = _lastPoint distance (position _vehicle);

    // check if we've traveled far enough to
    if ((_timeSinceLast >= _maxTime) || (_distanceFromLast >= _maxDistance)) then {
      // record a new point
      _lastTime = time;
      _lastPoint = position _vehicle;

      _points pushBack [
        _timeSinceLast,
        _distanceFromLast,
        _lastPoint,
        (speed _vehicle) * (1000 / (60 * 60))
      ];

      _vehicle setVariable ["cc_convoy_points", _points];
    };

    // rate limit to 20 Hz
    sleep (1.0 / 20.0);
  };

  // record stop point
  _timeSinceLast = time - _lastTime;
  _distanceFromLast = _lastPoint distance (position _vehicle);
  _lastPoint = position _vehicle;

  _points pushBack [
    _timeSinceLast,
    _distanceFromLast,
    _lastPoint,
    0
  ];

  _vehicle setVariable ["cc_convoy_points", _points];

  // debug
  ["convoy", "record_task", "%1: stop", [_vehicle]] call CC_Module_debug;
};

/**************************************
 * Public Interface                   *
 **************************************/

// TODO
