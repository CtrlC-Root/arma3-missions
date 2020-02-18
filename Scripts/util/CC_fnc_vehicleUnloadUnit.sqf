/**
 * Force a local unit to disembark from a vehicle.
 */

params [
  ["_vehicle", objNull, [objNull]],
  ["_unit", objNull, [objNull]],
  ["_eject", false, [true]]
];

unassignVehicle _unit;

if (_eject) then {
  _unit action ["EJECT", _vehicle];
}
else {
  _unit action ["GETOUT", _vehicle];
};
