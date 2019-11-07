/*****************************************************************************
 * Multiplayer support.                                                      *
 *****************************************************************************/

/**
 * Initialize multiplayer module.
 */
CC_Multiplayer_init = {
  // initialize module
  [
    "multiplayer",
    [],
    CC__multiplayer_debug_status,
    [
      ["Toggle HUD", CC__multiplayer_toggle_hud],
      ["Toggle Fatigue", CC__multiplayer_toggle_fatigue],
      ["Toggle Damage", CC__multiplayer_toggle_damage],
      ["Toggle Captive", CC__multiplayer_toggle_captive],
      ["Kill Object", CC__multiplayer_kill_object]
    ]
  ] call CC_Module_init;

  // everyone except dedicated server wait for player initialization
  if (!isServer || !isDedicated) then {
    waitUntil { !isNull player };
  };
};

/**
 * Retrieve module debugging information.
 *
 * @returns debug information as text
 */
CC__multiplayer_debug_status = {
  format [
    "Client ID: %1\nPlayer Fatigue: %2\nPlayer Damage: %3\nPlayer Captive: %4",
    clientOwner,
    player getVariable ["cc_multiplayer_enable_fatigue", true],
    player getVariable ["cc_multiplayer_allow_damage", true],
    captive player
  ];
};

/**
 * Debug user action that toggles the unit HUD.
 *
 * @locality local
 */
CC__multiplayer_toggle_hud = {
  // toggle the unit hud
  private "_enabled";
  _enabled = !(player getVariable ["cc_multiplayer_hud", false]);
  player setVariable ["cc_multiplayer_hud", _enabled];

  // add or remove the frame event handler
  if (_enabled) then {
    // start updating target units
    0 = [] spawn CC__multiplayer_hud_update_local;

    // add the frame render handler
    [
      "cc_multiplayer_hud",
      "onEachFrame",
      "CC__multiplayer_hud_onEachFrame"
    ] call BIS_fnc_addStackedEventHandler;
  }
  else {
    // remove the frame render handler
    [
      "cc_multiplayer_hud",
      "onEachFrame",
      "CC__multiplayer_hud_onEachFrame"
    ] call BIS_fnc_removeStackedEventHandler;
  };
};

/**
 * Compute target units and their render settings. This is a task that runs
 * locally while the multiplayer HUD is active.
 *
 * @locality local
 */
CC__multiplayer_hud_update_local = {
  // determine graphics settings
  private "_viewDistance";
  _viewDistance = getObjectViewDistance select 0;

  // update target units
  waitUntil {
    // determine target units
    private "_targetUnits";
    _targetUnits = [
      allUnits + vehicles - [player],
      { simulationEnabled _x && alive _x }
    ] call BIS_fnc_conditionalSelect;

    // compute unit information
    {
      // retrieve the unit's config entry
      private "_configEntry";
      _configEntry = (configFile >> "CfgVehicles" >> typeOf _x);

      // determine unit information
      private ["_name", "_distance", "_knows", "_label"];
      _name = getText (_configEntry >> "displayName");
      _distance = [_x distance player, 0] call CC_Math_round;
      _knows = [_x knowsAbout player, 3] call CC_Math_round;
      _label = format ["%1 [%2] @ %3 m", _name, _knows, _distance];

      // determine the unit texture
      private ["_texture", "_textures"];
      _textures = [
        getText (_configEntry >> "picture"),
        getText (configFile >> "CfgFactionClasses" >> (faction _x) >> "icon"),
        "\a3\ui_f\data\gui\cfg\hints\BasicLook_ca.paa"
      ];

      while {(_textures select 0) == ""} do {
        [_textures] call BIS_fnc_arrayShift;
      };

      _texture = _textures select 0;

      // determine icon opacity, icon size, and font size
      private ["_alpha", "_iconSize", "_fontSize"];
      _alpha = linearConversion [0.0, 4.0, _knows, 0.1, 0.8, true];
      _iconSize = linearConversion [0.0, _viewDistance, _distance, 0.8, 0.2, true];
      _fontSize = 0.03;

      // determine icon color
      private "_color";
      _color = switch (side _x) do {
        case west: { [0.7, 0.7, 1.0, _alpha] };
        case east: { [1.0, 0.7, 0.7, _alpha] };
        case independent: { [0.7, 1.0, 0.7, _alpha] };
        default { [1.0, 1.0, 1.0, _alpha] };
      };

      // store unit settings
      _x setVariable [
        "cc_multiplayer_hud_unit",
        [_label, _texture, _color, _iconSize, _fontSize]
      ];
    } forEach _targetUnits;

    // update target units
    player setVariable ["cc_multiplayer_hud_units", _targetUnits];

    // run while debugging is enabled and the multiplayer HUD is enabled
    private ["_debugEnabled", "_hudEnabled"];
    _debugEnabled = player getVariable ["cc_debug", false];
    _hudEnabled = player getVariable ["cc_multiplayer_hud", false];

    !(_debugEnabled) || !(_hudEnabled);
  };

  // clear units
  player setVariable ["cc_multiplayer_hud_units", []];
};

