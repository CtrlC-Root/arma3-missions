/**
 * Register a local event handler for a module event.
 *
 * @param 0 module name
 * @param 1 event name
 * @param 2 event handler
 */

params [
  ["_name", "", [""]],
  ["_event", "", [""]],
  ["_handler", {}, [{}]]
];

// validate parameters
if (_name == "") exitWith {
  ["empty module name"] call BIS_fnc_error;
};

if (_event == "") exitWith {
  ["empty event name"] call BIS_fnc_error;
};

private _moduleIndex = [CC__modules, _name] call BIS_fnc_findInPairs;
if (_moduleIndex < 0) exitWith {
  ["invalid module: %1", _name] call BIS_fnc_error;
};

private _globalModule = (CC__modules select _moduleIndex) select 1;
private _eventNames = _globalModule select 0;
if (!(_event in _eventNames)) exitWith {
  ["invalid module event: %1, %2", _name, _event] call BIS_fnc_error;
};

// register the event handler
// XXX: assuming CC__modules and CC__modules_local keys are in the same order
private _localModule = (CC__modules_local select _moduleIndex) select 1;
private _localEvents = _localModule select 0;
[_localEvents, _event, [_handler]] call BIS_fnc_addToPairs;
