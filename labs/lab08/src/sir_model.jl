using ResumableFunctions, ConcurrentSim, Distributions, DataFrames, Random

# Вспомогательные функции для массивов статистики
function increment!(a::Array{Int64})
    push!(a, a[end] + 1)
end
function decrement!(a::Array{Int64})
    push!(a, a[end] - 1)
end
function carryover!(a::Array{Int64})
    push!(a, a[end])
end

# Структура агента
mutable struct SIRPerson
    id::Int64
    status::Symbol  # :S, :I, :R
end

# Структура модели
mutable struct SIRModel
    sim::ConcurrentSim.Simulation
    β::Float64
    c::Float64
    γ::Float64
    ta::Array{Float64}
    Sa::Array{Int64}
    Ia::Array{Int64}
    Ra::Array{Int64}
    allIndividuals::Array{SIRPerson}
end

# Обновление статистики при заражении
function infection_update!(sim::ConcurrentSim.Simulation, m::SIRModel)
    push!(m.ta, ConcurrentSim.now(sim))
    decrement!(m.Sa)
    increment!(m.Ia)
    carryover!(m.Ra)
end

# Обновление статистики при выздоровлении
function recovery_update!(sim::ConcurrentSim.Simulation, m::SIRModel)
    push!(m.ta, ConcurrentSim.now(sim))
    carryover!(m.Sa)
    decrement!(m.Ia)
    increment!(m.Ra)
end

# Жизненный цикл одного агента
@resumable function live(env::ConcurrentSim.Simulation, individual::SIRPerson, m::SIRModel)
    while individual.status == :S
        @yield timeout(env, rand(Exponential(1/m.c)))
        # выбираем случайного собеседника (не себя)
        alter = individual
        N = length(m.allIndividuals)
        while alter == individual
            idx = rand(DiscreteUniform(1, N))
            alter = m.allIndividuals[idx]
        end
        if alter.status == :I
            if rand() < m.β
                individual.status = :I
                infection_update!(env, m)
            end
        end
    end
    if individual.status == :I
        @yield timeout(env, rand(Exponential(1/m.γ)))
        individual.status = :R
        recovery_update!(env, m)
    end
end

# Создание модели
function MakeSIRModel(u0, p)
    S0, I0, R0 = u0
    N = S0 + I0 + R0
    β, c, γ = p
    sim = ConcurrentSim.Simulation()
    allIndividuals = SIRPerson[]
    id = 1
    for i in 1:S0
        push!(allIndividuals, SIRPerson(id, :S))
        id += 1
    end
    for i in 1:I0
        push!(allIndividuals, SIRPerson(id, :I))
        id += 1
    end
    for i in 1:R0
        push!(allIndividuals, SIRPerson(id, :R))
        id += 1
    end
    ta = [0.0]
    Sa = [S0]
    Ia = [I0]
    Ra = [R0]
    return SIRModel(sim, β, c, γ, ta, Sa, Ia, Ra, allIndividuals)
end

# Активация всех агентов (запуск их процессов)
function activate(m::SIRModel)
    for individual in m.allIndividuals
        @process live(m.sim, individual, m)
    end
end

# Запуск симуляции до времени tf
function sir_run(m::SIRModel, tf::Float64)
    ConcurrentSim.run(m.sim, tf)
end

# Сбор результатов в DataFrame
function out(m::SIRModel)
    df = DataFrame()
    df.t = m.ta
    df.S = m.Sa
    df.I = m.Ia
    df.R = m.Ra
    return df
end
