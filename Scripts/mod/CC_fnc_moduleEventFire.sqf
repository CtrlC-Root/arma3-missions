/**
 * Run local event handlers for a module event.
 *
 * @param 0 module name
 * @param 1 event name
 * @param 2 event handler arguments, defaults to []
 * @param 3 run handlers asynchronously, defaults to true
 * @returns array of script handles in asynchronous mode, otherwise array
 *          of event handler results
 */

params [
  ["_name", "", [""]],
  ["_event", "", [""]],
  ["_args", [], [[]]],
  ["_async", true, [true]]
];

// validate parameters
if (_name == "") exitWith {
  ["empty module name"] call BIS_fnc_error;
};

if (_event == "") exitWith {
  ["empty event name"] call BIS_fnc_error;
};

// retrieve the local module
private _index = [CC__modules_local, _name] call BIS_fnc_findInPairs;
if (_index < 0) exitWith {
  ["invalid module: %1", [_name]] call BIS_fnc_error;
};

private _localModule = (CC__modules_local select _index) select 1;

// retrieve the event handlers
private _localEvents = _localModule select 0;
_index = [_localEvents, _event] call BIS_fnc_findInPairs;
if (_index < 0) exitWith {
  ["invalid module event: %1, %2", _name, _event] call BIS_fnc_error;
};

private _handlers = (_localEvents select _index) select 1;

// run the event handlers asynchronously
if (_async) exitWith {
  private "_scripts";
  _scripts = [];

  {
    _scripts pushBack ([_args, _x] spawn {
      (_this select 0) call (_this select 1);
    });
  } forEach _handlers;

  // return the script handles
  _scripts;
};

// run the event handlers synchronously
private "_results";
_results = [];

{
  _results pushBack (_args call _x);
} forEach _handlers;

// return the handler results
_results;
