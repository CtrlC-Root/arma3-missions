/*
Civilian Panic Animation?

unitCivilian playMoveNow "ApanPknlMstpSnonWnonDnon_G01";
unitCivilian disableAI "MOVE";
unitCivilian disableAI "ANIM";

unitCivilian playMoveNow "ApanPknlMstpSnonWnonDnon";
unitCivilian playMove "ApanPercMstpSnonWnonDnon";
unitCivilian playMove "AmovPercMstpSnonWnonDnon";
unitCivilian enableAI "MOVE";
unitCivilian enableAI "ANIM";

animationState unitCivilian;
*/

CC_Scenario_init = {
  [
    "scenario",
    CC__scenario_server_init,
    CC__scenario_client_init
  ] call CC_Module_init;
};

CC__scenario_server_init = {
  // determine nato units and vehicles
  CC__scenario_nato_vehicles = [vehicleNatoLead, vehicleNatoChase];
  publicVariable "CC__scenario_nato_vehicles";

  CC__scenario_nato_units = [unitJamesWright, unitDixonWatson];
  publicVariable "CC__scenario_nato_units";

  // pick one informant unit and remove the rest
  private _informants = allUnits select {
    _x getVariable ["cc_scenario_informant", false];
  };

  _informants = _informants call BIS_fnc_arrayShuffle;
  CC__scenario_informant = _informants call BIS_fnc_arrayPop;
  publicVariable "CC__scenario_informant";

  {
    deleteVehicle _x;
  } forEach _informants;

  // stage the informant and prevent him from running away
  CC__scenario_informant playActionNow "SitDown";
  CC__scenario_informant disableAI "MOVE";
  CC__scenario_informant disableAI "ANIM";

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
      "fsm_exfil",
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

  // register server event handlers
  ["scenario", "fsm_intro", CC__scenario_fsm_intro] call CC_Module_event_register;
  ["scenario", "fsm_ambush", CC__scenario_fsm_ambush] call CC_Module_event_register;
  ["scenario", "fsm_pivot", CC__scenario_fsm_pivot] call CC_Module_event_register;
  ["scenario", "fsm_search", CC__scenario_fsm_search] call CC_Module_event_register;
  ["scenario", "fsm_rescue", CC__scenario_fsm_rescue] call CC_Module_event_register;
  ["scenario", "fsm_exfil", CC__scenario_fsm_exfil] call CC_Module_event_register;
  ["scenario", "fsm_nato_win", CC__scenario_fsm_nato_win] call CC_Module_event_register;
  ["scenario", "fsm_syndikat_win", CC__scenario_fsm_syndikat_win] call CC_Module_event_register;

  // run the scenario state machine
  CC__scenario_fsm = [
    CC__scenario_fsm_state,
    CC__scenario_nato_vehicles,
    CC__scenario_nato_units,
    CC__scenario_informant,
    triggerAmbush,
    triggerTanouka,
    triggerFactory,
    vehicleRescueHeli
  ] execFSM "local\scenario.fsm";
};

