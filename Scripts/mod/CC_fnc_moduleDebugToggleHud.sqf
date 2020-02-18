/**
 * Toggle the local debug status HUD.
 */

// toggle the status hud
private "_enabled";
_enabled = !(player getVariable "cc_debug_hud");
player setVariable ["cc_debug_hud", _enabled];

// start the hud task if necessary
if (_enabled) then {
  0 = [] spawn {
    // display debugging information
    waitUntil {
      // current fps and time
      private _msg = format [
        "FPS: %1\nTime: %2\n------------------------\n",
        round(diag_fps),
        round(time)
      ];

      // determine the target unit to display information about
      private _target = cursorObject;
      if (isNull _target) then {
        _target = player;
      };

      // target information
      private _targetConfig = (configFile >> "CfgVehicles" >> typeOf _target);
      private _targetPos = getPosATL _target;

      _msg = _msg + format [
        "%1 (%2)\n%3\n(X, Y): %4, %5\nZ: %6\n",
        _target,
        rating _target,
        getText (_targetConfig >> "displayName"),
        [_targetPos select 0] call CC_fnc_mathRound,
        [_targetPos select 1] call CC_fnc_mathRound,
        [_targetPos select 2] call CC_fnc_mathRound
      ];

      // display module status
      {
        // retrieve the status callback
        private _name = _x select 0;
        private _settings = _x select 1;
        private _debugStatus = _settings select 2;

        // display the module status if available
        private _status = [] call _debugStatus;

        if (_status != "") then {
          _msg = _msg + format [
            "------------------------\n>> %1\n%2\n",
            _name,
            _status
          ];
        };
      } forEach CC__modules;

      // display the HUD content
      hintSilent _msg;

      // run while debug mode is enabled and the status hud is enabled
      !(player getVariable "cc_debug") || !(player getVariable "cc_debug_hud");
    };

    // clear the screen
    hintSilent "";
  };
};
