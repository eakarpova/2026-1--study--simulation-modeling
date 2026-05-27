using DrWatson
@quickactivate "project"
include(joinpath(@__DIR__, "../src/sir_model.jl"))
using Random, StatsPlots

tmax = 40.0
u0 = [990, 10, 0]
p = [0.05, 10.0, 0.25]

Random.seed!(1234)

des_model = MakeSIRModel(u0, p)
activate(des_model)
sir_run(des_model, tmax)
data_des = out(des_model)

@df data_des plot(:t, [:S :I :R],
    labels = ["S" "I" "R"],
    xlabel = "Время",
    ylabel = "Численность",
    title = "Дискретно-событийная SIR модель",
    linewidth = 2,
)
savefig(plotsdir("sir_des.png"))

println("Результат сохранён в plots/sir_des.png")
