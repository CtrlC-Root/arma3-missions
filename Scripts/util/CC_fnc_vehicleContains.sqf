/**
 * Check if a given vehicle contains a particular selection of group units.
 *
 * @param 0 vehicle
 * @param 1 selection (one of "all", "none")
 * @param 2 array of groups
 * @returns true, false, or objNull in case of error
 */

params [
  ["_vehicle", objNull, [objNull]],
  ["_selection", "", [""]],
  ["_groups", [], [[]]]
];

// retrieve all group units
private _groupUnits = _groups apply { units _x };
private _allUnits = [_groupUnits] call CC_fnc_arrayFlatten;
private _insideUnits = _allUnits select { vehicle _x == _vehicle };

// evaluate the selection
switch (_selection) do {
  case "all": {
    (count _insideUnits) == (count _allUnits);
  };

  case "none": {
    (count _insideUnits) == 0;
  };

  default {
    ["unknown selection: %1", _selection] call BIS_fnc_error;

    // returning either true or false could trigger a condition so return
    // a safe value that's unlikely to fail open or closed
    objNull;
  };
};
