using Agents
using Random
using StatsBase

@agent struct Daisy(GridAgent{2})
    breed::Symbol
    age::Int
    albedo::Float64
end

function update_surface_temperature!(pos, model)
    absorbed_luminosity = if isempty(pos, model)
        (1 - model.surface_albedo) * model.solar_luminosity
    else
        daisy = model[id_in_position(pos, model)]
        (1 - daisy.albedo) * model.solar_luminosity
    end
    local_heating = absorbed_luminosity > 0 ? 72 * -log(absorbed_luminosity) + 80 : 80
    model.temperature[pos...] = (model.temperature[pos...] + local_heating) / 2
end

function diffuse_temperature!(pos, model)
    ratio = model.ratio
    npos = nearby_positions(pos, model)
    model.temperature[pos...] = (1 - ratio) * model.temperature[pos...] +
        sum(model.temperature[p...] for p in npos) * 0.125 * ratio
end

function propagate!(pos, model)
    isempty(pos, model) && return
    daisy = model[id_in_position(pos, model)]
    temperature = model.temperature[pos...]
    seed_threshold = 0.1457 * temperature - 0.0032 * temperature^2 - 0.6443
    if rand(abmrng(model)) < seed_threshold
        empty_near_pos = random_nearby_position(pos, model, 1; filter = p -> isempty(p, model))
        if !isnothing(empty_near_pos)
            add_agent!(empty_near_pos, model, daisy.breed, 0, daisy.albedo)
        end
    end
end

function daisy_step!(agent::Daisy, model)
    agent.age += 1
    if agent.age ≥ model.max_age
        remove_agent!(agent, model)
    end
end

function daisyworld_step!(model)
    for p in positions(model)
        update_surface_temperature!(p, model)
        diffuse_temperature!(p, model)
        propagate!(p, model)
    end
    model.tick += 1
    solar_activity!(model)
end

function solar_activity!(model)
    if model.scenario == :ramp
        if model.tick > 200 && model.tick ≤ 400
            model.solar_luminosity += model.solar_change
        end
        if model.tick > 500 && model.tick ≤ 750
            model.solar_luminosity -= model.solar_change / 2
        end
    elseif model.scenario == :change
        model.solar_luminosity += model.solar_change
    end
end

function daisyworld(; griddim = (30, 30),
    max_age = 25,
    init_white = 0.2,
    init_black = 0.2,
    albedo_white = 0.75,
    albedo_black = 0.25,
    surface_albedo = 0.4,
    solar_change = 0.005,
    solar_luminosity = 1.0,
    scenario = :default,
    seed = 165)

    rng = MersenneTwister(seed)
    space = GridSpaceSingle(griddim)
    properties = Dict(
        :max_age => max_age,
        :surface_albedo => surface_albedo,
        :solar_luminosity => solar_luminosity,
        :solar_change => solar_change,
        :scenario => scenario,
        :tick => 0,
        :ratio => 0.5,
        :temperature => zeros(griddim)
    )
    model = StandardABM(Daisy, space; properties, rng,
        agent_step! = daisy_step!,
        model_step! = daisyworld_step!)

    grid = collect(positions(model))
    n_pos = prod(griddim)

    white_pos = sample(grid, Int(init_white * n_pos); replace = false)
    for wp in white_pos
        add_agent!(wp, model, :white, rand(rng, 0:max_age), albedo_white)
    end

    allowed = setdiff(grid, white_pos)
    black_pos = sample(allowed, Int(init_black * n_pos); replace = false)
    for bp in black_pos
        add_agent!(bp, model, :black, rand(rng, 0:max_age), albedo_black)
    end

    for p in positions(model)
        update_surface_temperature!(p, model)
    end
    return model
end
