/**
 * Record a log message in the system log and optionally send it to the
 * local player's screen using the system chat.
 *
 * @param 0 module name
 * @param 1 module function or relevant section of code
 * @param 2 message format string
 * @param 3 optional list of format values
 */

params [
  ["_module", "", [""]],
  ["_part", "", [""]],
  ["_msg", "", [""]],
  ["_args", [], [[]]]
];

// validate parameters
if (_module == "" || _part == "" || _msg == "") exitWith {
  ["invalid arguments: %1", _this] call BIS_fnc_error;
};

// format the message
private "_final";
_final = format [
  "CC: %1: %2: %3",
  toLower _module,
  toLower _part,
  format ([_msg] + _args)
];

// write the message to the log file
diag_log _final;

// print messages in side chat on clients where the player has
// debugging enabled
if (isServer && isDedicated) exitWith {};
if (local player && player getVariable ["cc_debug", false]) then {
  systemChat _final;
};
