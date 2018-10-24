local ui_get, ui_set = ui.get, ui.set
local quick_stop = ui.reference("RAGE", "Other", "Quick stop")
local quick_stop_ext = ui.new_checkbox("RAGE", "Other", "Minimal speed")
local quick_stop_cache = "On"

local function is_ent_moving(ent)
	local vel_x = entity.get_prop(ent, "m_vecVelocity[0]")
	local vel_y = entity.get_prop(ent, "m_vecVelocity[1]")
	local vel_z = entity.get_prop(ent, "m_vecVelocity[2]")

	return math.sqrt(vel_x * vel_x + vel_y * vel_y + vel_z * vel_z) > 20
end

client.set_event_callback("run_command", function(c)
	local g_pLocal = entity.get_local_player()
	local g_pWeapon = entity.get_player_weapon(g_pLocal)

	if ui_get(quick_stop_ext) and entity.is_alive(g_pLocal) then
		local m_flNextPrimaryAttack = entity.get_prop(g_pWeapon, "m_flNextPrimaryAttack")
		local m_nTickBase = entity.get_prop(g_pLocal, "m_nTickBase")
		local g_CanShoot = (m_flNextPrimaryAttack <= m_nTickBase * globals.tickinterval())

		if quick_stop_cache == "On" and not is_ent_moving(g_pLocal) or not g_CanShoot then
			ui_set(quick_stop, "Off")
			quick_stop_cache = ui_get(quick_stop)
		elseif quick_stop_cache == "Off" and is_ent_moving(g_pLocal) and g_CanShoot then
			ui_set(quick_stop, "On")
			quick_stop_cache = ui_get(quick_stop)
		end
	end
end)