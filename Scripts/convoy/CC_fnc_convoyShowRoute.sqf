params [
  ["_route", [], [[]]]
];

// create a deep copy of the route to avoid modifying the original
_route = +_route;

// utility function to create an appropriate marker object
private _createObject = {
  params [
    ["_entry", [], [[]]],
    ["_type", "middle", [""]]
  ];

  private _position = _entry select 2;
  private _objectClass = switch (_type) do {
    case "start": {
      "VR_3DSelector_01_complete_F";
    };

    case "end": {
      "VR_3DSelector_01_incomplete_F";
    };

    default {
      "VR_3DSelector_01_default_F"
    };
  };

  _objectClass createVehicle _position;
};

// keep track of objects we create
private _objects = [];

// create first point
private _entry = [_route] call BIS_fnc_arrayShift;
_objects pushBack [[_entry, "start"] call _createObject];

// create middle points
while { (count _route) > 2 } do {
  _entry = [_route] call BIS_fnc_arrayShift;
  _objects pushBack [[_entry] call _createObject];
};

// create final point
_entry = _route call BIS_fnc_arrayPop;
_objects pushBack [[_entry, "end"] call _createObject];

// return all created objects
_objects;
