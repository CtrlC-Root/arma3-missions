CC_scenario_init = {
  [
    "scenario",
    CC__scenario_serverInit,
    CC__scenario_clientInit
  ] call CC_fnc_moduleInit;
};

CC__scenario_serverInit = {
  // identify all relevant units
  CC__scenario_nato_units = allUnits select {
    (faction _x) == "BLU_F"
  };

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
  private _natoUnits = CC__scenario_nato_units select { alive _x };
  private _natoUnitsEscaped = _natoUnits select {
    !(_x inArea triggerLipina)
  };

  if ((count _natoUnitsEscaped) == (count _natoUnits)) exitWith {
    {["END1", true] remoteExec ["BIS_fnc_endMission", _x, true]} forEach allPlayers;

    // stop calling server task
    false;
  };

  if ((count _natoUnits) == 0) exitWith {
    {["END1", false] remoteExec ["BIS_fnc_endMission", _x, true]} forEach allPlayers;

    // stop calling server task
    false;
  };

  // run the task again
  true;
};

CC__scenario_debugStatus = {
  format [
    "NATO Alive: %1 / %2",
    { alive _x } count CC__scenario_nato_units,
    count CC__scenario_nato_units
  ];
};
