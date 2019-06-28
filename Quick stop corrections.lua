local quickstop = ui.reference("RAGE", "Other", "Quick stop")
local active = ui.new_checkbox("RAGE", "Other", "Correct quick stop")

client.set_event_callback("setup_command", function()
    local me = entity.get_local_player()
    local weapon = entity.get_player_weapon(me)

    if not ui.get(active) or weapon == nil then
        return
    end

    local m_nTickBase = entity.get_prop(me, "m_nTickBase")
    local m_flNextPrimaryAttack = entity.get_prop(weapon, "m_flNextPrimaryAttack")
    local m_bCanShoot = (m_flNextPrimaryAttack <= m_nTickBase * globals.tickinterval())

	ui.set(quickstop, m_bCanShoot and "On" or "Off")
end)
