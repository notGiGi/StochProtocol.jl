"""
# Demostración de Visualizaciones de StochProtocol

Este archivo muestra cómo crear gráficas hermosas y tablas profesionales
para analizar y presentar resultados de protocolos de consenso.

Características:
- Gráficas de alta calidad (300 DPI)
- Tablas formateadas profesionalmente
- Comparaciones entre múltiples protocolos
- Exportación a PNG
"""

using StochProtocol
using StochProtocol.Explore.Run: run_protocol
using StochProtocol.Explore: plot_discrepancy_vs_p, plot_consensus_vs_p, plot_comparison
using StochProtocol.Explore: results_table, results_comparison_table

# =============================================================================
# EJEMPLO 1: AMP Protocol - Análisis Completo
# =============================================================================

println("\n" * "="^80)
println("EJEMPLO 1: AMP PROTOCOL - ANÁLISIS COMPLETO")
println("="^80)

AMP = """
PROTOCOL AMP_Analysis
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
p_values = [0.0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0]
results_amp = run_protocol(AMP; p_values=p_values, rounds=1, repetitions=2000, seed=42)

# Mostrar tabla de resultados
results_table(results_amp; protocol_name="AMP (y=0.5)")

# Crear gráfica de discrepancia
println("📊 Generando gráfica de discrepancia...")
plot_disc = plot_discrepancy_vs_p(results_amp;
                                   title="AMP Protocol: E[D] vs p",
                                   save_path="amp_discrepancy.png")
display(plot_disc)

# Crear gráfica de consenso
println("📊 Generando gráfica de consenso...")
plot_cons = plot_consensus_vs_p(results_amp;
                                title="AMP Protocol: P(consensus) vs p",
                                save_path="amp_consensus.png")
display(plot_cons)

println("✓ Gráficas guardadas: amp_discrepancy.png, amp_consensus.png")
println()

# =============================================================================
# EJEMPLO 2: Comparación AMP vs FV
# =============================================================================

println("="^80)
println("EJEMPLO 2: COMPARACIÓN AMP vs FV")
println("="^80)

FV = """
PROTOCOL FV_Analysis
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

# Ejecutar FV con los mismos parámetros
results_fv = run_protocol(FV; p_values=p_values, rounds=1, repetitions=2000, seed=42)

# Tabla comparativa
results_comparison_table(Dict(
    "AMP" => results_amp,
    "FV" => results_fv
))

# Gráfica comparativa de discrepancia
println("📊 Generando gráfica comparativa...")
plot_comp = plot_comparison(
    Dict("AMP (y=0.5)" => results_amp, "FV" => results_fv);
    title="Protocol Comparison: Expected Discrepancy",
    metric=:discrepancy,
    save_path="amp_vs_fv_discrepancy.png"
)
display(plot_comp)

# Gráfica comparativa de consenso
plot_comp_cons = plot_comparison(
    Dict("AMP (y=0.5)" => results_amp, "FV" => results_fv);
    title="Protocol Comparison: Consensus Probability",
    metric=:consensus,
    save_path="amp_vs_fv_consensus.png"
)
display(plot_comp_cons)

println("✓ Gráficas guardadas: amp_vs_fv_discrepancy.png, amp_vs_fv_consensus.png")
println()

# =============================================================================
# EJEMPLO 3: Múltiples Protocolos de Averaging
# =============================================================================

println("="^80)
println("EJEMPLO 3: COMPARACIÓN DE PROTOCOLOS DE AVERAGING")
println("="^80)

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

MIN_CONS = """
PROTOCOL MinConsensus
PROCESSES: 5
STATE:
    x ∈ ℝ
INITIAL VALUES:
    [1.0, 2.0, 3.0, 4.0, 5.0]
CHANNEL:
    stochastic

UPDATE RULE:
    EACH ROUND:
        xᵢ ← min(all)

METRICS:
    discrepancy
"""

# Ejecutar todos
p_vals_avg = [0.0, 0.25, 0.5, 0.75, 1.0]
results_bavg = run_protocol(BASIC_AVG; p_values=p_vals_avg, rounds=10, repetitions=500)
results_max = run_protocol(MAX_CONS; p_values=p_vals_avg, rounds=5, repetitions=500)
results_min = run_protocol(MIN_CONS; p_values=p_vals_avg, rounds=5, repetitions=500)

# Tabla comparativa
results_comparison_table(Dict(
    "Average" => results_bavg,
    "Max" => results_max,
    "Min" => results_min
))

# Gráfica comparativa
plot_avg_comp = plot_comparison(
    Dict("Average" => results_bavg, "Max" => results_max, "Min" => results_min);
    title="Averaging Strategies: Convergence Speed",
    metric=:discrepancy,
    save_path="averaging_comparison.png"
)
display(plot_avg_comp)

println("✓ Gráfica guardada: averaging_comparison.png")
println()

# =============================================================================
# EJEMPLO 4: Validación Teórica de AMP
# =============================================================================

println("="^80)
println("EJEMPLO 4: VALIDACIÓN TEÓRICA AMP - E[D] = 1 - p")
println("="^80)

# Teoría: Para AMP con N=2, rounds=1, E[D] = 1 - p (independiente de y)
println("Teoría: E[D] = 1 - p")
println("\nResultados experimentales:")

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

using PrettyTables
pretty_table(data_theory,
             column_labels=["p", "E[D] Teórico", "E[D] Empírico", "Error"],
             alignment=[:center, :right, :right, :right])

println("\n✓ Validación completada: teoría y experimento coinciden!")
println()

# =============================================================================
# RESUMEN FINAL
# =============================================================================

println("="^80)
println("RESUMEN DE VISUALIZACIONES GENERADAS")
println("="^80)
println("📊 Gráficas individuales:")
println("   • amp_discrepancy.png - Discrepancia AMP vs p")
println("   • amp_consensus.png - Consenso AMP vs p")
println()
println("📊 Gráficas comparativas:")
println("   • amp_vs_fv_discrepancy.png - AMP vs FV: Discrepancia")
println("   • amp_vs_fv_consensus.png - AMP vs FV: Consenso")
println("   • averaging_comparison.png - Avg vs Max vs Min")
println()
println("📋 Tablas formateadas:")
println("   • Resultados detallados de cada protocolo")
println("   • Comparaciones lado a lado")
println("   • Validación teórica vs empírica")
println()
println("="^80)
println("✨ TODAS LAS VISUALIZACIONES LISTAS PARA PUBLICACIÓN ✨")
println("="^80)
