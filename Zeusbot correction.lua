local cache = nil
local flag_correction = ui.reference("RAGE", "Other", "Fake lag correction")
local zb_selection = ui.new_combobox("RAGE", "Other", "Zeus bot correction", { "-", "Disabled", "Delay shot" })

local ui_get, ui_set = ui.get, ui.set
client.set_event_callback("run_command", function(c)
	local g_pLocal = entity.get_local_player()
	local g_pWeapon = entity.get_player_weapon(g_pLocal)
	local g_pWeaponName = entity.get_classname(g_pWeapon)

	local selection = ui_get(zb_selection)
	local selection = selection == "Disabled" and "Off" or selection

	if selection ~= "-" and entity.is_alive(g_pLocal) then
	    cache = cache ~= nil and cache or ui_get(flag_correction)
	    if g_pWeaponName ~= "CWeaponTaser" then
	        if cache ~= nil then
	            ui_set(flag_correction, cache)
	            cache = nil
	        end
	    else
			ui_set(flag_correction, selection)
	    end
	end
end)