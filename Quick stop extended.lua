local selection = { "Can shoot", "Speed checks", "Minimal walk" }
local quickstop = ui.reference("RAGE", "Other", "Quick stop")
local qs_selection = ui.new_multiselect("RAGE", "Other", "Override quick stop", selection)
local qs_speed_threshold = ui.new_slider("RAGE", "Other", "Quick stop speed threshold", 1, 100, 10, true)
local qs_hotkey = ui.new_hotkey("RAGE", "Other", "Minimal walk hotkey")

local cache = { ["qs"] = "On" }
local ui_get, ui_set = ui.get, ui.set

local IN_FORWARD, IN_BACK, IN_LEFT, IN_RIGHT = 8, 16, 512, 1024
local wpn_list = { 
	["CAK47"] = { ["speed"] = 215, ["on_strafe"] = 51.69, ["can_zoon"] = false },
	["CWeaponSSG08"] = { ["speed"] = 230, ["on_strafe"] = 55.295, ["can_zoon"] = false },
	["CWeaponAWP"] = { ["speed"] = 100, ["on_strafe"] = 24.04, ["can_zoon"] = true },
	["CWeaponG3SG1"] = { ["speed"] = 120, ["on_strafe"] = 28.85, ["can_zoon"] = true },
	["CWeaponGlock"] = { ["speed"] = 240, ["on_strafe"] = 57.7, ["can_zoon"] = false },
	["CWeaponElite"] = { ["speed"] = 240, ["on_strafe"] = 57.7, ["can_zoon"] = false },
	["CDEagle"] = { ["speed"] = 230, ["on_strafe"] = 55.295, ["can_zoon"] = false },
	["CWeaponSCAR20"] = { ["speed"] = 120, ["on_strafe"] = 28.85, ["can_zoon"] = true },
	["CWeaponHKP2000"] = { ["speed"] = 240, ["on_strafe"] = 57.7, ["can_zoon"] = false }
}

local function is_contains(tab, val)
    for index, value in ipairs(tab) do
        if value == val then return true end
    end

    return false
end

local function is_ent_moving(ent, ground_check, speed)
	local x, y, z = entity.get_prop(ent, "m_vecVelocity")
	if not ground_check then
		return math.sqrt(x*x + y*y + z*z) > speed
	else
		return (math.sqrt(x*x + y*y + z*z) > speed and math.sqrt(z^2) == 0)
	end
end

local function set_speed(new_speed)
	if client.get_cvar("cl_sidespeed") == 450 and new_speed == 450 then
		return
	end

    client.set_cvar("cl_sidespeed", new_speed)
    client.set_cvar("cl_forwardspeed", new_speed)
    client.set_cvar("cl_backspeed", new_speed)
end

local function is_button_pressed(btn, ent)
	if ent ~= nil then
	    local buttons = entity.get_prop(ent, "m_nOldButtons")
	    return buttons ~= nil and (bit.band(buttons, btn) == btn) or false
	end

	return false
end

local function is_strafing()
	local g_pLocal = entity.get_local_player()
	return
		is_button_pressed(IN_LEFT, g_pLocal) and is_button_pressed(IN_FORWARD, g_pLocal) or
		is_button_pressed(IN_RIGHT, g_pLocal) and is_button_pressed(IN_FORWARD, g_pLocal) or
		is_button_pressed(IN_LEFT, g_pLocal) and is_button_pressed(IN_BACK, g_pLocal) or
		is_button_pressed(IN_RIGHT, g_pLocal) and is_button_pressed(IN_BACK, g_pLocal)
end

local function get_speed(weapon, zoom)
	if can_set_speed then
		local current_weapon = wpn_list[weapon]
		if not current_weapon or current_weapon.can_zoom ~= false then
			if not current_weapon or zoom == 0 then
				set_speed(450)
				return
			end
		end

		if is_strafing() then
			set_speed(current_weapon.on_strafe)
		else
			x = current_weapon.speed / 100
			set_speed(x * 34)
		end
	end
end

client.set_event_callback("run_command", function(c)
	local g_pLocal = entity.get_local_player()
	local g_pWeapon = entity.get_player_weapon(g_pLocal)
	local qs_mode = ui_get(qs_selection)

	if not entity.is_alive(g_pLocal) then
		return
	end

	local m_flNextPrimaryAttack = entity.get_prop(g_pWeapon, "m_flNextPrimaryAttack")
	local m_nTickBase = entity.get_prop(g_pLocal, "m_nTickBase")
	local g_CanShoot = (m_flNextPrimaryAttack <= m_nTickBase * globals.tickinterval())

	local can_shot = is_contains(qs_mode, selection[1])
	local speed_checks = is_contains(qs_mode, selection[2])

	local stop_state = true
	if speed_checks then
		stop_state = is_ent_moving(g_pLocal, false, ui_get(qs_speed_threshold))
	end

	if can_shot then
		if (speed_checks and stop_state) or not speed_checks then
			stop_state = g_CanShoot
		end
	end

	if is_contains(qs_mode, selection[3]) then
		can_set_speed = ui_get(qs_hotkey)
		if not can_set_speed then
			set_speed(450)
		else
			stop_state = false
		end

		wpn_id = entity.get_player_weapon(g_pLocal)
		wpn_class = entity.get_classname(wpn_id)
		wpn_zoomLevel = entity.get_prop(wpn_id, "m_zoomLevel")

		get_speed(wpn_class, wpn_zoomLevel)
	end

	if cache.qs == "On" and not stop_state then
		ui_set(quickstop, "Off")
		cache["qs"] = ui_get(quickstop)
	elseif cache.qs == "Off" and stop_state then
		ui_set(quickstop, "On")
		cache["qs"] = ui_get(quickstop)
	end
end)

local function visibility()
    local a = ui_get(qs_selection)
    local b = ui_get(qs_speed_threshold)
    local c = ui_get(qs_hotkey)

    ui.set_visible(qs_speed_threshold, is_contains(a, selection[2]))
    ui.set_visible(qs_hotkey, is_contains(a, selection[3]))
end

visibility()
ui.set_callback(qs_selection, visibility)