CC__scenario_debug_status = {
  format [
    "FSM: %1\nInformant: %2\nNATO Units: %3",
    CC__scenario_state,
    CC__scenario_informant,
    CC__scenario_nato_units
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
  // XXX: start convoy
  [] call CC__scenario_convoy_setup;

  // create the meet informant task
  [
    groupNatoFireTeam,
    "meetInformant",
    ["Meet the informant at the factory.", "Meet Informant", ""],
    getMarkerPos "markerMeetInformant",
    "ASSIGNED",
    2,
    false,
    "meet",
    false
  ] call BIS_fnc_taskCreate;

  // TODO: start radio messages
};

CC__scenario_fsm_ambush = {
  // blow up the car bomb and lead vehicle
  vehicleCarBomb setDamage 1;
  vehicleNatoLead setDamage 1;

  // kill the driver of the chase vehicle
  (driver vehicleNatoChase) setDamage 1;

  // disable the chase vehicle
  private _vehicleClass = typeOf vehicleNatoChase;
  private _enginePart = getText (configFile >> "CfgVehicles" >> _vehicleClass >> "HitPoints" >> "HitEngine" >> "name");
  vehicleNatoChase setHit [_enginePart, 1];

  // enable syndikat units in tanouka
  private _syndikatUnits = allUnits select {
    (faction _x == "IND_C_F") && (_x inArea triggerTanouka)
  };

  {
    _x enableSimulation true;
  } forEach _syndikatUnits;

  // TODO: start radio messages

  // XXX: create defend task (after radio messages)
  [
    groupNatoFireTeam,
    "defendConvoy",
    ["Defend the convoy from attack.", "Defend Convoy", ""],
    position vehicleNatoChase,
    "ASSIGNED",
    10,
    true,
    "defend",
    true
  ] call BIS_fnc_taskCreate;
};

CC__scenario_fsm_pivot = {
  // enable syndikat units at the factory
  private _syndikatUnits = allUnits select {
    (faction _x == "IND_C_F") && (_x inArea triggerFactory)
  };

  {
    _x enableSimulation true;
  } forEach _syndikatUnits;

  // complete defend task
  ["defendConvoy", "SUCCEEDED"] call BIS_fnc_taskSetState;

  // TODO: start radio messages

  // XXX: temporary pause to prevent task alerts from overlapping
  sleep 1;

  // XXX: delete the meet informant task (after radio messages)
  ["meetInformant"] call BIS_fnc_deleteTask;

  // XXX: temporary pause to prevent task alerts from overlapping
  sleep 1;

  // XXX: create search task (after radio messages)
  [
    groupNatoFireTeam,
    "searchFactory",
    ["Search the factory for the informant.", "Locate Informant", ""],
    getMarkerPos "markerSearchFactory",
    "ASSIGNED",
    12,
    true,
    "search",
    true
  ] call BIS_fnc_taskCreate;
};

CC__scenario_fsm_search = {
  // TODO: start radio messages
};

CC__scenario_fsm_rescue = {
  // add the informant to the nato fire team so they can command him, enable
  // movement again, and  tweak some of the annoying civilian behavior
  CC__scenario_informant playActionNow "Stand";
  CC__scenario_informant enableAI "MOVE";
  CC__scenario_informant enableAI "ANIM";
  CC__scenario_informant allowFleeing 0;
  [CC__scenario_informant] join groupNatoFireTeam;  // changes locality

  // complete search task
  ["searchFactory", "SUCCEEDED"] call BIS_fnc_taskSetState;

  // send the rescue helicopter
  missionNamespace setVariable ["CC__scenario_nato_rescue", true];

  // TODO: start radio messages

  // create board transport task (after radio messages)
  [
    groupNatoFireTeam,
    "boardTransport",
    ["Board the rescue helicopter.", "Board Transport", ""],
    position objectRescueHelipad,
    "ASSIGNED",
    14,
    true,
    "getin",
    true
  ] call BIS_fnc_taskCreate;
};

CC__scenario_fsm_exfil = {
  // let the rescue helicopter leave
  missionNamespace setVariable ["CC__scenario_nato_exfil", true];

  // complete the exfil task
  ["boardTransport", "SUCCEEDED"] call BIS_fnc_taskSetState;
};

CC__scenario_fsm_nato_win = {
  // end the mission for all players
  // XXX: how do we end it for spectators?
  private _players = allPlayers - entities "HeadlessClient_F";

  {
    if (faction _x == "BLU_T_F") then {
      ["END1", true] remoteExec ["BIS_fnc_endMission", _x, true];
    } else {
      ["END1", false] remoteExec ["BIS_fnc_endMission", _x, true];
    };
  } forEach _players;
};

CC__scenario_fsm_syndikat_win = {
  // end the mission for all players
  // XXX: how do we end it for spectators?
  private _players = allPlayers - entities "HeadlessClient_F";

  {
    if (faction _x == "IND_C_F") then {
      ["END1", true] remoteExec ["BIS_fnc_endMission", _x, true];
    } else {
      ["END1", false] remoteExec ["BIS_fnc_endMission", _x, true];
    };
  } forEach _players;
};

CC__scenario_convoy_setup = {
  private ["_followDistance", "_vehicles", "_route"];
  _followDistance = 12;
  _vehicles = CC__scenario_nato_vehicles;
  _route = CC__scenario_nato_route apply {
    // [t, d, [x, y, z], s]
    _x set [3, 12];
    _x;
  };

  // initialize vehicle crew and route
  {
    // set group behavior to careless so they follow roads and use lights
    private _driverGroup = group (driver _x);
    _driverGroup setBehaviour "CARELESS";

    // disable unit targeting and switching behavior based on enemy units
    {
      _x disableAI "TARGET";
      _x disableAI "AUTOCOMBAT";
    } forEach (units _driverGroup);

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
      ""
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
