CC_Scenario_init = {
  [
    "scenario",
    CC__scenario_server_init,
    CC__scenario_client_init
  ] call CC_Module_init;
};

CC__scenario_server_init = {
  // determine which units are critical to the story by sorting the fire team
  // units in order of rank players first followed by NPCs and picking in order
  private "_units";
  _units = [
    units groupNatoFireTeam,
    [],
    { if (isPlayer _x) then { (rankId _x) + 10; } else { rankId _x; } },
    "DESCEND"
  ] call BIS_fnc_sortBy;

  CC__scenario_story_vehicles = [vehicleNatoLead, vehicleNatoChase];
  publicVariable "CC__scenario_story_vehicles";

  CC__scenario_story_units = _units select [0, 2];
  publicVariable "CC__scenario_story_units";

  // initialize scenario state (updated by FSM as mission progresses)
  CC__scenario_state = "start";
  publicVariable "CC__scenario_state";

  // settings
  [
    [
      "fsm_intro",
      "fsm_ambush",
      "fsm_pivot",
      "fsm_search",
      "fsm_rescue",
      "fsm_nato_win",
      "fsm_syndikat_win"
    ],
    { False },
    CC__scenario_debug_status,
    []
  ];
};

CC__scenario_client_init = {
  // client settings
  if (!isServer) exitWith { };

  // run the scenario state machine
  CC__scenario_fsm = [
    CC__scenario_fsm_state,
    CC__scenario_story_units
  ] execFSM "local\scenario.fsm";

  // register server event handlers
  ["scenario", "fsm_intro", CC__scenario_fsm_intro] call CC_Module_event_register;
  ["scenario", "fsm_ambush", CC__scenario_fsm_ambush] call CC_Module_event_register;
  ["scenario", "fsm_pivot", CC__scenario_fsm_pivot] call CC_Module_event_register;
  ["scenario", "fsm_pivot", CC__scenario_fsm_pivot] call CC_Module_event_register;
  ["scenario", "fsm_search", CC__scenario_fsm_search] call CC_Module_event_register;
  ["scenario", "fsm_rescue", CC__scenario_fsm_rescue] call CC_Module_event_register;
  ["scenario", "fsm_nato_win", CC__scenario_fsm_nato_win] call CC_Module_event_register;
  ["scenario", "fsm_syndikat_win", CC__scenario_fsm_syndikat_win] call CC_Module_event_register;
};

CC__scenario_debug_status = {
  format [
    "FSM: %1",
    CC__scenario_state
  ];
};

CC__scenario_fsm_state = {
  // only run on the server
  if (!isServer) exitWith {
    ["scenario", "fsm_state", "not called on server"] call CC_Module_debug;
  };

  // retrieve parameters
  params [
    ["_state", "", [""]]
  ];

  // debug
  ["scenario", "fsm_state", "%1", [_state]] call CC_Module_debug;

  // update the scenario state
  CC__scenario_state = _state;
  publicVariable "CC__scenario_state";

  // run event handlers
  ["scenario", format ["fsm_%1", _state], [], true] call CC_Module_event_fire;
};

CC__scenario_fsm_intro = {
  // TODO
};

CC__scenario_fsm_ambush = {
  // TODO
};

CC__scenario_fsm_pivot = {
  // TODO
};

CC__scenario_fsm_search = {
  // TODO
};

CC__scenario_fsm_rescue = {
  // TODO
};

CC__scenario_fsm_nato_win = {
  // TODO
};

CC__scenario_fsm_syndikat_win = {
  // TODO
};

