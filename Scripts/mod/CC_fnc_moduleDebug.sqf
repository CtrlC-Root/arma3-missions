/**
 * Enable or disable the debug interface for a player unit.
 *
 * @param 0 enabled state
 * @param 1 player unit
 */

params [
  ["_state", true, [true]],
  ["_unit", player, [objNull]]
];

// corner case: function called with default arguments on server so player is objNull
if (isNull _unit) exitWith {
  ["null unit"] call BIS_fnc_error;
};

// verify the unit is a player
private "_players";
_players = ([] call BIS_fnc_listPlayers) - (entities "HeadlessClient_F");

if (!(_unit in _players)) exitWith {
  ["unit not a player: %1", _unit] call BIS_fnc_error;
};

// configure the interface on the local client
[_state] remoteExec ["CC_fnc_moduleDebugLocal", _unit, false];
