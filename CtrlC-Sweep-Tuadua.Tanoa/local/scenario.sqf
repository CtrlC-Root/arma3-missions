CC_scenario_init = {
  [
    "scenario",
    CC__scenario_serverInit,
    CC__scenario_clientInit
  ] call CC_fnc_moduleInit;
};

CC__scenario_serverInit = {
  // define scenario flags
  CC__scenario_flags = [
    ["nato_insert_request", false],
    ["nato_exfil_request", false],

    ["nato_house_a", false],
    ["nato_house_b", false],
    ["nato_house_c", false],
    ["nato_house_d", false],
    ["nato_weapon_cache", false]
  ];

  publicVariable "CC__scenario_flags";

  // define dynamic markers
  CC__scenario_markers = [
    ["markerNatoKilo", groupNatoKilo]
  ];

  // module settings
  [
    [],
    CC__scenario_serverTask,
    CC__scenario_debugStatus,
    []
  ];
};

CC__scenario_clientInit = {
  // nothing to do
};

CC__scenario_serverTask = {
  // update dynamic markers
  {
    private _marker = _x select 0;
    private _target = _x select 1;

    if (typeName _target == "GROUP") then {
      _target = leader _target;
    };

    // update marker to unit's
    private _position = getPos _target;
    _marker setMarkerPos [
      _position select 0,
      _position select 1
    ];
  } forEach CC__scenario_markers;

  // run the task again
  true;
};

CC__scenario_debugStatus = {
  private _parts = [];

  {
    _parts pushBack format [
      "F:%1 (%2)",
      _x select 0,
      _x select 1
    ];
  } forEach CC__scenario_flags;

  _parts joinString "\n";
};
