using DrWatson
@quickactivate "project"
using Agents, DataFrames, Plots, CSV, Random, Statistics
include(joinpath(@__DIR__, "../src/sir_model.jl"))

function run_experiment(p)
    β_und = fill(p[:beta], 3)
    β_det = fill(p[:beta]/10, 3)
    model = initialize_sir(;
        Ns = p[:Ns],
        β_und = β_und,
        β_det = β_det,
        infection_period = p[:infection_period],
        detection_time = p[:detection_time],
        death_rate = p[:death_rate],
        reinfection_probability = p[:reinfection_probability],
        Is = p[:Is],
        seed = p[:seed],
        n_steps = p[:n_steps],
    )

    infected_frac(model) = count(a.status == :I for a in allagents(model)) / nagents(model)
    peak = 0.0
    for step in 1:p[:n_steps]
        Agents.step!(model, 1)
        frac = infected_frac(model)
        if frac > peak
            peak = frac
        end
    end
    final_inf = infected_frac(model)
    final_rec = count(a.status == :R for a in allagents(model)) / nagents(model)
    total_deaths = sum(p[:Ns]) - nagents(model)

    return (peak = peak, final_inf = final_inf, final_rec = final_rec, deaths = total_deaths)
end

beta_range = 0.1:0.1:1.0
seeds = [42, 43, 44]
params_list = []
for b in beta_range, s in seeds
    push!(params_list, Dict(
        :beta => b,
        :Ns => [1000, 1000, 1000],
        :infection_period => 14,
        :detection_time => 7,
        :death_rate => 0.02,
        :reinfection_probability => 0.1,
        :Is => [0, 0, 1],
        :seed => s,
        :n_steps => 100,
    ))
end

results = []
for p in params_list
    data = run_experiment(p)
    push!(results, merge(p, Dict(pairs(data))))
end

df = DataFrame(results)
CSV.write(datadir("beta_scan_all.csv"), df)

grouped = combine(groupby(df, :beta),
    :peak => mean => :mean_peak,
    :final_inf => mean => :mean_final_inf,
    :deaths => mean => :mean_deaths,
)

plot(grouped.beta, grouped.mean_peak, label = "Пик эпидемии", xlabel = "β", ylabel = "Доля", marker = :circle)
plot!(grouped.beta, grouped.mean_final_inf, label = "Конечная доля инфицированных", marker = :square)
plot!(grouped.beta, grouped.mean_deaths ./ 3000, label = "Доля умерших", marker = :diamond)
savefig(plotsdir("beta_scan.png"))
