CC_Scenario_init = {
  [
    "scenario",
    CC__scenario_server_init,
    CC__scenario_client_init
  ] call CC_fnc_moduleInit;
};

CC__scenario_server_init = {


 // identify all relevant units

 CC__scenario_nato_units = allUnits select {
   (faction _x) == "BLU_F"
 };

 CC__scenario_OPFOR_units = allUnits select {
   (faction _x) == "OPF_R_F"
 };

 0 = [] spawn {

   private _players = allPlayers - entities "HeadlessClient_F";

   while { true } do {
     // if (({alive _x} count _players) == ({_x inArea triggerLipina} count _players)) exitWith {
     if (({alive _x} count _players) == 2 && ({_x inArea triggerLipina} count _players) == 0) exitWith {
       {["END1", true] remoteExec ["BIS_fnc_endMission", _x, true]} forEach _players;
     };
     if (({ faction _x == "BLU_F" && alive _x } count allUnits) == 0) exitWith {
       {["END1", false] remoteExec ["BIS_fnc_endMission", _x, true]} forEach _players;
     };
     sleep 1;
   };
 };

 // module settings
 [
   [],
   { False },
   CC__scenario_debug_status,
   []
 ];

};

CC__scenario_client_init = {

 // client settings
 if (!isServer) exitWith { };

};

CC__scenario_debug_status = {
  "";
};
