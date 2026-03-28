using DrWatson
@quickactivate "project"
using DataFrames, Plots, CSV, Statistics

file_path = joinpath(datadir(), "beta_scan_all.csv")
if !isfile(file_path)
    error("Файл не найден: $file_path")
end

df = CSV.read(file_path, DataFrame)

grouped = combine(groupby(df, :beta),
    :peak => mean => :mean_peak,
    :final_inf => mean => :mean_final_inf,
    :deaths => mean => :mean_deaths,
)

p1 = plot(grouped.beta, grouped.mean_peak, marker = :circle, label = "Пик эпидемии")
p2 = plot(grouped.beta, grouped.mean_final_inf, marker = :square, label = "Конечная доля инфицированных")
p3 = plot(grouped.beta, grouped.mean_deaths ./ 3000, marker = :diamond, label = "Доля умерших")

plot(p1, p2, p3, layout = (3,1), size = (800, 1000), xlabel = "β", ylabel = "Доля")
savefig(plotsdir("comprehensive_analysis.png"))
