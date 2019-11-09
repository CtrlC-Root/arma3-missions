// Intro:
// Ambush: vehicleCarBomb
// Factory: N/A
// Search: N/A
// Outro: vehicleRescueHeli, CC__scenario_rescue_heli

CC_Scenario_init = {
  [
    "scenario",
    [
      "fsm_intro",
      "fsm_ambush",
      "fsm_pivot",
      "fsm_search",
      "fsm_rescue",
      "fsm_nato_win",
      "fsm_syndikat_win"
    ],
    CC__scenario_debug_status,
    []
  ] call CC_Module_init;

  // only configure scenario event handlers on the server
  if (!isServer) exitWith {};

  // register event handlers for fsm states
  ["scenario", "fsm_intro", CC__scenario_fsm_intro] call CC_Module_event_register;
  ["scenario", "fsm_ambush", CC__scenario_fsm_ambush] call CC_Module_event_register;
  ["scenario", "fsm_pivot", CC__scenario_fsm_pivot] call CC_Module_event_register;
  ["scenario", "fsm_pivot", CC__scenario_fsm_pivot] call CC_Module_event_register;
  ["scenario", "fsm_search", CC__scenario_fsm_search] call CC_Module_event_register;
  ["scenario", "fsm_rescue", CC__scenario_fsm_rescue] call CC_Module_event_register;
  ["scenario", "fsm_nato_win", CC__scenario_fsm_nato_win] call CC_Module_event_register;
  ["scenario", "fsm_syndikat_win", CC__scenario_fsm_syndikat_win] call CC_Module_event_register;

  // determine which units are critical to the story
  CC__story_units = [
    unitNatoMajor,
    unitNatoCaptain
  ];

  // initialize scenario state
  CC__scenario_state = "start";
  publicVariable "CC__scenario_state";

  // run the scenario state machine
  CC__scenario_fsm = [
    CC__scenario_fsm_state,
    CC__story_units
  ] execFSM "local\scenario.fsm";
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
