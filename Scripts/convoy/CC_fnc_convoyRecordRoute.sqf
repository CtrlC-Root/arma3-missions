params [
  ["_vehicle", objNull, [objNull]],
  ["_maxDistance", 2, [1]],
  ["_maxTime", 2, [1]]
];

// validate parameters
if (isNull _vehicle) exitWith {
  ["vehicle is null"] call BIS_fnc_error;
};

// prevent the function from being called
private _check = _vehicle getVariable "cc_convoy_record";
if (!(isNil "_check")) exitWith {
  ["vehicle cc_convoy_record variable present"] call BIS_fnc_error;
};

// add vehicle actions
private _actions = [
  _vehicle,
  "CONVOY",
  [
    ["showWindow", false],
    ["condition", "((vehicle _this) == _originalTarget)"]
  ],
  [
    [
      ["title", "Start Recording"],
      ["script", {
        params ["_target", "_caller", "_actionId", "_args"];
        _target setVariable ["cc_convoy_record", true];
      }],
      ["condition", "!(_originalTarget getVariable ['cc_convoy_record', false])"]
    ],
    [
      ["title", "Stop Recording"],
      ["script", {
        params ["_target", "_caller", "_actionId", "_args"];
        _target setVariable ["cc_convoy_record", false];
      }],
      ["condition", "(_originalTarget getVariable ['cc_convoy_record', false])"]
    ]
  ]
] call CC_fnc_addActions;

// set initial vehicle variables
_vehicle setVariable ["cc_convoy_record", false];
_vehicle setVariable ["cc_convoy_actions", _actions];

// spawn a task to record the route and return it's task ID
[_vehicle, _maxDistance, _maxTime] spawn {
  params ["_vehicle", "_maxDistance", "_maxTime"];

  // wait until we're asked to start recording points
  waitUntil {
    sleep 0.1;
    _vehicle getVariable ["cc_convoy_record", false];
  };

  // initialize route
  private _lastTime = time;
  private _lastPosition = position _vehicle;
  private _route = [[0, 0, _lastPosition, 0]];

  // record points until asked to stop
  while { _vehicle getVariable ["cc_convoy_record", false] } do {
    // sample the current time and vehicle position
    private _currentTime = time;
    private _currentPosition = position _vehicle;

    // calculate elapsed time and distance traveled since the last route point
    private _timeSinceLast = _currentTime - _lastTime;
    private _distanceFromLast = _lastPosition distance _currentPosition;

    // check if we need to record another point
    if ((_timeSinceLast >= _maxTime) || (_distanceFromLast >= _maxDistance)) then {
      // update our running state
      _lastTime = _currentTime;
      _lastPosition = _currentPosition;

      // record the point
      _route pushBack [
        _timeSinceLast,
        _distanceFromLast,
        _lastPosition,
        (speed _vehicle) * (1000 / (60 * 60))
      ];
    };

    // rate limit to 20 Hz
    sleep (1.0 / 20.0);
  };

  // save the recorded route in the vehicle
  _vehicle setVariable ["cc_convoy_route", _route];

  // remove vehicle actions
  {
    _vehicle removeAction _x;
  } forEach (_vehicle getVariable "cc_convoy_actions");

  // clear vehicle variables
  _vehicle setVariable ["cc_convoy_actions", nil];
  _vehicle setVariable ["cc_convoy_record", nil];
};
