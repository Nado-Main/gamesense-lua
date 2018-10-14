local ui_get, ui_set, e_prop = ui.get, ui.set, entity.get_prop

local fs_active = ui.new_checkbox("AA", "Anti-aimbot angles", "Freestanding corrections")
local freestanding = ui.reference("AA", "Anti-aimbot angles", "Freestanding")
local slowmotion, slowmotion_hk = ui.reference("AA", "Other", "Slow motion")

local function get_velocity(entity)
	local vel_x = e_prop(entity, "m_vecVelocity[0]")
	local vel_y = e_prop(entity, "m_vecVelocity[1]")
	local vel_z = e_prop(entity, "m_vecVelocity[2]")

	return (math.sqrt(vel_x * vel_x + vel_y * vel_y + vel_z * vel_z))
end

client.set_event_callback("run_command", function(c)
	local g_pLocal = entity.get_local_player()
	local g_pWeapon = entity.get_player_weapon(g_pLocal)
	if ui_get(fs_active) and g_pWeapon then

		g_Velocity = get_velocity(g_pLocal)
		if g_Velocity > 1 and not ui_get(slowmotion_hk) then
			ui_set(freestanding, { "Running" })
		else
			ui_set(freestanding, { "Default" })
		end

	end
end)