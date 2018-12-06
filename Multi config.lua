local bit = require "bit"
local ui_get, ui_set, ui_visible = ui.get, ui.set, ui.set_visible

-- Variables
local cache = {}
local old_weapon, current_weapon, wpn_info = nil, nil, {}

local dv_wpn = { "hkp2000", "deagle", "revolver", "ssg08", "awp", "duals", "scar20" }
local to_sort = { "Pistols", "SMGs", "Rifles", "Shotguns", "Snipers", "Heavys" }
local bad_wpn = { -1, 0, 7, 8, 9, 11 }

local min_dmg_table = { [0] = "Auto" }
for i = 1, 26 do min_dmg_table[100 + i] = "HP+" .. i end

local lookup = {
	[32] = { ["name"] = "P2000", ["sname"] = "hkp2000", ["type"] = "pistol" },
	[61] = { ["name"] = "USP-S", ["sname"] = "usp_silencer", ["type"] = "pistol" },
	[4]  = { ["name"] = "Glock-18", ["sname"] = "glock", ["type"] = "pistol" },
	[2]  = { ["name"] = "Dual Beretas", ["sname"] = "duals", ["type"] = "pistol" },
	[36] = { ["name"] = "P250", ["sname"] = "p250", ["type"] = "pistol" },
    [3]  = { ["name"] = "Five-SeveN", ["sname"] = "fiveseven", ["type"] = "pistol" },
    [30] = { ["name"] = "Tec-9", ["sname"] = "tec9", ["type"] = "pistol" },
    [63] = { ["name"] = "CZ75-Auto", ["sname"] = "fn57", ["type"] = "pistol" },
    [1]  = { ["name"] = "Desert Eagle", ["sname"] = "deagle", ["type"] = "pistol" },
	[64] = { ["name"] = "R8-Revolver", ["sname"] = "revolver", ["type"] = "pistol" },
    [10] = { ["name"] = "FAMAS", ["sname"] = "famas", ["type"] = "rifle" },
    [16] = { ["name"] = "M4A4", ["sname"] = "m4a1", ["type"] = "rifle" },
    [60] = { ["name"] = "M4A1-S", ["sname"] = "m4a1_silencer", ["type"] = "rifle" },
    [8]  = { ["name"] = "AUG", ["sname"] = "aug", ["type"] = "rifle" },
    [13] = { ["name"] = "Galil AR", ["sname"] = "galilar", ["type"] = "rifle" },
    [7]  = { ["name"] = "AK-47", ["sname"] = "ak47", ["type"] = "rifle" },
    [39] = { ["name"] = "Sg553", ["sname"] = "sg553", ["type"] = "rifle" },
    [9]  = { ["name"] = "AWP", ["sname"] = "awp", ["type"] = "sniper" },
    [40] = { ["name"] = "Ssg08", ["sname"] = "ssg08", ["type"] = "sniper" },
    [38] = { ["name"] = "Autosniper", ["sname"] = "scar20", ["type"] = "sniper" },
    [35] = { ["name"] = "Nova", ["sname"] = "nova", ["type"] = "shotgun" },
    [25] = { ["name"] = "XM1014", ["sname"] = "xm1014", ["type"] = "shotgun" },
    [29] = { ["name"] = "Sawed-Off", ["sname"] = "sawedoff", ["type"] = "shotgun" },
    [27] = { ["name"] = "MAG-7", ["sname"] = "mag7", ["type"] = "shotgun" },
    [17] = { ["name"] = "MAC-10", ["sname"] = "mac10", ["type"] = "smg" },
    [24] = { ["name"] = "UMP-45", ["sname"] = "ump45", ["type"] = "smg" },
    [26] = { ["name"] = "PP-Bizon", ["sname"] = "bizon", ["type"] = "smg" },
    [34] = { ["name"] = "Mp9 / Mp7", ["sname"] = "mp9", ["type"] = "smg" },
    [19] = { ["name"] = "P90", ["sname"] = "p90", ["type"] = "smg" },
    [28] = { ["name"] = "Negev", ["sname"] = "negev", ["type"] = "heavy" },
    [14] = { ["name"] = "M249", ["sname"] = "m249", ["type"] = "heavy" }
}

