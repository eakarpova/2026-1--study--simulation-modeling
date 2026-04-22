using DrWatson
@quickactivate "project"
include(joinpath(@__DIR__, "../src/SIRPetri.jl"))
using .SIRPetri
using Plots

β = 0.3
γ = 0.1
tmax = 100.0

net, u0, _ = build_sir_network(β, γ)
df = simulate_deterministic(net, u0, (0.0, tmax), saveat = 0.2, rates = [β, γ])

anim = @animate for i in 1:length(df.time)
    bar(
        ["S", "I", "R"],
        [df.S[i], df.I[i], df.R[i]],
        ylims = (0, 1000),
        title = "Time = $(round(df.time[i], digits=1))",
        ylabel = "Population",
        legend = false,
    )
end

gif(anim, plotsdir("sir_animation.gif"), fps = 10)
println("Анимация сохранена в plots/sir_animation.gif")
