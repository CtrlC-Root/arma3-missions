/**
 * Force all the units in a vehicle except the driver to disembark.
 */
CC_Vehicle_unload = {
  // retrieve parameters
  params [
    ["_vehicle", objNull, [objNull]],
    ["_eject", false, [false]]
  ];

  // locate all the units in the vehicle except the driver and his friends
  // XXX: maybe look for units assigned to cargo instead, this can fail
  // when more than one unit group is crewing the vehicle and not cargo
  private _crew = units (group (driver _vehicle));
  private _passengers = (crew _vehicle) - _crew;

  // instruct the units to leave the vehicle
  {
    [_vehicle, _x, _eject] remoteExec ["CC__vehicle_unload_local", _x, false];
  } forEach _passengers;
};

/**
 * Force all the units in a vehicle except the driver to disembark.
 *
 * @locality local
 */
CC__vehicle_unload_local = {
  // retrieve parameters
  private _vehicle = _this select 0;
  private _unit = _this select 1;
  private _eject = _this select 2;

  // force the unit to leave the vehicle
  unassignVehicle _unit;

  if (_eject) then {
    _unit action ["EJECT", _vehicle];
  }
  else {
    _unit action ["GETOUT", _vehicle];
  };
};

/**
 * Check if a given vehicle contains a particular selection of group units.
 *
 * @param 0 vehicle
 * @param 1 selection (one of "all", "none")
 * @param 2 array of groups
 * @returns true, false, or objNull in case of error
 */
CC_Vehicle_contains = {
  params [
    ["_vehicle", objNull, [objNull]],
    ["_selection", "", [""]],
    ["_groups", [], [[]]]
  ];

  // retrieve all group units
  private _groupUnits = _groups apply { units _x };
  private _allUnits = [_groupUnits] call CC_Array_flatten;
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
      ["util", "vehicle_contains", "unknown selection: %1", [_selection]] call CC_Module_debug;

      // returning either true or false could trigger a condition so return
      // a safe value that's unlikely to fail open or closed
      objNull;
    };
  };
};