local reference = {
	{ "RAGE", "Aimbot", "Target hitbox", ["options"] = { 
			["type"] = "multiselect",
			["select"] = { "Head", "Chest", "Stomach", "Arms", "Legs", "Feet" },
			["bydefault"] = "Head"
		}
	},
	{ "RAGE", "Aimbot", "Target selection", ["options"] = { 
			["type"] = "combobox",
			["select"] = { "Cycle", "Cycle (2x)", "Near crosshair", "Highest damage", "Lowest ping", "Best K/D ratio", "Best hit chance" }
		}
	},
	{ "RAGE", "Aimbot", "Avoid limbs if moving", ["options"] = { ["type"] = "checkbox" }},
	{ "RAGE", "Aimbot", "Avoid head if jumping", ["options"] = { ["type"] = "checkbox" }},
	{ "RAGE", "Aimbot", "Dynamic multi-point", ["options"] = {  ["type"] = "checkbox" }},
	{ "RAGE", "Aimbot", "Minimum hit chance", ["options"] = { 
			["type"] = "slider",
			["min"] = 0,
			["max"] = 100,
			["init_value"] = 50,
			["show_tooltip"] = true,
			["unit"] = "%",
			["scale"] = 1,
			["tooltips"] = nil
		}
	},
	{ "RAGE", "Aimbot", "Minimum damage", ["options"] = { 
			["type"] = "slider",
			["min"] = 0,
			["max"] = 126,
			["init_value"] = 10,
			["show_tooltip"] = true,
			["unit"] = "",
			["scale"] = 1,
			["tooltips"] = min_dmg_table
		}
	},
	{ "RAGE", "Aimbot", "Stomach hitbox scale", ["options"] = { 
			["type"] = "slider",
			["min"] = 1,
			["max"] = 100,
			["init_value"] = 100,
			["show_tooltip"] = true,
			["unit"] = "%",
			["scale"] = 1,
			["tooltips"] = nil
		}
	},
	{ "RAGE", "Aimbot", "Multi-point", ["options"] = { 
			["type"] = "multiselect",
			["select"] = { "Head", "Chest", "Stomach", "Arms", "Legs", "Feet" },
			["bydefault"] = nil
		}
	},
	{ "RAGE", "Aimbot", "Multi-point scale", ["options"] = {
			["type"] = "slider",
			["min"] = 1,
			["max"] = 100,
			["init_value"] = 55,
			["show_tooltip"] = true,
			["unit"] = "%",
			["scale"] = 1,
			["tooltips"] = nil
		}
	},
	{ "RAGE", "Other", "Accuracy boost", ["options"] = { 
			["type"] = "combobox",
			["select"] = { "Off", "Low", "Medium", "High", "Maximum" }
		}
	},
	{ "RAGE", "Other", "Accuracy boost options", ["options"] = { 
			["type"] = "multiselect",
			["select"] = { "Refine shot", "Extended backtrack" },
			["bydefault"] = nil
		}
	},
	{ "RAGE", "Other", "Fake lag correction", ["options"] = { 
			["type"] = "combobox",
			["select"] = { "Off", "Delay shot", "Predict" },
			["bydefault"] = nil
		}
	},
	{ "RAGE", "Other", "Prefer body aim", ["options"] = { 
			["type"] = "combobox",
			["select"] = { "Off", "Always on", "Fake angles", "Aggressive", "High inaccuracy" }
		}
	},
}

