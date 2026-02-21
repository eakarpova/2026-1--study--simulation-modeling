using DrWatson
@quickactivate "../../project"
using DifferentialEquations
using DataFrames
using StatsPlots
using LaTeXStrings
using Plots
using Statistics
using FFTW

script_name = splitext(basename(PROGRAM_FILE))[1]
mkpath(plotsdir(script_name))
mkpath(datadir(script_name))

function lotka_volterra!(du, u, p, t)
    x, y = u
    α, β, δ, γ = p
    @inbounds begin
        du[1] = α*x - β*x*y
        du[2] = δ*x*y - γ*y
    end
    nothing
end

p_lv = [0.1, 0.02, 0.01, 0.3]
u0_lv = [40.0, 9.0]
tspan_lv = (0.0, 200.0)
dt_lv = 0.01

prob_lv = ODEProblem(lotka_volterra!, u0_lv, tspan_lv, p_lv)
sol_lv = solve(prob_lv, dt = dt_lv, Tsit5(), reltol=1e-8, abstol=1e-10, saveat=0.1, dense=true)

df_lv = DataFrame()
df_lv[!, :t] = sol_lv.t
df_lv[!, :prey] = [u[1] for u in sol_lv.u]
df_lv[!, :predator] = [u[2] for u in sol_lv.u]

df_lv[!, :dprey_dt] = p_lv[1] .* df_lv.prey .- p_lv[2] .* df_lv.prey .* df_lv.predator
df_lv[!, :dpredator_dt] = p_lv[3] .* df_lv.prey .* df_lv.predator .- p_lv[4] .* df_lv.predator

println("="^60)
println("Модель Лотки-Вольтерры (хищник-жертва)")
println("="^60)
println("\nПараметры модели:")
println("α = ", p_lv[1])
println("β = ", p_lv[2])
println("δ = ", p_lv[3])
println("γ = ", p_lv[4])
println("\nНачальные условия: x0 = ", u0_lv[1], ", y0 = ", u0_lv[2])

x_star = p_lv[4] / p_lv[3]
y_star = p_lv[1] / p_lv[2]
println("\nСтационарные точки: x* = ", round(x_star, digits=3), ", y* = ", round(y_star, digits=3))

plt1 = plot(df_lv.t, [df_lv.prey df_lv.predator],
            label=[L"Жертвы (x)" L"Хищники (y)"],
            xlabel="Время", ylabel="Популяция",
            title="Модель Лотки-Вольтерры: Динамика популяций",
            linewidth=2, legend=:topright, grid=true, size=(900, 500),
            color=[:green :red])
hline!(plt1, [x_star], color=:green, linestyle=:dash, alpha=0.5, label="x*")
hline!(plt1, [y_star], color=:red, linestyle=:dash, alpha=0.5, label="y*")

plt2 = plot(df_lv.prey, df_lv.predator,
            label="Фазовая траектория",
            xlabel="Жертвы (x)", ylabel="Хищники (y)",
            title="Фазовый портрет",
            color=:blue, linewidth=1.5, grid=true, size=(800, 600),
            legend=:topright)
scatter!(plt2, [x_star], [y_star], color=:black, markersize=8, label="Стационарная точка")

x_range = LinRange(0, maximum(df_lv.prey)*1.1, 100)
y_nullcline = p_lv[1] ./ (p_lv[2] .* x_range)
plot!(plt2, x_range, y_nullcline, color=:red, linestyle=:dash, linewidth=1.5, label="Изоклина хищников")

y_range = LinRange(0, maximum(df_lv.predator)*1.1, 100)
x_nullcline = p_lv[4] ./ (p_lv[3] .* ones(length(y_range)))
plot!(plt2, x_nullcline, y_range, color=:green, linestyle=:dash, linewidth=1.5, label="Изоклина жертв")

savefig(plt1, plotsdir(script_name, "lv_dynamics.png"))
savefig(plt2, plotsdir(script_name, "lv_phase_portrait.png"))

println("\nМоделирование завершено успешно!")
