using DrWatson
@quickactivate "../../project"
using DifferentialEquations
using DataFrames
using StatsPlots
using LaTeXStrings
using Plots
using Statistics

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

# Базовые параметры
p_base = [0.1, 0.02, 0.01, 0.3]
u0 = [40.0, 9.0]
tspan = (0.0, 200.0)
dt = 0.1

println("="^60)
println("ПАРАМЕТРИЧЕСКОЕ ИССЛЕДОВАНИЕ МОДЕЛИ ЛОТКИ–ВОЛЬТЕРРЫ")
println("="^60)

# ------------------------------------------------------------
# 1. Влияние α (скорость роста жертв)
# ------------------------------------------------------------
println("\n--- Влияние α (скорость роста жертв) ---")
α_values = [0.05, 0.1, 0.15, 0.2, 0.25]
results_α = []

for α in α_values
    p_test = [α, p_base[2], p_base[3], p_base[4]]
    prob = ODEProblem(lotka_volterra!, u0, tspan, p_test)
    sol = solve(prob, dt = dt, saveat=1.0)
    
    prey_mean = mean([u[1] for u in sol.u])
    predator_mean = mean([u[2] for u in sol.u])
    
    push!(results_α, (α=α, prey_mean=prey_mean, predator_mean=predator_mean))
    println("α = $α → средние: жертвы = $(round(prey_mean, digits=1)), хищники = $(round(predator_mean, digits=1))")
end

df_α = DataFrame(results_α)

p_α = plot(df_α.α, [df_α.prey_mean df_α.predator_mean],
           label=[L"Жертвы (x)" L"Хищники (y)"],
           xlabel="α", ylabel="Средняя популяция",
           title="Зависимость средних значений от α",
           linewidth=2, marker=:circle, legend=:topleft)
savefig(p_α, plotsdir(script_name, "lv_alpha_scan.png"))

# ------------------------------------------------------------
# 2. Влияние γ (смертность хищников)
# ------------------------------------------------------------
println("\n--- Влияние γ (смертность хищников) ---")
γ_values = [0.2, 0.25, 0.3, 0.35, 0.4]
results_γ = []

for γ in γ_values
    p_test = [p_base[1], p_base[2], p_base[3], γ]
    prob = ODEProblem(lotka_volterra!, u0, tspan, p_test)
    sol = solve(prob, dt = dt, saveat=1.0)
    
    prey_mean = mean([u[1] for u in sol.u])
    predator_mean = mean([u[2] for u in sol.u])
    
    push!(results_γ, (γ=γ, prey_mean=prey_mean, predator_mean=predator_mean))
    println("γ = $γ → средние: жертвы = $(round(prey_mean, digits=1)), хищники = $(round(predator_mean, digits=1))")
end

df_γ = DataFrame(results_γ)

p_γ = plot(df_γ.γ, [df_γ.prey_mean df_γ.predator_mean],
           label=[L"Жертвы (x)" L"Хищники (y)"],
           xlabel="γ", ylabel="Средняя популяция",
           title="Зависимость средних значений от γ",
           linewidth=2, marker=:circle, legend=:topleft)
savefig(p_γ, plotsdir(script_name, "lv_gamma_scan.png"))

# ------------------------------------------------------------
# 3. Сравнение фазовых портретов
# ------------------------------------------------------------
println("\n--- Сравнение фазовых портретов при разных α ---")

p_phase = plot(size=(800,600), legend=:topright)

for α in [0.08, 0.12, 0.16]
    p_test = [α, p_base[2], p_base[3], p_base[4]]
    prob = ODEProblem(lotka_volterra!, u0, tspan, p_test)
    sol = solve(prob, dt = dt)
    xs = [u[1] for u in sol.u]
    ys = [u[2] for u in sol.u]
    plot!(p_phase, xs, ys, label="α = $α", linewidth=1.5)
end

plot!(p_phase, xlabel="Жертвы (x)", ylabel="Хищники (y)",
      title="Фазовые портреты при разных α")
savefig(p_phase, plotsdir(script_name, "lv_phase_comparison.png"))

# ------------------------------------------------------------
println("\n✅ Параметрическое исследование Лотки–Вольтерры завершено!")
println("Графики сохранены в: plots/$(script_name)/")