CC__scenario_convoy_setup = {
  private ["_followDistance", "_vehicles", "_route"];
  _followDistance = 12;
  _vehicles = CC__scenario_story_vehicles;
  _route = CC__scenario_nato_route apply {
    // [t, d, [x, y, z], s]
    _x set [3, 12];
    _x;
  };

  // initialize vehicle crew and route
  {
    {
      switch (toLower ((assignedVehicleRole _x) select 0)) do {
        case "driver";
        case "turret": {
          // disable targeting and switching to combat behavior
          _x disableAI "TARGET";
          _x disableAI "AUTOCOMBAT";

          // set the unit's group behavior
          (group _x) setBehaviour "CARELESS";
        };
      };
    } forEach (crew _x);

    // determine the start and stop offsets
    private ["_startOffset", "_stopOffset"];
    _startOffset = _followDistance * ((count _vehicles) - _forEachIndex - 1);
    _stopOffset = _followDistance * _forEachIndex;

    // create a copy of the route for this vehicle
    private "_localRoute";
    _localRoute = [] + _route;

    // remove points from the beginning based on the start offset
    private ["_entry", "_distanceFromLast"];
    while { _startOffset > 0 } do {
      _entry = [_localRoute] call BIS_fnc_arrayShift;
      _distanceFromLast = _entry select 1;
      _startOffset = _startOffset - _distanceFromLast;
    };

    // remove points from the end based on the stop offset
    while { _stopOffset > 0 } do {
      _entry = _localRoute call BIS_fnc_arrayPop;
      _distanceFromLast = _entry select 1;
      _stopOffset = _stopOffset - _distanceFromLast;
    };

    // override speed for last point to convince vehicles to stop
    _entry = _localRoute call BIS_fnc_arrayPop;
    _entry set [3, 0];  // [t, d, [x, y, z], s]
    _localRoute pushBack _entry;

    // store the route in the vehicle
    private "_localPoints";
    _localPoints = _localRoute apply {
      private ["_p", "_s"];
      _p = _x select 2;
      _s = _x select 3;

      // [x, y, z, s]
      _p + [_s];
    };

    // XXX
    _x setVariable ["cc_convoy_route", _localRoute];
    _x setVariable ["cc_convoy_points", _localPoints];
  } forEach _vehicles;

  // stage vehicles
  {
    ["scenario", "convoy_start", "stage: %1", [_x]] call CC_Module_debug;
    private ["_localRoute", "_group", "_waypoint"];
    _localRoute = (_x getVariable "cc_convoy_route");
    _group = group (driver _x);

    _entry = _localRoute select 0;
    _waypoint = _group addWaypoint [_entry select 2, -1];
    _waypoint setWaypointType "MOVE";
    _waypoint setWaypointStatements [
      "(speed (vehicle this)) <= 0.01",
      "(vehicle this) setVariable ['cc_convoy_wp', 'start']"
    ];

    waitUntil { (_x getVariable ["cc_convoy_wp", ""]) == "start" };
  } forEach _vehicles;

  // start vehicles
  {
    ["scenario", "convoy_setup", "start: %1", [_x]] call CC_Module_debug;
    private ["_localRoute", "_group", "_waypoint"];
    _localRoute = (_x getVariable "cc_convoy_route");
    _group = group (driver _x);

    _entry = _localRoute select ((count _localRoute) - 1);
    _waypoint = _group addWaypoint [_entry select 2, -1];
    _waypoint setWaypointType "MOVE";
    _waypoint setWaypointStatements [
      "(speed (vehicle this)) <= 0.01",
      format ["hint '%1'", _x]
    ];

    //_x limitSpeed 60;
    _x setDriveOnPath (_x getVariable "cc_convoy_points");
  } forEach _vehicles;
};

CC__scenario_convoy_show = {
  private ["_vehicle", "_route"];
  _vehicle = _this select 0;
  _route = _vehicle getVariable "cc_convoy_route";

  // create first point
  private ["_entry", "_objects"];
  _entry = [_route] call BIS_fnc_arrayShift;
  "VR_3DSelector_01_complete_F" createVehicle (_entry select 2);

  // create middle points
  while { (count _route) > 2 } do {
    _entry = [_route] call BIS_fnc_arrayShift;
    "VR_3DSelector_01_default_F" createVehicle (_entry select 2);
  };

  // create final point
  _entry = _route call BIS_fnc_arrayPop;
  "VR_3DSelector_01_incomplete_F" createVehicle (_entry select 2);
};
