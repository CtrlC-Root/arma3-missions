/**
 * Force all the units in a vehicle except the driver to disembark.
 */

params [
  ["_vehicle", objNull, [objNull]],
  ["_eject", false, [false]]
];

// locate all the units in the vehicle except the driver and his friends
// XXX: maybe look for units assigned to cargo instead, this can fail
// when more than one unit group is crewing the vehicle and not cargo
private _crew = units (group (driver _vehicle));
private _passengers = (crew _vehicle) - _crew;

// instruct the units to leave the vehicle (on the appropriate host)
{
  [_vehicle, _x, _eject] remoteExec ["CC_fnc_vehicleUnloadUnit", _x, false];
} forEach _passengers;
