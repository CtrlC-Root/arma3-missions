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
