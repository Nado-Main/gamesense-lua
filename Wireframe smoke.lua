local is_active = ui.new_checkbox("VISUALS", "Effects", "Wireframed smoke")
local smoke_remove = ui.reference("VISUALS", "Effects", "Remove smoke grenades")

local data_old = { }

local function ticks_time(tick)
    return (globals.tickinterval() * tick)
end

local function setup_nosmoke(first_pass)
    if first_pass then
        ui.set(smoke_remove, true)
        client.delay_call(ticks_time(14), setup_nosmoke, false)
    else
        ui.set(smoke_remove, false)
    end
end

client.set_event_callback("net_update_end", function()
    local smoke_data = entity.get_all("CSmokeGrenadeProjectile")

    local material_smoke = materialsystem.find_materials("particle/vistasmokev1/vistasmokev1_smokegrenade")
    local material_fire = materialsystem.find_material("particle/vistasmokev1/vistasmokev1_fire")

    if not ui.get(is_active) or smoke_data == nil then
        return
    end

    local data = { }
    for i=1, #smoke_data do
        if entity.get_prop(smoke_data[i], "m_bDidSmokeEffect") == 1 then
            data[#data+1] = true
        end
    end

    if #data ~= #data_old then
        client.delay_call(ticks_time(14), setup_nosmoke, true)
        data_old = data
    end

    material_fire:set_material_var_flag(2, true)
    for i=1, #material_smoke do
        material_smoke[i]:set_material_var_flag(28, true)
    end
end)
