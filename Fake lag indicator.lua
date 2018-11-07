local choked_cmd = 0
local ui_get = ui.get

local fl = {
	enabled = ui.reference("AA", "Fake lag", "Enabled"),
	limit = ui.reference("AA", "Fake lag", "Limit")	
}

local mode = { "Static color", "By choked commands" }
local active = ui.new_checkbox("AA", "Fake lag", "Fake lag indicator")
local lag_picker = ui.new_color_picker("AA", "Fake lag", "LAG Color", 124, 195, 13, 255)

local circle = ui.new_checkbox("AA", "Fake lag", "Draw circle indicator")
local circle_picker = ui.new_color_picker("AA", "Fake lag", "Circle Color", 53, 110, 254, 255)
local circle_mode = ui.new_combobox("AA", "Fake lag", "Style", mode)

local function g_Math(int, max, declspec)
	local int = (int > max and max or int)

	local tmp = max / int;
	local i = (declspec / tmp)
	i = (i >= 0 and math.floor(i + 0.5) or math.ceil(i - 0.5))

	return i
end

local function draw_indicator_circle(c, x, y, r, g, b, a, percentage, outline)
    local outline = outline or true
    local radius, start_degrees = 9, 0

	if outline then 
		client.draw_circle_outline(c, x, y, 0, 0, 0, 200, radius, start_degrees, 1.0, 5)
	end

    client.draw_circle_outline(c, x, y, r, g, b, 255, radius-1, start_degrees, percentage, 3) -- Inner Circle
end

local function g_ColorByInt(number, max)
	local Colors = {
		{ 124, 195, 13 },
		{ 176, 205, 10 },
		{ 213, 201, 19 },
		{ 220, 169, 16 },
		{ 228, 126, 10 },
		{ 229, 104, 8 },
		{ 235, 63, 6 },
		{ 237, 27, 3 },
		{ 255, 0, 0 }
	}

	i = g_Math(number, max, #Colors)
	return
		Colors[i <= 1 and 1 or i][1], 
		Colors[i <= 1 and 1 or i][2],
		Colors[i <= 1 and 1 or i][3]
end

client.set_event_callback("run_command", function(c)
	choked_cmd = c.chokedcommands
end)

client.set_event_callback("paint", function(c)
	if	not ui_get(active) or 
		not ui_get(fl.enabled) or
		not entity.is_alive(entity.get_local_player()) then
	return
	end

	local r, g, b, a = ui_get(lag_picker)
	local y = client.draw_indicator(c, r, g, b, a, "LAG")
	if choked_cmd == 1 then 
		choked_cmd = 0
	end

	if ui_get(circle) then
		local r, g, b, a = 0, 0, 0, 255
		if ui_get(circle_mode) == mode[1] then
			r, g, b, a = ui_get(circle_picker)
		else
			r, g, b = g_ColorByInt(choked_cmd, ui_get(fl.limit))
		end

		draw_indicator_circle(c, 73.3, (y + 14), r, g, b, alpha, choked_cmd / ui_get(fl.limit))
	end

	client.draw_text(c, 12, y + 26, 243, 124, 124, 255, "-", "200", "CHOKED COMMANDS: ", choked_cmd)
end)

local function visibility()
	local a = ui_get(active)
	local c = ui_get(circle)

	ui.set_visible(circle, a)
	ui.set_visible(circle_picker, a and c)
	ui.set_visible(circle_mode, a and c)
end

visibility()
ui.set_callback(active, visibility)
ui.set_callback(circle, visibility)