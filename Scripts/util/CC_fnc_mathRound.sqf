/**
 * Round a floating point value to a specific number of digits.
 *
 * @param 0 value
 * @param 1 digits after the decimal point
 * @returns rounded value
 */

params [
  ["_value", 0, [0]],
  ["_digits", 2, [0]]
];

// corner case: round to integer
if (_digits <= 0) exitWith {
  round _value;
};

// determine the scale coefficient
private "_scale";
_scale = 10 ^ _digits;

// round the value to the requested digits
(round (_value * _scale)) / _scale;
