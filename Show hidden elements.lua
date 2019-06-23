local sv_maxunlag_reference = ui.reference("MISC", "Settings", "sv_maxunlag")
local sv_maxticks_reference = ui.reference("MISC", "Settings", "sv_maxusrcmdprocessticks")

local function call_and_return(func, ...)
	func(...)
	return func
end

client.set_event_callback("player_connect_full", call_and_return(function(e)
	local me = entity.get_local_player()
	local user = client.userid_to_entindex(e.userid)

	if e.force or user == me then
		local resources = entity.get_player_resource()
		local is_valve_ds = entity.get_prop(resources, "m_bIsValveDS") == 1

		if e.force == nil then
			ui.set(sv_maxunlag_reference, 200)
			ui.set(sv_maxticks_reference, 16)
		end
        
		ui.set_visible(sv_maxunlag_reference, not is_valve_ds)
		ui.set_visible(sv_maxticks_reference, not is_valve_ds)
	end
end, { force = true }))