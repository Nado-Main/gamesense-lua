local delay_slider = { [1] = "Fast" }
for i = 2, 33 do delay_slider[i] = i - 1 .. "ms" end

local active = ui.new_checkbox("MISC", "Miscellaneous", "Door spammer")
local hotkey = ui.new_hotkey("MISC", "Miscellaneous", "Door spammer hk", true)
local delay = ui.new_slider("MISC", "Miscellaneous", "Reaction time", 1, 33, 1, true, "ms", 0, delay_slider)

local menu_listener = function() ui.set_visible(delay, ui.get(active)) end
local round = function(num, dec) return tonumber(string.format("%." .. (dec or 0) .. "f", num)) end

local cmd_tick, cmd_num = 0, 0
local cmd_last_command = globals.tickcount()
ui.set_callback(active, menu_listener)

function hook_listener(data)
    for i = 1, #data do
        client.set_event_callback(data[i], function(c) 
            callback(data[i], c)
        end)
    end
end

function callback(name, cmd)
    if not ui.get(active) then
        return
    end

    local g_local = entity.get_local_player()

    listener = {
        ["setup_command"] = function(cmd)
            cmd_num = ui.get(hotkey) and cmd_num + 1 or 0

            if cmd_num > 3 then
                cmd_tick = globals.tickcount()
                if cmd_tick - cmd_last_command > 0 then
                    cmd.in_use = 1
                end

                if cmd_tick - cmd_last_command > ui.get(delay) then
                    cmd.in_use = 0
                    cmd_last_command = cmd_tick
                end
            end
        end,

        ["paint"] = function(cmd)
            if entity.is_alive(g_local) and cmd_num > 2 then
                local _, y = client.screen_size()
                renderer.text(11, y - 43, 255, 255, 255, 255, "-", 0, "SPAM TIME: " .. round(globals.tickinterval() * cmd_num, 2) .. " SEC")
            end
        end
    }

    if listener[name] then
        listener[name](cmd)
    end
end

menu_listener()
hook_listener({ "setup_command", "paint" })