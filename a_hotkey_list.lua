local renderer_line = renderer.line
local renderer_text = renderer.text
local measure_text = renderer.measure_text
local renderer_gradient = renderer.gradient
local renderer_rectangle = renderer.rectangle
local client_screen_size = client.screen_size
local globals_realtime = globals.realtime
local math_floor = math.floor
local math_sin = math.sin
local ui_get = ui.get
local ui_set = ui.set

local active = ui.new_checkbox("VISUALS", "Other ESP", "Hotkey list")
local x_axis, y_axis =
    ui.new_slider("VISUALS", "Other ESP", "Hotkey list position (x/y)\n hlist_posx", 195, 8192, 350, true, "px"),
    ui.new_slider("VISUALS", "Other ESP", "\n hlist_posy", 4, 8192, 4, true, "px")

local references = { }
local hotkey_id = {
    "holding",
    "toggled",
    "disabled"
}

local function item_count(tab)
    if tab == nil then return 0 end
    if #tab == 0 then
        local val = 0
        for k in pairs(tab) do
            val = val + 1
        end

        return val
    end

    return #tab
end

local function create_item(tab, container, name, arg, cname)
    local collected = { }
    local reference = { ui.reference(tab, container, name) }

    for i=1, #reference do
        if i <= arg then
            collected[i] = reference[i]
        end
    end

    references[cname or name] = collected
end

local function renderer_container(x, y, w, h)
    local realtime = globals_realtime()
    local c = { 10, 60, 40, 40, 40, 60, 20 }

    local outline_set = function(x, y, w, h, r, g, b, a)
        renderer_line(x, y, x + w, y, r, g, b, a)
        renderer_line(x, y, x, y + h, r, g, b, a)
        renderer_line(x, y + h, x + w, y + h, r, g, b, a)
        renderer_line(x+w, y + h, x + w, y, r, g, b, a)
    end

    local color = {
        math_floor(math_sin(realtime * 2) * 127 + 128),
        math_floor(math_sin(realtime * 2 + 2) * 127 + 128),
        math_floor(math_sin(realtime * 2 + 4) * 127 + 128)
    }

    for i = 1, #c do
        outline_set(x+i, y+i, w-(i*2), h-(i*2), c[i], c[i], c[i], 200)
    end

    renderer_rectangle( x + 6, y + 6, w - 12, h - 12, 25, 25, 25, 245)
    renderer_gradient(x + 10, y + 17, w - 20, 2, color[1], color[2], color[3], 255, color[3], color[2], color[1], 200, true)
    renderer_rectangle(x + 10, y + 20, w - 20, h - 30, 20,20, 20, 245)

    outline_set(x + 10, y + 20, w - 20, h - 30, 40, 40, 40, 245)
end

local function ui_callback()
    local visible = ui_get(active)
    ui.set_visible(x_axis, visible)
    ui.set_visible(y_axis, visible)
end

local function paint_handler()
    if not ui_get(active) then
        return
    end

    local m_items = { }
    local x_offset, y_offset = 0, 24

    for ref in pairs(references) do
        local current_ref = references[ref]
        local count = item_count(current_ref)

        local active = true
        local state = { ui_get(current_ref[count]) }

        if count > 1 then
            active = ui_get(current_ref[1])
        end

        if active and state[2] ~= 0 and (state[2] == 3 and not state[1] or state[2] ~= 3 and state[1]) then
            m_items[ref] = hotkey_id[state[2]]

            local ms = measure_text(nil, ref)

            if ms > x_offset then
                x_offset = ms
            end
        end
    end

    if ui.is_menu_open() then
        x_offset = 55
        m_items = {
            ["menu item"] = "state"
        }
    end

    if item_count(m_items) == 0 then
        return
    end

    -- do stuff
    local screen_size = { client_screen_size() }
    
    local xp_a, yp_a = ui_get(x_axis), ui_get(y_axis)
    if xp_a > screen_size[1] then ui_set(x_axis, screen_size[1]); xp_a = screen_size[1] end
    if yp_a > screen_size[2] - 20 then ui_set(y_axis, screen_size[2]-20); yp_a = screen_size[2]-20 end

    local x, y = xp_a - 5, yp_a
    local w, h = 100 + x_offset, 36 + (15*item_count(m_items))

    renderer_container(x - w, y, w, h)
    renderer_text(x - w + w / 2, y + 12, 255, 255, 255, 255, "c-", 0, string.upper("h o t k e y s"))

    for key, val in pairs(m_items) do
        local key_type = "[" .. val .. "]"

        renderer_text(x - w + 15, y + y_offset, 255, 255, 255, 255, "", 0, key)
        renderer_text(x - measure_text(nil, key_type) - 15, y + y_offset, 255, 255, 255, 255, "", 0, key_type)

        y_offset = y_offset + 15
    end
end

-- Creating menu items
create_item("RAGE", "Aimbot", "Safe point", 2)
create_item("RAGE", "Other", "Force body aim", 1)
create_item("RAGE", "Other", "Duck peek assist", 1)
create_item("RAGE", "Other", "Anti-aim correction override", 1, "Resolver override")
create_item("RAGE", "Other", "Double tap", 2)
create_item("AA", "Other", "Slow motion", 2)
create_item("AA", "Other", "On shot anti-aim", 2)
create_item("AA", "Anti-aimbot angles", "Freestanding", 1)
create_item("MISC", "Miscellaneous", "Z-Hop", 2)
create_item("MISC", "Miscellaneous", "Pre-speed", 2)
create_item("MISC", "Miscellaneous", "Blockbot", 2)
create_item("MISC", "Miscellaneous", "Jump at edge", 2)
create_item("MISC", "Miscellaneous", "Automatic grenade release", 2, "Grenade release")
create_item("MISC", "Miscellaneous", "Ping spike", 2)
create_item("MISC", "Miscellaneous", "Free look", 1)
create_item("VISUALS", "Player ESP", "Activation type", 1, "Visuals")

client.set_event_callback("paint", paint_handler)

ui.set_callback(active, ui_callback)
ui_callback()