-- Functions
local function m_table_recreate(l, id)
	local r = {}
	for k, _ in pairs(l) do
		if id ~= nil then
			r[#r+1] = l[k][id]
		else
			r[#r+1] = l[k]
		end
	end

	return r
end

-- Menu
local multicfg_active = ui.new_checkbox("RAGE", "Other", "Multi config")
local multicfg_ignore_menu = ui.new_checkbox("RAGE", "Other", "Ignore menu state")
local multicfg_bywpn = ui.new_checkbox("RAGE", "Other", "Sort by class")
local multicfg_divisor = ui.new_checkbox("RAGE", "Other", "Weapon divisor")
local multicfg_wpns = ui.new_multiselect("RAGE", "Other", "Active weapons", m_table_recreate(lookup, "name"))

-- Functions
local function m_CreateReference(e)
	for num, _ in pairs(reference) do

		local rf = reference[num]
		e[rf[3]] = ui.reference(rf[1], rf[2], rf[3])

	end
end

function m_table_concat(t1,t2)
    for i=1, #t2 do 
    	t1[#t1+1] = t2[i]
    end

    return t1
end

local function m_vis(table, var)
	for k, _ in pairs(table) do 
		ui_visible(table[k], var)
	end
end


local function m_valid(table, val, new_method)
	if new_method == true then
		-- Forcing extra table valid checks
		if type(table) == 'table' then
			for k,v in pairs(table) do
				if tostring(k) == tostring(val) then 
					return true
				end
			end
		end
		return false
	else -- Default valid checks
		for i=1,#table do
			if table[i] == val then 
				return true
			end
		end
		return false
	end
end

local function m_hook(table, isActive)
	if isActive then
		for k, _ in pairs(reference) do 
			local n = reference[k]
			ui_set(cache[n[3]], ui_get(table[n[3]]))
		end
	end
end

local function m_weapon(wpn)
	c = { active = ui.new_checkbox("RAGE", "Other", wpn .. ": " .. "Active") }

	for k, _ in pairs(reference) do 
		local g = {}
		local refered = reference[k]
		local l_name = refered[3]
		local l_options = refered.options

		if l_options.type == "checkbox" then
			c[l_name] = ui.new_checkbox("RAGE", "Other", wpn .. ": " .. l_name)

		elseif l_options.type == "slider" then
			c[l_name] = ui.new_slider("RAGE", "Other", wpn .. ": " .. l_name, l_options.min, l_options.max, l_options.init_value, l_options.show_tooltip, l_options.unit, l_options.scale, l_options.tooltips)

		elseif l_options.type == "combobox" then
			c[l_name] = ui.new_combobox("RAGE", "Other", wpn .. ": " .. l_name, l_options.select)

		elseif l_options.type == "multiselect" then
			c[l_name] = ui.new_multiselect("RAGE", "Other", wpn .. ": " .. l_name, l_options.select)
			if l_options.bydefault then

				ui_set(c[l_name], l_options.bydefault)
				
			end
		end
	end

	wpn_info[wpn] = c
end

local function paste()
  	if ui_get(multicfg_active) and 
  		current_weapon ~= nil and m_valid(lookup, old_weapon, true) then
  		local wpn = wpn_info[current_weapon]

		for k, _ in pairs(reference) do 
			local n = reference[k]
			ui_set(wpn[n[3]], ui_get(cache[n[3]]))
		end
	end
end

local function m_HookWpns()
	foo = {}
	tbl = m_table_recreate(lookup, "name")

	m_table_concat(foo, tbl)
	m_table_concat(foo, to_sort)

	for k, v in pairs(foo) do
		m_weapon(foo[k])
		m_vis(wpn_info[foo[k]], false)
	end
end

local multicfg_paste = ui.new_button("RAGE", "Other", "Paste vars", paste)

local function Visible()
	local active = ui_get(multicfg_active)
	local bywpn = ui_get(multicfg_bywpn)

	ui_visible(multicfg_ignore_menu, active)
	ui_visible(multicfg_bywpn, active)
	ui_visible(multicfg_wpns, active and not bywpn)
	ui_visible(multicfg_divisor, bywpn)

	if current_weapon ~= nil then 
		m_vis(wpn_info[current_weapon], active)
	end
end

-- hk
m_CreateReference(cache)
m_HookWpns()

Visible()
ui.set_callback(multicfg_active, Visible)
ui.set_callback(multicfg_bywpn, Visible)

client.set_event_callback("run_command", function(e)
	local g_LocalPlayer = entity.get_local_player()
	if not ui_get(multicfg_active) or not entity.is_alive(g_LocalPlayer) then
		return
	end

	local m_hActiveWeapon = entity.get_prop(g_LocalPlayer, "m_hActiveWeapon")
  	local m_iItem = bit.band(entity.get_prop(m_hActiveWeapon, "m_iItemDefinitionIndex"), 0xFFFF)

  	if m_iItem == 11 then -- Autosniper checks
  		m_iItem = 38
  	end

  	if old_weapon ~= m_iItem then
  		old_weapon = m_iItem
		if m_valid(lookup, old_weapon, true) then

			if not ui_get(multicfg_ignore_menu) and ui.is_menu_open() then
				return
			end

			local lc = lookup[old_weapon]
			local wpn = lc.name

			if ui_get(multicfg_bywpn) then
				if lc.type == "pistol" then wpn = "Pistols"
				elseif lc.type == "smg" then wpn = "SMGs"
				elseif lc.type == "rifle" then wpn = "Rifles"
				elseif lc.type == "shotgun" then wpn = "Shotguns"
				elseif lc.type == "sniper" then wpn = "Snipers"
				elseif lc.type == "heavy" then wpn = "Heavys" end

				if ui_get(multicfg_divisor) and m_valid(dv_wpn, lc.sname) then
					wpn = lc.name
				end
			end

			-- Actions
			-- Validate bad weapon list
			if not m_valid(bad_wpn, lc.type) and (m_valid(ui_get(multicfg_wpns), lc.name) or ui_get(multicfg_bywpn)) then
				if current_weapon ~= nil then 
					m_vis(wpn_info[current_weapon], false)
				end

				m_vis(wpn_info[wpn], true)
				m_hook(wpn_info[wpn], ui_get(wpn_info[wpn].active))
				current_weapon = wpn
			elseif current_weapon ~= nil then 
				m_vis(wpn_info[current_weapon], false)
			end
		end
  	end
end)