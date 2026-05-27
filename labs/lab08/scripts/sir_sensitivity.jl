using DrWatson
@quickactivate "project"
include(joinpath(@__DIR__, "../src/sir_model.jl"))
using Random, StatsPlots, CSV, DataFrames

tmax = 40.0
u0 = [990, 10, 0]

betas = [0.03, 0.05, 0.07, 0.1]
results = []

for β in betas
    p = [β, 10.0, 0.25]
    model = MakeSIRModel(u0, p)
    activate(model)
    sir_run(model, tmax)
    data = out(model)
    peak_I = maximum(data.I)
    final_R = data.R[end]
    push!(results, (β=β, peak_I=peak_I, final_R=final_R))
end

df = DataFrame(results)
CSV.write(datadir("sensitivity.csv"), df)

@df df plot(:β, [:peak_I :final_R],
    labels = ["Пик I" "Финальное R"],
    marker = :circle,
    xlabel = "β",
    ylabel = "Численность",
    title = "Чувствительность к β",
)
savefig(plotsdir("sensitivity.png"))

println("Анализ чувствительности завершён. График в plots/sensitivity.png")
