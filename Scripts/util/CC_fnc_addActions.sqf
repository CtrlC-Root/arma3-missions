params [
  ["_target", objNull, [objNull]],
  ["_prefix", "", [""]],
  ["_common", [], [[]]],
  ["_actions", [], [[]]]
];

// validate arguments
if (isNull _target) exitWith {
  ["target is null"] call BIS_fnc_error;
};

if (_prefix == "") exitWith {
  ["prefix is empty"] call BIS_fnc_error;
};

// define a procedure to merge two lists of setting pairs intelligently
private _mergeSettings = {
  params ["_a", "_b"];

  // merge the right list into the left list
  {
    _x params ["_key", "_value"];
    switch (_key) do {
      // join conditions using AND operator
      case "condition": {
        private _existing = [_a, _key, "true"] call BIS_fnc_getFromPairs;
        if (_existing != "true") then {
          _value = format ["%1 && %2", _existing, _value];
        };

        [_a, _key, _value] call BIS_fnc_setToPairs;
      };

      // append new arguments to the existing list
      case "arguments": {
        [_a, _key, _value] call BIS_fnc_addToPairs;
      };

      // override the value directly
      default {
        [_a, _key, _value] call BIS_fnc_setToPairs;
      };
    };
  } forEach _b;

  // return the modified pair list
  _a;
};

// hardcoded setting defaults
private _defaults = [
  ["title", ""],
  ["script", {}],
  ["arguments", []],
  ["priority", 80],
  ["showWindow", true],
  ["hideOnUse", true],
  ["shortcut", ""],
  ["condition", "true"],
  ["radius", 50],
  ["unconscious", false]
];

// merge the common settings into the defaults
[_defaults, _common] call _mergeSettings;

// add the actions to the target and return the resulting indices
_actions apply {
  // determine final settings for this action
  private _settings = [+_defaults, _x] call _mergeSettings;
  private _title = (_settings select 0) select 1;
  private _script = (_settings select 1) select 1;
  private _arguments = (_settings select 2)select 1;
  private _priority = (_settings select 3) select 1;
  private _showWindow = (_settings select 4) select 1;
  private _hideOnUse = (_settings select 5) select 1;
  private _shortcut = (_settings select 6) select 1;
  private _condition = (_settings select 7) select 1;
  private _radius = (_settings select 8) select 1;
  private _unconscious = (_settings select 9) select 1;

  // add the action returning the index
  _target addAction [
    format ["%1: %2", _prefix, _title],
    _script,
    _arguments,
    _priority,
    _showWindow,
    _hideOnUse,
    _shortcut,
    _condition,
    _radius,
    _unconscious
  ];
};
