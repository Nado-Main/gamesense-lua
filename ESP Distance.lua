local game_type = cvar.game_type

local pl = ui.reference("PLAYERS", "Players", "Player list")
local pl_disable_esp = ui.reference("PLAYERS", "Adjustments", "Disable visuals")

local se = ui.reference("VISUALS", "Other ESP", "Shared ESP")
local se_strict = ui.reference("VISUALS", "Other ESP", "Restrict shared ESP updates")

-- Menu elements
local distance_esp = ui.new_checkbox("VISUALS", "Player ESP", "Distance limit")
local ignore_dz = ui.new_checkbox("VISUALS", "Player ESP", "Ignore danger zone")
local maximum_distance = ui.new_slider("VISUALS", "Player ESP", "Maximum distance", 0, 500, 250, true, "ft")

local function get_fdistance(a_x, a_y, a_z, b_x, b_y, b_z)
	local pow = (math.pow(a_x - b_x, 2) + math.pow(a_y - b_y, 2) + math.pow(a_z - b_z, 2))
    return math.ceil(math.sqrt(pow) * 0.0254 / 0.3048)
end

client.set_event_callback("paint", function()
	if ui.get(distance_esp) then
		local g_Local = entity.get_local_player()
	    local g_pList = entity.get_players(true)

	    local x, y, z = entity.get_prop(g_Local, "m_vecOrigin")
	    for i = 1, #g_pList do 

	    	p = { x, y, z }
	    	p.x, p.y, p.z = entity.get_prop(g_pList[i], "m_vecOrigin")         

	    	if ui.get(ignore_dz) then
	    		ui.set(se, game_type:get_int() == 6)
	    		ui.set(se_strict, game_type:get_int() == 6)
	    	end

	        if p.x ~= nil then
	        	esp_active = (get_fdistance(x, y, z, p.x, p.y, p.z) > ui.get(maximum_distance))

				ui.set(pl, g_pList[i])
				ui.set(pl_disable_esp, esp_active)
	        end

	    end
	end
end)


local function invoke_visible_callback()
	local active = ui.get(distance_esp)
	ui.set_visible(ignore_dz, active)
	ui.set_visible(maximum_distance, active)
end

invoke_visible_callback()
ui.set_callback(distance_esp, invoke_visible_callback)