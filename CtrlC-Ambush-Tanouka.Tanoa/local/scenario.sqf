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
  ] call CC_fnc_moduleInit;
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
      "fsm_syndikat_win",
      "dialogue_ambush_getout",
      "dialogue_ambush_defend",
      "dialogue_pivot_search",
      "dialogue_rescue_evac"
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
  ["scenario", "fsm_intro", CC__scenario_fsm_intro] call CC_fnc_moduleEventRegister;
  ["scenario", "fsm_ambush", CC__scenario_fsm_ambush] call CC_fnc_moduleEventRegister;
  ["scenario", "fsm_pivot", CC__scenario_fsm_pivot] call CC_fnc_moduleEventRegister;
  ["scenario", "fsm_search", CC__scenario_fsm_search] call CC_fnc_moduleEventRegister;
  ["scenario", "fsm_rescue", CC__scenario_fsm_rescue] call CC_fnc_moduleEventRegister;
  ["scenario", "fsm_exfil", CC__scenario_fsm_exfil] call CC_fnc_moduleEventRegister;

  [
    "scenario",
    "fsm_nato_win",
    CC__scenario_fsm_nato_win
  ] call CC_fnc_moduleEventRegister;

  [
    "scenario",
    "fsm_syndikat_win",
    CC__scenario_fsm_syndikat_win
  ] call CC_fnc_moduleEventRegister;

  [
    "scenario",
    "dialogue_ambush_getout",
    CC__scenario_dialogue_ambush_getout
  ] call CC_fnc_moduleEventRegister;

  [
    "scenario",
    "dialogue_ambush_defend",
    CC__scenario_dialogue_ambush_defend
  ] call CC_fnc_moduleEventRegister;

  [
    "scenario",
    "dialogue_pivot_search",
    CC__scenario_dialogue_pivot_search
  ] call CC_fnc_moduleEventRegister;

  [
    "scenario",
    "dialogue_rescue_evac",
    CC__scenario_dialogue_rescue_evac
  ] call CC_fnc_moduleEventRegister;

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
    ["not called on server"] call BIS_fnc_error;
  };

  // retrieve parameters
  params [
    ["_state", "", [""]]
  ];

  // debug
  ["scenario", "fsm_state", "%1", [_state]] call CC_fnc_moduleLog;

  // update the scenario state
  CC__scenario_state = _state;
  publicVariable "CC__scenario_state";

  // run event handlers
  ["scenario", format ["fsm_%1", _state], [], true] call CC_fnc_moduleEventFire;

  // start relevant dialogue
  [_state] call CC__scenario_dialogue_play;
};

CC__scenario_fsm_intro = {
  // start convoy
  [] spawn CC__scenario_convoy_run;

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
    _x enableSimulationGlobal true;
  } forEach _syndikatUnits;
};

CC__scenario_dialogue_ambush_getout = {
  // force everyone out of the chase car
  [vehicleNatoChase] call CC_fnc_vehicleUnload;
};

CC__scenario_dialogue_ambush_defend = {
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
    _x enableSimulationGlobal true;
  } forEach _syndikatUnits;

  // complete defend task
  ["defendConvoy", "SUCCEEDED"] call BIS_fnc_taskSetState;
};

CC__scenario_dialogue_pivot_search = {
  // delete the meet informant task
  ["meetInformant"] call BIS_fnc_deleteTask;

  // XXX: slight pause to prevent overlapping notifications
  sleep 1;

  // create search factory task
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
  // nothing to do
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
};

CC__scenario_dialogue_rescue_evac = {
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
