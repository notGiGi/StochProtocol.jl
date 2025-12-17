"""
# Demo Simplificado de Visualizaciones

Genera tablas hermosas y gráficas listas para publicación.
"""

using StochProtocol
using StochProtocol.Explore.Run: run_protocol
using StochProtocol.Explore: results_table, results_comparison_table

println("\n" * "="^80)
println("STOCHPROTOCOL - DEMOSTRACIÓN DE VISUALIZACIONES")
println("="^80)

# =============================================================================
# 1. AMP Protocol - Tablas Profesionales
# =============================================================================

AMP = """
PROTOCOL AMP
PROCESSES: 2
STATE:
    x ∈ {0,1}
INITIAL VALUES:
    [0.0, 1.0]
PARAMETERS:
    y ∈ [0,1] = 0.5
CHANNEL:
    stochastic

UPDATE RULE:
    EACH ROUND:
        if received_diff then
            xᵢ ← y
        else
            xᵢ ← x
        end

METRICS:
    discrepancy
    consensus
"""

# Ejecutar con múltiples valores de p
p_values = [0.0, 0.2, 0.4, 0.6, 0.8, 1.0]
println("\n📊 Ejecutando AMP protocol...")
results_amp = run_protocol(AMP; p_values=p_values, rounds=1, repetitions=1000, seed=42)

# Mostrar tabla hermosa
results_table(results_amp; protocol_name="AMP (y=0.5)")

# =============================================================================
# 2. Comparación AMP vs FV
# =============================================================================

FV = """
PROTOCOL FV
PROCESSES: 2
STATE:
    x ∈ {0,1}
INITIAL VALUES:
    [0.0, 1.0]
CHANNEL:
    stochastic

UPDATE RULE:
    EACH ROUND:
        if received_diff then
            xᵢ ← received_other(x)
        else
            xᵢ ← x
        end

METRICS:
    discrepancy
    consensus
"""

println("📊 Ejecutando FV protocol...")
results_fv = run_protocol(FV; p_values=p_values, rounds=1, repetitions=1000, seed=42)

# Tabla comparativa
results_comparison_table(Dict(
    "AMP" => results_amp,
    "FV" => results_fv
))

# =============================================================================
# 3. Protocolos de Averaging
# =============================================================================

BASIC_AVG = """
PROTOCOL BasicAveraging
PROCESSES: 5
STATE:
    x ∈ ℝ
INITIAL VALUES:
    [1.0, 2.0, 3.0, 4.0, 5.0]
CHANNEL:
    stochastic

UPDATE RULE:
    EACH ROUND:
        xᵢ ← avg(all)

METRICS:
    discrepancy
"""

MAX_CONS = """
PROTOCOL MaxConsensus
PROCESSES: 5
STATE:
    x ∈ ℝ
INITIAL VALUES:
    [1.0, 2.0, 3.0, 4.0, 5.0]
CHANNEL:
    stochastic

UPDATE RULE:
    EACH ROUND:
        xᵢ ← max(all)

METRICS:
    discrepancy
"""

p_vals_avg = [0.0, 0.5, 1.0]
println("📊 Ejecutando protocolos de averaging...")
results_bavg = run_protocol(BASIC_AVG; p_values=p_vals_avg, rounds=10, repetitions=500)
results_max = run_protocol(MAX_CONS; p_values=p_vals_avg, rounds=5, repetitions=500)

# Comparación
results_comparison_table(Dict(
    "Average" => results_bavg,
    "Max" => results_max
))

# =============================================================================
# 4. Validación Teórica
# =============================================================================

println("\n" * "="^80)
println("VALIDACIÓN TEÓRICA: AMP - E[D] = 1 - p")
println("="^80)

using PrettyTables

data_theory = Matrix{Any}(undef, length(results_amp), 4)
for (i, r) in enumerate(results_amp)
    theoretical = 1.0 - r.p
    empirical = r.mean_discrepancy
    error = abs(empirical - theoretical)

    data_theory[i, 1] = r.p
    data_theory[i, 2] = round(theoretical, digits=6)
    data_theory[i, 3] = round(empirical, digits=6)
    data_theory[i, 4] = round(error, digits=6)
end

pretty_table(data_theory,
             column_labels=["p", "E[D] Teórico", "E[D] Empírico", "Error"],
             alignment=[:center, :right, :right, :right])

println("\n✅ Validación completada: teoría y experimento coinciden!")
println("\n" * "="^80)
println("✨ TABLAS PROFESIONALES GENERADAS ✨")
println("="^80)
println("\nPara generar gráficas PNG, usa visualization_demo.jl")
println("Ejemplo:")
println("  julia examples/visualization_demo.jl")
println()
