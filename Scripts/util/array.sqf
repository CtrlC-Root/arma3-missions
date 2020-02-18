/**
 * Flatten an array of arrays into a single top-level array.
 */
CC_Array_flatten = {
  params [
    ["_nested", [], [[]]]
  ];

  private _values = [];

  {
    _values append _x;
  } forEach _nested;

  _values;
};
