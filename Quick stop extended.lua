local selection = { "Off", "Can shoot", "No movement" }
local quickstop = ui.reference("RAGE", "Other", "Quick stop")
local qs_selection = ui.new_combobox("RAGE", "Other", "Override quick stop", selection)

local cache = { ["qs"] = "On" }
local ui_get, ui_set = ui.get, ui.set

local function is_ent_moving(ent, ground_check, speed)
	local x, y, z = entity.get_prop(ent, "m_vecVelocity")
	if not ground_check then
		return math.sqrt(x*x + y*y + z*z) > speed
	else
		return (math.sqrt(x*x + y*y + z*z) > speed and math.sqrt(z^2) == 0)
	end
end

client.set_event_callback("run_command", function(c)
	local g_pLocal = entity.get_local_player()
	local g_pWeapon = entity.get_player_weapon(g_pLocal)
	local qs_mode = ui_get(qs_selection)

	if qs_mode ~= selection[1] and entity.is_alive(g_pLocal) then
		local m_flNextPrimaryAttack = entity.get_prop(g_pWeapon, "m_flNextPrimaryAttack")
		local m_nTickBase = entity.get_prop(g_pLocal, "m_nTickBase")
		local g_CanShoot = (m_flNextPrimaryAttack <= m_nTickBase * globals.tickinterval())

		local c, n = false, false
		if qs_mode == selection[3] then
			c = is_ent_moving(g_pLocal, false, 20)
		else
			c = g_CanShoot
		end

		if cache.qs == "On" and not c then
			ui_set(quickstop, "Off")
			cache["qs"] = ui_get(quickstop)
		elseif cache.qs == "Off" and c then
			ui_set(quickstop, "On")
			cache["qs"] = ui_get(quickstop)
		end
	end
end)