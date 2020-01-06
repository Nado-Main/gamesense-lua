local function setup_materials(list)
    local models = { }

    for i=1, #list do
        models[i] = {
            name = list[i],
            data = materialsystem.find_material(list[i])
        }
    end

    return models
end

local function setup_var(data, in_call)
    local ticks_time = function(tick)
        return (globals.tickinterval() * tick)
    end

    if not in_call then
        ui.set(data.reference, data.on_call)
        client.delay_call(ticks_time(data.time), setup_var, data, true)
    else
        ui.set(data.reference, data.end_call)
    end
end

local function setup_smokeinfo()
    local data, me = 0, entity.get_local_player()
    local CSmokeGrenadeProjectile = entity.get_all("CSmokeGrenadeProjectile")

    if me == nil or CSmokeGrenadeProjectile == nil then
        return
    end

    for i=1, #CSmokeGrenadeProjectile do
        local smoke = CSmokeGrenadeProjectile[i]

        if entity.get_prop(smoke, "m_bDidSmokeEffect") == 1 then
            data = data + 1
        end
    end

    return data
end

local function find_across(tab, in_a, key)
    for i=1, #tab do
        local pr = tab[i][in_a]
        if pr ~= nil and pr == key then
            return tab[i]
        end
    end

    return nil
end

local smokes = 0
local models = {
    "particle/vistasmokev1/vistasmokev1",
    "particle/vistasmokev1/vistasmokev1_smokegrenade",
    "particle/vistasmokev1/vistasmokev1_emods",
    "particle/vistasmokev1/vistasmokev1_emods_impactdust",
    "particle/vistasmokev1/vistasmokev1_fire"
}

local post_data = { "Off", "Wireframe", "Circle" }
local ref = ui.reference("VISUALS", "Effects", "Remove smoke grenades")

local grenade_effect = ui.new_combobox("VISUALS", "Effects", "Smoke effect", post_data)

local materials = setup_materials(models)
local net_update = function(force_disable)
    local active = force_disable and "Off" or ui.get(grenade_effect)

    local smoke_count = setup_smokeinfo()
    local smoke_fire = find_across(materials, "name", "particle/vistasmokev1/vistasmokev1_fire")

    if smoke_count ~= smokes then
        smokes = smoke_count

        if active ~= post_data[1] then
            setup_var({
                reference = ref, time = 7,
                on_call = true, end_call = false
            })
        end
    end

    local n_data = active ~= "Off"
    local circle = active == post_data[3]

    for k, v in pairs(materials) do
        local old_val = n_data

        if v.name == models[5] and circle then
            n_data = false
        end

        v.data:set_material_var_flag(28, n_data)
        v.data:set_material_var_flag(3, n_data)
        v.data:set_material_var_flag(2, n_data and circle)

        n_data = old_val
    end

    if smoke_fire ~= nil then
        smoke_fire.data:set_material_var_flag(2, n_data and active ~= post_data[3])
    end
end

client.set_event_callback("net_update_end", net_update)
client.set_event_callback("shutdown", function()
    net_update(true)

    if ui.get(grenade_effect) ~= post_data[1] then
        ui.set(ref, true)
    end
end)
