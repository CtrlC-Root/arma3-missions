CC__scenario_dialogue_intro = [
  ["groupRadio", unitJamesWright, "Dialogue1", 0.96],
  ["pause", 5],
  ["groupRadio", unitJamesWright, "Dialogue2", 2.56],
  ["groupRadio", unitDixonWatson, "Dialogue3", 2.75],
  ["pause", 5],
  ["groupRadio", unitJamesWright, "Dialogue4", 5.85],
  ["groupRadio", unitDixonWatson, "Dialogue5", 6.15],
  ["groupRadio", unitJamesWright, "Dialogue6", 1.92],
  ["groupRadio", unitDixonWatson, "Dialogue7", 1.52]
];

CC__scenario_dialogue_ambush = [
  ["groupRadio", unitJamesWright, "Dialogue8", 1.29],
  ["sideRadio", unitJamesWright, "Dialogue9", 3.38], // XXX: Control
  ["sideRadio", ["BluFor", "HQ"], "Dialogue10", 3.04], // XXX: Control
  ["groupRadio", unitDixonWatson, "Dialogue11", 2.53]
];

CC__scenario_dialogue_pivot = [
  ["groupRadio", unitJamesWright, "Dialogue12", 2.75],
  ["groupRadio", unitDixonWatson, "Dialogue13", 3.33],
  ["groupRadio", unitJamesWright, "Dialogue14", 1.96],
  ["groupRadio", unitDixonWatson, "Dialogue15", 2.21],
  ["groupRadio", unitJamesWright, "Dialogue16", 2.29],
  ["sideRadio", unitJamesWright, "Dialogue17", 6.83], // XXX: Control
  ["sideRadio", ["BluFor", "HQ"], "Dialogue18", 2.56] // XXX: Control
];

CC__scenario_dialogue_search = [
  ["sideRadio", ["BluFor", "HQ"], "Dialogue19", 6.00], // XXX: Control
  ["sideRadio", unitJamesWright, "Dialogue20", 1.07], // XXX: Control
  ["groupRadio", unitJamesWright, "Dialogue21", 3.89]
];

CC__scenario_dialogue_rescue = [
  ["speak", CC__scenario_informant, "Dialogue22", 2.20],
  ["speak", unitDixonWatson, "Dialogue23", 1.38],
  ["sideRadio", unitJamesWright, "Dialogue24", 2.70], // XXX: Control
  ["sideRadio", ["BluFor", "HQ"], "Dialogue25", 7.81], // XXX: Control
  ["speak", unitDixonWatson, "Dialogue26", 1.07],
  ["speak", CC__scenario_informant, "Dialogue27", 6.27],
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
      case "groupRadio": {
        _args params [
          ["_unit", objNull, [objNull]],
          ["_class", "", [""]],
          ["_duration", 0, [0]]
        ];

        [
          "scenario",
          "dialogue_play_task",
          "group radio: %1, %2, %3",
          [_unit, _class, _duration]
        ] call CC_Module_debug;

        _unit groupRadio _class;
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
