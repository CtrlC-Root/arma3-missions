params [
  ["_args", [], [[]]],
  ["_code", {}, [{}]],
  ["_state", [scriptNull, 0, 0, objNull], [[]], 4]
];

// spawn a helper block and pass all the parameters to it
private _scriptHandle = [_args, _code, _state] spawn {
  params ["_args", "_code", "_state"];

  // store the start time
  private _startTime = time;
  _state set [1, _startTime];

  // run the code
  private _result = _args call _code;

  // calculate the elapsed time
  private _elapsedTime = time - _startTime;

  // store the elapsed time and result
  _state set [2, _elapsedTime];
  _state set [3, _result];
};

// store the script handle
_state set [0, _scriptHandle];

// return a reference to the state array
_state;