/**
 * Display 3D icons and labels for relevant units. This is an event handler
 * for the onEachFrame event and needs to be run each time the screen is
 * redrawn.
 *
 * @locality local
 */
CC__multiplayer_hud_onEachFrame = {
  // corner case: debugging or the unit HUD is disabled
  private ["_debugEnabled", "_hudEnabled"];
  _debugEnabled = player getVariable ["cc_debug", false];
  _hudEnabled = player getVariable ["cc_multiplayer_hud", false];

  if (!_debugEnabled || !_hudEnabled) exitWith {
    // disable the hud
    player setVariable ["cc_multiplayer_hud", false];

    // remove the frame event handler so we don't waste processing time
    [
      "cc_multiplayer_hud",
      "onEachFrame",
      "CC__multiplayer_hud_onEachFrame"
    ] call BIS_fnc_removeStackedEventHandler;
  };

  // determine target units
  private "_targetUnits";
  _targetUnits = player getVariable ["cc_multiplayer_hud_units", []];

  // corner case: no units to draw
  if (count _targetUnits == 0) exitWith {};

  // iterate though all units and vehicles
  {
    // retrieve unit settings
    private "_settings";
    _settings = _x getVariable [
      "cc_multiplayer_hud_unit",
      ["???", "", [1.0, 1.0, 1.0, 1.0], 1.0, 0.03]
    ];

    // determine the units' visible position above ground level (AGL)
    private "_position";
    _position = visiblePositionASL _x;
    _position set [2, (_x modelToWorld [0, 0, 0]) select 2];

    // draw the unit icon
    drawIcon3D [
      _settings select 1,
      _settings select 2,
      _position,
      _settings select 3,
      _settings select 3,
      0,
      _settings select 0,
      0,
      _settings select 4,
      "PuristaMedium"
    ];
  } forEach _targetUnits;
};

/**
 * Debug user action that kills whatever the player's cursor is currently
 * pointing to.
 *
 * @locality local
 */
CC__multiplayer_kill_object = {
  // do it
  cursorObject setDamage 1;
};

/**
 * Debug user action that toggles whether the player experiences fatigue.
 *
 * @locality local
 */
CC__multiplayer_toggle_fatigue = {
  // determine the new setting
  private "_enableFatigue";
  _enableFatigue = !(player getVariable ["cc_multiplayer_enable_fatigue", true]);

  // store the new setting
  player setVariable ["cc_multiplayer_enable_fatigue", _enableFatigue];
  player enableFatigue _enableFatigue;
};

/**
 * Debug user action that toggles whether the player can receive damage.
 *
 * @locality local
 */
CC__multiplayer_toggle_damage = {
  // determine the new setting
  private "_allowDamage";
  _allowDamage = !(player getVariable ["cc_multiplayer_allow_damage", true]);

  // store the new setting
  player setVariable ["cc_multiplayer_allow_damage", _allowDamage];
  player allowDamage _allowDamage;
};

/**
 * Debug user action that toggles whether the player is captive.
 *
 * @locality local
 */
CC__multiplayer_toggle_captive = {
  // determine the new setting
  private "_captive";
  _captive = !(captive player);

  // store the new setting
  player setCaptive _captive;
};
