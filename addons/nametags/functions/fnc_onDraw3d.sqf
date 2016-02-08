/*
 * Author: <N/A>
 * Draws names and icons.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * call ace_nametags_fnc_onDraw3d
 *
 * Public: No
 */
#include "script_component.hpp"

private ["_defaultIcon", "_distance", "_alpha", "_icon", "_targets", "_relPos", "_projDist", "_target"];

BEGIN_COUNTER(GVAR(onDraw3d));

// Don't show nametags in spectator or if RscDisplayMPInterrupt is open
if ((isNull ACE_player) || {!alive ACE_player} || {!isNull (findDisplay 49)}) exitWith {};

// Determine flags from current settings
private _drawName = true;
private _drawRank = GVAR(showPlayerRanks);
private _enabledTagsNearby = false;
private _enabledTagsCursor = false;
private _onKeyPressAlphaMax = 1;
switch (GVAR(showPlayerNames)) do {
    case 0: {
        // Player names Disabled
        _drawName = false;
        _enabledTagsNearby = (GVAR(showSoundWaves) == 2);
        _enabledTagsCursor = false;
    };
    case 1: {
        // Player names Enabled
        _enabledTagsNearby = true;
        _enabledTagsCursor = false;
    };
    case 2: {
        // Player names Only cursor
        _enabledTagsNearby = (GVAR(showSoundWaves) == 2);
        _enabledTagsCursor = true;
    };
    case 3: {
        // Player names Only Keypress
        _onKeyPressAlphaMax = 2 + (GVAR(showNamesTime) - ACE_time);
        _enabledTagsNearby = (_onKeyPressAlphaMax) > 0 || (GVAR(showSoundWaves) == 2);
        _enabledTagsCursor = false;
    };
    case 4: {
        // Player names Only Cursor and Keypress
        _onKeyPressAlphaMax = 2 + (GVAR(showNamesTime) - ACE_time);
        _enabledTagsNearby = (GVAR(showSoundWaves) == 2);
        _enabledTagsCursor = _onKeyPressAlphaMax > 0;
    };
};

private _ambientBrightness = ((([] call EFUNC(common,ambientBrightness)) + ([0, 0.4] select ((currentVisionMode ace_player) != 0))) min 1) max 0;
private _maxDistance = _ambientBrightness * GVAR(PlayerNamesViewDistance);

// Show nametag for the unit behind the cursor or its commander
if (_enabledTagsCursor) then {
    _target = cursorTarget;
    if !(_target isKindOf "CAManBase") then {
        // When cursorTarget is on a vehicle show the nametag for the commander.
        if !(_target in allUnitsUAV) then {
            _target = effectiveCommander _target;
        } else {
            _target = objNull;
        };
    };
    if (isNull _target) exitWith {};

    if (_target != ACE_player &&
        {(side group _target) == (side group ACE_player)} &&
        {GVAR(showNamesForAI) || {[_target] call EFUNC(common,isPlayer)}} &&
        {lineIntersectsSurfaces [_camPosASL, eyePos _x, ACE_player, _x] isEqualTo []} &&
        {!isObjectHidden _x}) then {

        _distance = ACE_player distance _target;

        private _drawSoundwave = (GVAR(showSoundWaves) > 0) && {[_target] call FUNC(isSpeaking)};
        // Alpha:
        // - base value determined by GVAR(playerNamesMaxAlpha)
        // - decreases when _distance > _maxDistance
        // - increases when the unit is speaking
        // - it's clamped by the value of _onKeyPressAlphaMax
        private _alpha = (((1 + ([0, 0.2] select _drawSoundwave) - 0.2 * (_distance - _maxDistance)) min 1) * GVAR(playerNamesMaxAlpha)) min _onKeyPressAlphaMax;

        if (_alpha > 0) then {
            [ACE_player, _target, _alpha, _distance * 0.026, _drawName, _drawRank, _drawSoundwave] call FUNC(drawNameTagIcon);
        };
    };
};

// Show nametags for nearby units
if (_enabledTagsNearby) then {
    private _camPosAGL = positionCameraToWorld [0, 0, 0];
    private _camPosASL = AGLtoASL _camPosAGL;
    private _vecy = (AGLtoASL positionCameraToWorld [0, 0, 1]) vectorDiff _camPosASL;

    // Find valid targets and cache them
    private _targets = [[], {
        private _nearMen = _camPosAGL nearObjects ["CAManBase", _maxDistance + 7];
        _nearMen select {
            _x != ACE_player &&
            {(side group _x) == (side group ACE_player)} &&
            {GVAR(showNamesForAI) || {[_x] call EFUNC(common,isPlayer)}} &&
            {lineIntersectsSurfaces [_camPosASL, eyePos _x, ACE_player, _x] isEqualTo []} &&
            {!isObjectHidden _x}
        }
    }, missionNamespace, QGVAR(nearMen), 0.5] call EFUNC(common,cachedCall);

    {
        private _target = _x;

        private _relPos = (visiblePositionASL _target) vectorDiff _camPosASL;
        private _distance = vectorMagnitude _relPos;
        private _projDist = _relPos vectorDistance (_vecy vectorMultiply (_relPos vectorDotProduct _vecy));

        private _drawSoundwave = (GVAR(showSoundWaves) > 0) && {[_target] call FUNC(isSpeaking)};
        // Alpha:
        // - base value determined by GVAR(playerNamesMaxAlpha)
        // - decreases when _distance > _maxDistance
        // - increases when the unit is speaking
        // - it's clamped by the value of _onKeyPressAlphaMax
        private _alpha = (((1 + ([0, 0.2] select _drawSoundwave) - 0.2 * (_distance - _maxDistance)) min 1) * GVAR(playerNamesMaxAlpha)) min _onKeyPressAlphaMax;

        if (_alpha > 0) then {
            [ACE_player, _target, _alpha, _distance * 0.026, _drawName, _drawRank, _drawSoundwave] call FUNC(drawNameTagIcon);
        };
        nil
    } count _targets;
};

END_COUNTER(GVAR(onDraw3d));
