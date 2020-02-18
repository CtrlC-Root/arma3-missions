CC_Scenario_init = {
  [
    "scenario",
    CC__scenario_server_init,
    CC__scenario_client_init
  ] call CC_fnc_moduleInit;
};

CC__scenario_server_init = {
  // identify all relevant story units
  CC__scenario_nato_police_units = allUnits select {
    (vehicle _x) == _x && (faction _x) == "BLU_GEN_F"
  };

  CC__scenario_nato_rescue_units = units groupNatoExtractionTeam;
  CC__scenario_fia_assault_units = units groupFiaAssaultTeam;

  // stage the captured commander and prevent him from running away
  unitFiaOfficer playActionNow "SitDown";
  unitFiaOfficer disableAI "MOVE";
  unitFiaOfficer disableAI "ANIM";

  // settings
  [
    [
      "fsm_nato_peaceful",
      "fsm_nato_alarmed",
      "fsm_nato_lose",
      "fsm_fia_search",
      "fsm_fia_escape",
      "fsm_fia_lose",
      "fsm_fia_win"
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
  [
    "scenario",
    "fsm_nato_peaceful",
    CC__scenario_fsm_nato_peaceful
  ] call CC_fnc_moduleEventRegister;

  [
    "scenario",
    "fsm_nato_alarmed",
    CC__scenario_fsm_nato_alarmed
  ] call CC_fnc_moduleEventRegister;

  [
    "scenario",
    "fsm_nato_lose",
    CC__scenario_fsm_nato_lose
  ] call CC_fnc_moduleEventRegister;

  [
    "scenario",
    "fsm_fia_search",
    CC__scenario_fsm_fia_search
  ] call CC_fnc_moduleEventRegister;

  [
    "scenario",
    "fsm_fia_escape",
    CC__scenario_fsm_fia_escape
  ] call CC_fnc_moduleEventRegister;

  [
    "scenario",
    "fsm_fia_lose",
    CC__scenario_fsm_fia_lose
  ] call CC_fnc_moduleEventRegister;

  [
    "scenario",
    "fsm_fia_win",
    CC__scenario_fsm_fia_win
  ] call CC_fnc_moduleEventRegister;

  // run the scenario state machines
  CC__scenario_nato_fsm = [
    CC__scenario_fsm_state,
    CC__scenario_nato_police_units,
    CC__scenario_nato_rescue_units,
    unitFiaOfficer
  ] execFSM "local\nato.fsm";

  CC__scenario_fia_fsm = [
    CC__scenario_fsm_state,
    CC__scenario_fia_assault_units,
    unitFiaOfficer,
    triggerVilla
  ] execFSM "local\fia.fsm";
};

CC__scenario_debug_status = {
  private _fiaState = "N/A";
  private _natoState = "N/A";

  {
    private _name = _x select 0;
    private _state = _x select 1;

    switch (_name) do {
      case "fia": {
        _fiaState = _state;
      };

      case "nato": {
        _natoState = _state;
      };
    };
  } forEach diag_activeMissionFSMs;

  format [
    "FIA FSM: %1\nNATO FSM: %2\nNATO Start: %3\nNATO Insert: %4",
    _fiaState,
    _natoState,
    missionNamespace getVariable ["cc__scenario_nato_start", false],
    missionNamespace getVariable ["cc__scenario_nato_insert", false]
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

  // run event handlers
  ["scenario", format ["fsm_%1", _state], [], true] call CC_fnc_moduleEventFire;
};

CC__scenario_fsm_nato_peaceful = {
  // force police units to turn off flashlights?
};

CC__scenario_fsm_nato_alarmed = {
  // call the rescue helicopter if it hasn't already left
  missionNamespace setVariable ["cc__scenario_nato_start", true, true];

  // force all police units to turn on flashlights?
};

CC__scenario_fsm_nato_lose = {
  // XXX
  [] call CC__scenario_fsm_fia_win;
};

CC__scenario_fsm_fia_search = {
  // XXX
  [
    groupFiaAssaultTeam,
    "locateCapturedUnit",
    ["Locate the captured commander.", "Locate HVT", ""],
    getMarkerPos "markerVilla",
    "ASSIGNED",
    2,
    false,
    "search",
    false
  ] call BIS_fnc_taskCreate;
};

CC__scenario_fsm_fia_escape = {
  // add the captured unit to the assault team so they can command him, enable
  // movement again, and  tweak some of the annoying civilian behavior
  unitFiaOfficer playActionNow "Stand";
  unitFiaOfficer enableAI "MOVE";
  unitFiaOfficer enableAI "ANIM";
  unitFiaOfficer allowFleeing 0;
  [unitFiaOfficer] join groupFiaAssaultTeam;  // changes locality

  // XXX
  ["locateCapturedUnit", "SUCCEEDED"] call BIS_fnc_taskSetState;

  // XXX
  [
    groupFiaAssaultTeam,
    "escapeAlive",
    ["Escape the area alive.", "Escape", ""],
    objNull,
    "ASSIGNED",
    4,
    true,
    "exit",
    false
  ] call BIS_fnc_taskCreate;
};

CC__scenario_fsm_fia_lose = {
  // end the mission for all players
  // XXX: how do we end it for spectators?
  private _players = allPlayers - entities "HeadlessClient_F";

  {
    if (faction _x == "BLU_GEN_F") then {
      ["END1", true] remoteExec ["BIS_fnc_endMission", _x, true];
    } else {
      ["END1", false] remoteExec ["BIS_fnc_endMission", _x, true];
    };
  } forEach _players;
};

CC__scenario_fsm_fia_win = {
  // XXX
  ["locateCapturedUnit", "SUCCEEDED"] call BIS_fnc_taskSetState;
  ["escapeAlive", "SUCCEEDED"] call BIS_fnc_taskSetState;

  // end the mission for all players
  // XXX: how do we end it for spectators?
  private _players = allPlayers - entities "HeadlessClient_F";

  {
    if (faction _x == "IND_G_F") then {
      ["END1", true] remoteExec ["BIS_fnc_endMission", _x, true];
    } else {
      ["END1", false] remoteExec ["BIS_fnc_endMission", _x, true];
    };
  } forEach _players;
};
