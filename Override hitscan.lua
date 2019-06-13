local ref_hitbox = ui.reference("RAGE", "Aimbot", "Target hitbox")
local ref_multipoint, _, ref_multipoint_level = ui.reference("RAGE", "Aimbot", "Multi-point")
local ref_multipoint_scale = ui.reference("RAGE", "Aimbot", "Multi-point scale")
local ref_stomach_hitbox_scale = ui.reference("RAGE", "Aimbot", "Stomach hitbox scale")
local ref_dynamic_multipoint = ui.reference("RAGE", "Aimbot", "Dynamic multi-point")
local ref_avoid_limbs = ui.reference("RAGE", "Aimbot", "Avoid limbs if moving")
local ref_avoid_head = ui.reference("RAGE", "Aimbot", "Avoid head if jumping")

local _tab = { "RAGE", "Other" }
local multipoint_level = { "Low", "Medium", "High" }
local hitboxes = { "Head", "Chest", "Stomach", "Arms", "Legs", "Feet" }
local avoid_list = { "Avoid limbs if moving", "Avoid head if jumping" }

local cache = { }
local ui_get, ui_set = ui.get, ui.set

local menu = {
    hitbox = ui.new_multiselect(_tab[1], _tab[2], "Override hitscan \n override_hitbox", hitboxes),
    hotkey = ui.new_hotkey(_tab[1], _tab[2], "Override hitbox hotkey \n override_hk", true),
    customize = ui.new_checkbox(_tab[1], _tab[2], "Customize hitscan \n override_hitbox_customizations"),
    ignore_selections = ui.new_multiselect(_tab[1], _tab[2], "\n ignore_selections", avoid_list),

    multipoint = ui.new_multiselect(_tab[1], _tab[2], "Multi-point \n override_multipoint", hitboxes),
    multipoint_level = ui.new_combobox(_tab[1], _tab[2], "\n override_multipoint_level", multipoint_level),
    multipoint_scale = ui.new_slider(_tab[1], _tab[2], "Multi-point scale \n override_multipoint_scale", 24, 100, ui_get(ref_multipoint_scale), true, "%", 1, { [24] = "Auto" }),
    dynamic_multipoint = ui.new_checkbox(_tab[1], _tab[2], "Dynamic multi-point \n override_dynamic_multipoint"),

    customize_stomach_scale = ui.new_checkbox(_tab[1], _tab[2], "Stomach hitbox scale \n override_stomach_scale"),
    stomach_scale = ui.new_slider(_tab[1], _tab[2], "\n override_stomach_scale_value", 0, 100, ui_get(ref_stomach_hitbox_scale), true, "%"),
}

local function compare(tab, val)
    for i = 1, #tab do
        if tab[i] == val then
            return true
        end
    end
    
    return false
end

local function invoke_cache_callback(name, condition, should_call, VAR)
    local hotkey_modes = {
        [0] = "always on",
        [1] = "on hotkey",
        [2] = "toggle",
        [3] = "off hotkey"
    }

    local _cond = ui_get(condition)
    local _type = type(_cond)

    local value, mode = ui_get(condition)
    local finder = mode ~= nil and mode or (_type == "boolean" and tostring(_cond) or _cond)
    cache[name] = cache[name] ~= nil and cache[name] or finder

    if should_call then ui_set(condition, mode ~= nil and hotkey_modes[VAR] or VAR) else
        if cache[name] ~= nil then
            local _cache = cache[name]
            
            if _type == "boolean" then
                if _cache == "true" then _cache = true end
                if _cache == "false" then _cache = false end
            end

            ui_set(condition, mode ~= nil and hotkey_modes[_cache] or _cache)
            cache[name] = nil
        end
    end
end

local function invoke_menu_callback()
    local list = ui_get(menu.hitbox)
    local customize = ui_get(menu.customize)
    local multipoint = ui_get(menu.multipoint)

    ui.set_visible(menu.customize, #list > 0)
    ui.set_visible(menu.ignore_selections, #list > 0 and customize)

    ui.set_visible(menu.multipoint, #list > 0 and customize)
    ui.set_visible(menu.multipoint_level, #list > 0 and customize and #multipoint > 0)
    ui.set_visible(menu.multipoint_scale, #list > 0 and customize and #multipoint > 0)
    ui.set_visible(menu.dynamic_multipoint, #list > 0 and customize and #multipoint > 0)
    ui.set_visible(menu.customize_stomach_scale, #list > 0 and customize)
    ui.set_visible(menu.stomach_scale, #list > 0 and customize and ui_get(menu.customize_stomach_scale))
end

ui.set_callback(menu.hitbox, invoke_menu_callback)
ui.set_callback(menu.customize, invoke_menu_callback)
ui.set_callback(menu.multipoint, invoke_menu_callback)
ui.set_callback(menu.customize_stomach_scale, invoke_menu_callback)

invoke_menu_callback()

client.set_event_callback("paint", function()
    local list = ui.get(menu.hitbox)
    local active = #list > 0 and ui_get(menu.hotkey)
    local customize = ui_get(menu.customize)
    
    local selections = ui_get(menu.ignore_selections)
    local multipoint_active = active and #ui_get(ref_multipoint) > 0 and customize

    invoke_cache_callback("ref_hitbox", ref_hitbox, active, list)
    invoke_cache_callback("ref_avoid_limbs", ref_avoid_limbs, active and compare(selections, avoid_list[1]), true)
    invoke_cache_callback("ref_avoid_head", ref_avoid_head, active and compare(selections, avoid_list[2]), true)

    invoke_cache_callback("ref_multipoint", ref_multipoint, active, customize and ui_get(menu.multipoint) or ui_get(ref_multipoint))
    invoke_cache_callback("ref_multipoint_level", ref_multipoint_level, multipoint_active, ui_get(menu.multipoint_level))
    invoke_cache_callback("ref_multipoint_scale", ref_multipoint_scale, multipoint_active, ui_get(menu.multipoint_scale))
    invoke_cache_callback("ref_dynamic_multipoint", ref_dynamic_multipoint, multipoint_active, ui_get(menu.dynamic_multipoint))
    invoke_cache_callback("ref_stomach_hbs", ref_stomach_hitbox_scale, active and ui_get(menu.customize_stomach_scale), ui_get(menu.stomach_scale))
end)
