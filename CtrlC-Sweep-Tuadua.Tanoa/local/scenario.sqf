CC_scenario_init = {
  [
    "scenario",
    CC__scenario_serverInit,
    CC__scenario_clientInit
  ] call CC_fnc_moduleInit;
};

CC__scenario_serverInit = {
  // define scenario flags
  CC__scenario_flags = [
    ["nato_insert_request", false],
    ["nato_insert_complete", false],
    ["nato_exfil_request", false],
    ["nato_exfil_complete", false],

    ["nato_house_a", false],
    ["nato_house_b", false],
    ["nato_house_c", false],
    ["nato_house_d", false],
    ["nato_cache_found", false],
    ["nato_cache_destroyed", false]
  ];

  publicVariable "CC__scenario_flags";

  // define dynamic markers
  CC__scenario_markers = [
    ["markerNatoKilo", groupNatoKilo]
  ];

  // module settings
  [
    [
      "fsm_insert",
      "fsm_sweep",
      "fsm_locate_cache",
      "fsm_destroy_cache",
      "fsm_exfil",
      "fsm_nato_win",
      "fsm_nato_lose"
    ],
    CC__scenario_serverTask,
    CC__scenario_debugStatus,
    []
  ];
};

CC__scenario_fsmReportState = {
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

CC__scenario_clientInit = {
  // only run on the server
  if (!isServer) exitWith {};

  [
    "scenario",
    "fsm_insert",
    CC__scenario_fsm_insert
  ] call CC_fnc_moduleEventRegister;

  [
    "scenario",
    "fsm_sweep",
    CC__scenario_fsm_sweep
  ] call CC_fnc_moduleEventRegister;

  [
    "scenario",
    "fsm_locate_cache",
    CC__scenario_fsm_locate_cache
  ] call CC_fnc_moduleEventRegister;

  [
    "scenario",
    "fsm_destroy_cache",
    CC__scenario_fsm_destroy_cache
  ] call CC_fnc_moduleEventRegister;

  [
    "scenario",
    "fsm_exfil",
    CC__scenario_fsm_exfil
  ] call CC_fnc_moduleEventRegister;

  [
    "scenario",
    "fsm_nato_win",
    CC__scenario_fsm_nato_win
  ] call CC_fnc_moduleEventRegister;

  [
    "scenario",
    "fsm_nato_lose",
    CC__scenario_fsm_nato_lose
  ] call CC_fnc_moduleEventRegister;

  // run the scenario state machine
  CC__scenario_nato_viper_fsm = [
    CC__scenario_fsmReportState,
    CC_scenario_setFlag,
    CC_scenario_clearFlag,
    CC_scenario_checkFlag,
    groupNatoViper
  ] execFSM "local\nato_viper.fsm";
};

CC__scenario_serverTask = {
  // update dynamic markers
  {
    private _marker = _x select 0;
    private _target = _x select 1;

    if (typeName _target == "GROUP") then {
      _target = leader _target;
    };

    // update marker to unit's
    private _position = getPos _target;
    _marker setMarkerPos [
      _position select 0,
      _position select 1
    ];
  } forEach CC__scenario_markers;

  // run the task again
  true;
};

CC__scenario_debugStatus = {
  private _parts = [];

  {
    _parts pushBack format [
      "F:%1 (%2)",
      _x select 0,
      _x select 1
    ];
  } forEach CC__scenario_flags;

  _parts joinString "\n";
};

CC__scenario_fsm_insert = {
  systemChat "FSM Insert";
};

CC__scenario_fsm_sweep = {
  systemChat "FSM Sweep";
};

CC__scenario_fsm_locate_cache = {
  systemChat "FSM Locate Cache";
};

CC__scenario_fsm_destroy_cache = {
  systemChat "FSM Destroy Cache";
};

CC__scenario_fsm_exfil = {
  systemChat "FSM Exfil";
};

CC__scenario_fsm_nato_win = {
  // end the mission for all players
  // XXX: how do we end it for spectators?
  private _players = allPlayers - entities "HeadlessClient_F";

  {
    if (faction _x == "BLU_CTRG_F") then {
      ["END1", true] remoteExec ["BIS_fnc_endMission", _x, true];
    } else {
      ["END1", false] remoteExec ["BIS_fnc_endMission", _x, true];
    };
  } forEach _players;
};

CC__scenario_fsm_nato_lose = {
  // end the mission for all players
  // XXX: how do we end it for spectators?
  private _players = allPlayers - entities "HeadlessClient_F";

  {
    if (faction _x == "BLU_CTRG_F") then {
      ["END1", false] remoteExec ["BIS_fnc_endMission", _x, true];
    } else {
      ["END1", true] remoteExec ["BIS_fnc_endMission", _x, true];
    };
  } forEach _players;
};
