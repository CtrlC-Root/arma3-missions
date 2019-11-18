CC__scenario_dialogue_intro = [
  ["radioToGroup", unitJamesWright, "Dialogue1", 0.96],
  ["pause", 5],
  ["radioToGroup", unitJamesWright, "Dialogue2", 2.56],
  ["radioToGroup", unitDixonWatson, "Dialogue3", 2.75],
  ["pause", 5],
  ["radioToGroup", unitJamesWright, "Dialogue4", 5.85],
  ["radioToGroup", unitDixonWatson, "Dialogue5", 6.15],
  ["radioToGroup", unitJamesWright, "Dialogue6", 1.92],
  ["radioToGroup", unitDixonWatson, "Dialogue7", 1.52]
];

CC__scenario_dialogue_ambush = [
  ["radioToGroup", unitJamesWright, "Dialogue8", 1.29],
  ["radioToCommand", unitJamesWright, "Dialogue9", 3.38],
  ["radioFromCommand", WEST, "Dialogue10", 3.04],
  ["pause", 1],
  ["radioToGroup", unitDixonWatson, "Dialogue11", 2.53]
];

CC__scenario_dialogue_pivot = [
  ["radioToGroup", unitJamesWright, "Dialogue12", 2.75],
  ["radioToGroup", unitDixonWatson, "Dialogue13", 3.33],
  ["radioToGroup", unitJamesWright, "Dialogue14", 1.96],
  ["radioToGroup", unitDixonWatson, "Dialogue15", 2.21],
  ["radioToGroup", unitJamesWright, "Dialogue16", 2.29],
  ["radioToCommand", unitJamesWright, "Dialogue17", 6.83],
  ["radioFromCommand", WEST, "Dialogue18", 2.56]
];

CC__scenario_dialogue_search = [
  ["radioFromCommand", WEST, "Dialogue19", 6.00],
  ["radioToCommand", unitJamesWright, "Dialogue20", 1.07],
  ["radioToGroup", unitJamesWright, "Dialogue21", 3.89]
];

CC__scenario_dialogue_rescue = [
  ["speak", "CC__scenario_informant", "Dialogue22", 2.20],
  ["speak", unitDixonWatson, "Dialogue23", 1.38],
  ["radioToCommand", unitJamesWright, "Dialogue24", 2.70],
  ["radioFromCommand", WEST, "Dialogue25", 7.81],
  ["speak", unitDixonWatson, "Dialogue26", 1.07],
  ["speak", "CC__scenario_informant", "Dialogue27", 6.27],
  ["speak", unitDixonWatson, "Dialogue28", 2.45],
  ["speak", unitJamesWright, "Dialogue29", 1.34]
];

CC__scenario_dialogue = [
  ["intro", CC__scenario_dialogue_intro],
  ["ambush", CC__scenario_dialogue_ambush],
  ["pivot", CC__scenario_dialogue_pivot],
  ["search", CC__scenario_dialogue_search],
  ["rescue", CC__scenario_dialogue_rescue],
  ["exfil", []]
];

CC__scenario_dialogue_play = {
  params [
    ["_segment", "", [""]]
  ];

  private _index = [CC__scenario_dialogue, _segment] call BIS_fnc_findInPairs;
  if (_index < 0) exitWith {
    [
      "scenario",
      "dialogue_play",
      "segment not found: %1",
      [_segment]
    ] call CC_Module_debug;
  };

  private _dialogue = ((CC__scenario_dialogue select _index) select 1);
  ["scenario", "dialogue_play", "start segment: %1", [_segment]] call CC_Module_debug;
  [_dialogue] spawn CC__scenario_dialogue_play_task;
};

CC__scenario_dialogue_play_task = {
  params [
    ["_dialogue", [], [[]]]
  ];

  {
    private _type = _x select 0;
    private _args = _x select [1, count _x];

    switch (_type) do {
      case "radioToGroup": {
        _args params [
          ["_unit", objNull, [objNull]],
          ["_radioClass", "", [""]],
          ["_duration", 0, [0]]
        ];

        [
          "scenario",
          "dialogue_play_task",
          "radio to group: %1, %2, %3",
          [_unit, _radioClass, _duration]
        ] call CC_Module_debug;

        [_unit, _radioClass] remoteExec ["groupRadio", 0];
        sleep _duration;
      };

      case "radioToCommand": {
        _args params [
          ["_unit", objNull, [objNull]],
          ["_radioClass", "", [""]],
          ["_duration", 0, [0]]
        ];

        [
          "scenario",
          "dialogue_play_task",
          "radio to command: %1, %2, %3",
          [_unit, _radioClass, _duration]
        ] call CC_Module_debug;

        [_unit, _radioClass] remoteExec ["commandRadio", 0];
        sleep _duration;
      };

      case "radioFromCommand": {
        _args params [
          ["_side", sideUnknown, [sideUnknown]],
          ["_radioClass", "", [""]],
          ["_duration", 0, [0]]
        ];

        [
          "scenario",
          "dialogue_play_task",
          "radio from command: %1, %2, %3",
          [_side, _radioClass, _duration]
        ] call CC_Module_debug;

        [[_side, "Base"], _radioClass] remoteExec ["commandRadio", 0];
        sleep _duration;
      };

      case "speak": {
        _args params [
          ["_source", objNull, [objNull, ""]],
          ["_soundClass", "", [""]],
          ["_duration", 0, [0]]
        ];

        private _unit = if ((typeName _source) == "STRING") then {
          missionNamespace getVariable _source;
        } else {
          _source;
        };

        if ((typeName _unit) != "OBJECT") exitWith {
          [
            "scenario",
            "dialogue_play_task",
            "speak: unsupported source: %1: %2",
            [_source, _unit]
          ] call CC_Module_debug;
        };

        [
          "scenario",
          "dialogue_play_task",
          "speak: %1, %2, %3",
          [_unit, _soundClass, _duration]
        ] call CC_Module_debug;

        // XXX: investigate [from, to] alternative syntax for say command
        [_unit, _soundClass] remoteExec ["say", 0];
        sleep _duration;
      };

      case "pause": {
        _args params [
          ["_duration", 0, [0]]
        ];

        [
          "scenario",
          "dialogue_play_task",
          "pause: %1",
          [_duration]
        ] call CC_Module_debug;

        sleep _duration;
      };

      default {
        ["scenario", "dialogue_play_task", "unknown type: %1", [_type]] call CC_Module_debug;
      };
    };
  } forEach _dialogue;
};
