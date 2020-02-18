/**
 * Enable or disable the debug interface for the local player.
 *
 * @param 0 enabled state
 */

params [
  ["_state", true, [true]]
];

if (state) then {
  // verify the interface is disabled
  if (player getVariable ["cc_debug", false]) exitWith {
    ["debug interface is already enabled"] call BIS_fnc_error;
  };

  // variables
  player setVariable ["cc_debug", true];
  player setVariable ["cc_debug_hud", false];

  // add user actions
  private _actions = [_unit addAction [
    "DEBUG: Toggle HUD",
    CC_fnc_moduleDebugToggleHud,
    [],
    0.1,
    false,
    true,
    "",
    "(_target getVariable ['cc_debug', false]) && (_target == _this)"
  ]];

  {
    // retrieve module debug actions
    private _name = _x select 0;
    private _settings = _x select 1;
    private _debugActions = _settings select 3;

    // create actions for module debug actions
    {
      // unpack the debug action
      private ["_action", "_handler"];
      _action = _x select 0;
      _handler = _x select 1;

      // create the user action and keep track of it's ID
      _actions pushBack (_unit addAction [
        format ["DEBUG [%1]: %2", toUpper _name, _action],
        _handler,
        [],
        0,
        false,
        true,
        "",
        "(_target getVariable ['cc_debug', false]) && (_target == _this)"
      ]);
    } forEach _debugActions;
  } forEach CC__modules;

  // store user actions
  player setVariable ["cc_debug_actions", _actions];
}
else {
  // verify the interface is enabled
  if (!(player getVariable ["cc_debug", false])) exitWith {
    ["debug interface is already disabled"] call BIS_fnc_error;
  };

  // remove user actions
  {
    player removeAction _x;
  } forEach (player getVariable ["cc_debug_actions", []]);

  // variables
  player setVariable ["cc_debug_actions", nil];
  player setVariable ["cc_debug_hud", nil];
  player setVariable ["cc_debug", nil];
};
