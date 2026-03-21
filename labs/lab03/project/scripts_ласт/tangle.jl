using Literate

# Папка с исходными литературными файлами
jmd_dir = "scripts"

# Список всех литературных файлов
files = [
    "daisyworld-literate.jmd",
    "daisyworld-animate-literate.jmd",
    "daisyworld-count-literate.jmd",
    "daisyworld-luminosity-literate.jmd",
    "daisyworld-param-literate.jmd",
    "daisyworld-count-param-literate.jmd",
    "daisyworld-luminosity-param-literate.jmd"
]

for file in files
    full_path = joinpath(jmd_dir, file)
    base = splitext(file)[1]

    println("Обработка: $file")

    # Генерация чистого кода
    Literate.script(full_path, "scripts"; credit=false)

    # Генерация Jupyter notebook
    Literate.notebook(full_path, "notebooks"; credit=false)

    # Генерация Quarto документа
    Literate.markdown(full_path, "markdown"; flavor=Literate.QuartoFlavor(), credit=false, execute=false);
end
