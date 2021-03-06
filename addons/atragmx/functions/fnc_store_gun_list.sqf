/*
 * Author: Ruthberg
 * Saves the persistent gun list entries into profileNamespace
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * call ace_atragmx_fnc_store_user_data
 *
 * Public: No
 */
#include "script_component.hpp"

private _gunList = [];
{
    if (_x select 20) then {
        _gunList pushBack _x;
    };
} forEach GVAR(gunList);

profileNamespace setVariable ["ACE_ATragMX_gunList", _gunList];
