using Literate

files = [
    "sir_run_basic-literate.jmd",
    "sir_scan_beta-literate.jmd",
    "sir_migration_effect-literate.jmd",
    "sir_optimize_parameters-literate.jmd",
    "sir_visualize_dynamics-literate.jmd"
]

for file in files
    full_path = joinpath("scripts", file)
    base = splitext(file)[1]
    println("Обработка: $file")
    Literate.script(full_path, "scripts"; credit=false)
    Literate.notebook(full_path, "notebooks"; credit=false)
    Literate.markdown(full_path, "markdown"; flavor=Literate.QuartoFlavor(), credit=false)
end
