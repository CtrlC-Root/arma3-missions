CC_Scenario_init = {
  [
    "scenario",
    CC__scenario_server_init,
    CC__scenario_client_init
  ] call CC_fnc_moduleInit;
};

CC__scenario_server_init = {
  // flags
  CC__scenario_flags = [
    ["csat_comms_disabled", false],
    ["aaf_cas_request", false],
    ["aaf_cas_ready", false],
    ["aaf_marines_request", false]
  ];

  publicVariable "CC__scenario_flags";

  // waypoints
  private _aafVehicleGroups = [groupGorgon1, groupGorgon2, groupStrider1, groupStrider2];
  CC__scenario_waypoints = [
    ["beach", _aafVehicleGroups + []],
    ["hq_stage", _aafVehicleGroups + []],
    ["hq_exfil", _aafVehicleGroups + []]
  ];

  publicVariable "CC__scenario_waypoints";

  // TODO: use the module server task for this instead
  CC__scenario_markers = [
    ["markerAafCobra", groupAafCobra],
    ["markerAafCondor", vehicleAafCondor],
    ["markerAafGorgon1", vehicleAafGorgon1],
    ["markerAafGorgon2", vehicleAafGorgon2],
    ["markerAafStrider1", vehicleAafStrider1],
    ["markerAafStrider2", vehicleAafStrider2]
  ];

  0 = [] spawn {
    while { true } do {
      // update markers
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

      // XXX: rate limit
      sleep 0.25;
    };
  };

  // settings
  [
    [],
    { False; },
    CC__scenario_status
  ];
};

CC__scenario_client_init = {
  // XXX: shortcut to disable comms
  {
    _x addAction [
      "Disable Comms",
      { ["csat_comms_disabled"] call CC_scenario_setFlag; },
      nil,
      1.5,
      false,
      true,
      "",
      "!(['csat_comms_disabled'] call CC_scenario_checkFlag)",
      5
    ];
  } forEach [deviceTerminalA, deviceTerminalB];
};

CC__scenario_status = {
  private _parts = [];

  {
    _parts pushBack format [
      "F:%1 (%2)",
      _x select 0,
      _x select 1
    ];
  } forEach CC__scenario_flags;

  {
    _parts pushBack format [
      "W:%1 (%2)",
      _x select 0,
      count (_x select 1)
    ];
  } forEach CC__scenario_waypoints;

  _parts joinString "\n";
};
