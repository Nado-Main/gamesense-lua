local ui_get = ui.get
local g_Execute, g_Log = client.exec, client.log
local get_name, get_steam64 = entity.get_player_name, entity.get_steam64

local mute_list = { "-", "Mute chat", "Mute voice", "Silence" }
local swap_list = { ["Spectators"] = "spec", ["Terrorists"] = "t", ["Counter-Terrorists"] = "ct" }
local Players = ui.reference("PLAYERS", "Players", "Player list")

local function recompile(tbl)
	local result = { "-" }
	
  for k,_ in pairs(tbl) do
    result[#result+1] = k
	end
	
  return result
end

ui.set_callback(ui.new_combobox("PLAYERS", "Adjustments", "Move teams", recompile(swap_list)), function(c)
	local act = ui_get(c)
	if act ~= swap_list[1] then
		ui.set(c, "-")
		local name = get_name(ui_get(Players))

		g_Log("Moved ", name, " to ", swap_list[act])
		g_Execute('sm_team "', name, '" ', swap_list[act])
	end
end)

ui.set_callback(ui.new_combobox("PLAYERS", "Adjustments", "Mute adjustments", mute_list), function(c)
	local act = ui_get(c)
	if act ~= mute_list[1] then
		ui.set(c, mute_list[1])
		local name = get_name(ui_get(Players))

		if act == mute_list[2] then
			g_Log("Gagged: ", name)
			g_Execute('sm_gag "', name, '"')
		elseif act == mute_list[3] then
			g_Log("Muted: ", name)
			g_Execute('sm_mute "', name, '"')
		elseif act == mute_list[4] then
			g_Log("Silenced: ", name)
			g_Execute('sm_silence "', name, '"')
		end
	end
end)

local slap_dmg = ui.new_slider("PLAYERS", "Adjustments", "Override slap damage", 0, 100, 50, true, "HP", 1, { [0] = "No damage", [100] = "Slay" })

ui.new_button("PLAYERS", "Adjustments", "Slap", function()
	local damage = ui_get(slap_dmg)
	local name = get_name(ui_get(Players))

	g_Log("Damage given to ", name, " - ", damage)
	g_Execute('sm_slap "', name, '" ', damage)
end)