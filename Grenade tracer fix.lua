local entity_get_local_player = entity.get_local_player
local entity_get_player_weapon = entity.get_player_weapon
local entity_get_prop = entity.get_prop
local ui_set = ui.set

local grenade_ref = ui.reference("VISUALS", "Other ESP", "Grenade trajectory")

client.set_event_callback("setup_command", function()
    local me = entity_get_local_player()
    local weapon = entity_get_player_weapon(me)
    local m_bPinPulled = entity_get_prop(weapon, "m_bPinPulled") == 1

    ui_set(grenade_ref, m_bPinPulled)
end)
