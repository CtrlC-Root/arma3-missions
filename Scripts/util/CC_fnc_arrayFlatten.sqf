/**
 * Flatten an array of arrays into a single top-level array.
 */

params [
  ["_nested", [], [[]]]
];

private _values = [];

{
  _values append _x;
} forEach _nested;

_values;
