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
      ["Start Recording", CC__convoy_record_start],
      ["Stop Recording", CC__convoy_record_stop]
    ]
  ] call CC_Module_init;
};

/**************************************
 * Debug Interface                    *
 **************************************/

CC__convoy_debug_status = {
  private ["_status", "_vehicle"];
  _status = [];

  _vehicle = vehicle player;
  if (_vehicle getVariable ["cc_convoy_record", false]) then {
    private "_points";
    _points = _vehicle getVariable ["cc_convoy_points", []];
    _status pushBack (format ["RECORDING (%1)", count _points]);
  };

  _status joinString "\n";
};

CC__convoy_record_start = {
  private ["_vehicle"];
  _vehicle = vehicle player;

  if (_vehicle getVariable ["cc_convoy_record", false]) exitWith {
    ["convoy", "record_start", "already recording: %1", [_vehicle]] call CC_Module_debug;
  };

  _vehicle setVariable ["cc_convoy_record", true];
  _vehicle setVariable ["cc_convoy_data", []];
  [_vehicle] spawn CC__convoy_record_task;
};

CC__convoy_record_stop = {
  private ["_vehicle"];
  _vehicle = vehicle player;

  _vehicle setVariable ["cc_convoy_record", nil];
};

CC__convoy_record_task = {
  params [
    ["_vehicle", objNull, [objNull]],
    ["_maxDistance", 2, [1]],
    ["_maxTime", 2, [1]]
  ];

  ["convoy", "record_task", "%1: start", [_vehicle]] call CC_Module_debug;

  // record start point
  private ["_startTime", "_lastTime", "_lastPoint", "_points"];
  _startTime = time;
  _lastTime = _startTime;
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

    // rate limit
    sleep 0.5;
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

  // save recorded points
  ["convoy", "record_task", "%1: stop", [_vehicle]] call CC_Module_debug;
};

/**************************************
 * Public Interface                   *
 **************************************/

// TODO: create, remove, start, stop, status
