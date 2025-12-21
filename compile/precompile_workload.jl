# Precompile workload - runs common operations to bake them into sysimage

using StochProtocol
using Plots
using PlutoUI

# Define a simple protocol
protocol = Protocol("""
PROTOCOL TestProtocol
PROCESSES: 5
STATE: x ∈ ℝ
INITIAL: xᵢ = i
CHANNEL: stochastic

UPDATE RULE:
    EACH ROUND:
        xᵢ ← avg(inbox_with_self)

METRICS:
    discrepancy
    consensus
""")

# Run protocol (forces compilation of all hot paths)
results = run_protocol(protocol;
    p_values = [0.7],
    rounds = 10,
    repetitions = 100
)

# Generate plots (compiles plotting code)
plot_discrepancy_vs_p(results)

# Generate tables
results_table(results)

# Advanced features
using StochProtocol: Ring, convergence_rate, time_to_epsilon_consensus

# Use topologies
topo = Ring()
neighbors(topo, 1, 5)

# Use convergence analysis
disc = results[1].discrepancy_trace
convergence_rate(disc)
time_to_epsilon_consensus(disc, 0.01)

println("✅ Precompilation workload completed")
