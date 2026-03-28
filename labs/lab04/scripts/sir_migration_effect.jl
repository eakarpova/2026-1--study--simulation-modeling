using DrWatson
@quickactivate "project"
using Agents, DataFrames, Plots, CSV, Random, Statistics
include(joinpath(@__DIR__, "../src/sir_model.jl"))

function create_migration_matrix(C, intensity)
    M = fill(intensity / (C - 1), C, C)
    for i in 1:C
        M[i, i] = 1 - intensity
    end
    return M
end

function peak_time(p)
    C = p[:C]
    migration_rates = create_migration_matrix(C, p[:migration_intensity])
    model = initialize_sir(;
        Ns = p[:Ns],
        β_und = p[:β_und],
        β_det = p[:β_det],
        infection_period = p[:infection_period],
        detection_time = p[:detection_time],
        death_rate = p[:death_rate],
        reinfection_probability = p[:reinfection_probability],
        Is = p[:Is],
        seed = p[:seed],
        migration_rates = migration_rates,
        n_steps = p[:n_steps],
    )

    infected_frac(model) = count(a.status == :I for a in allagents(model)) / nagents(model)
    peak = 0.0
    peak_step = 0
    for step in 1:p[:n_steps]
        Agents.step!(model, 1)
        frac = infected_frac(model)
        if frac > peak
            peak = frac
            peak_step = step
        end
    end
    return (peak_time = peak_step, peak_value = peak)
end

migration_intensities = 0.0:0.1:0.5
seeds = [42, 43, 44]
params_list = []
for mig in migration_intensities, s in seeds
    push!(params_list, Dict(
        :migration_intensity => mig,
        :C => 3,
        :Ns => [1000, 1000, 1000],
        :β_und => [0.5, 0.5, 0.5],
        :β_det => [0.05, 0.05, 0.05],
        :infection_period => 14,
        :detection_time => 7,
        :death_rate => 0.02,
        :reinfection_probability => 0.1,
        :Is => [1, 0, 0],
        :seed => s,
        :n_steps => 150,
    ))
end

results = []
for p in params_list
    data = peak_time(p)
    push!(results, merge(p, Dict(pairs(data))))
end

df = DataFrame(results)
CSV.write(datadir("migration_scan_all.csv"), df)

grouped = combine(groupby(df, :migration_intensity),
    :peak_time => mean => :mean_peak_time,
    :peak_value => mean => :mean_peak_value,
)

plot(grouped.migration_intensity, grouped.mean_peak_time, marker = :circle,
     xlabel = "Интенсивность миграции", ylabel = "Время до пика (дни)", label = "Время пика")
plot!(grouped.migration_intensity, grouped.mean_peak_value .* 3000, marker = :square,
     xlabel = "Интенсивность миграции", ylabel = "Численность в пике", label = "Пиковая заболеваемость")
savefig(plotsdir("migration_effect.png"))
