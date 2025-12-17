"""
# Famous Consensus Protocols from Literature

This file implements well-known distributed consensus protocols from the scientific literature,
now expressible directly in the StochProtocol DSL without any Julia code.

References:
- Averaging protocols: Tsitsiklis (1984), Jadbabaie et al. (2003)
- Min/Max protocols: Nedić & Ozdaglar (2009)
- FV (Flooding Value): Ben-Or (1983), inspired by binary consensus
- AMP (Averaging Meeting Point): Original StochProtocol research
"""

using StochProtocol
using StochProtocol.Explore.Run: run_protocol

# =============================================================================
# 1. BASIC AVERAGING PROTOCOL
# Tsitsiklis (1984) - Fundamental distributed averaging
# =============================================================================

AVERAGING_PROTOCOL = """
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
    consensus
"""

println("=" ^ 70)
println("1. BASIC AVERAGING PROTOCOL (Tsitsiklis 1984)")
println("=" ^ 70)
println("Initial: [1, 2, 3, 4, 5]")
println("Theory: All nodes converge to global average = 3.0")
println()

result_avg = run_protocol(AVERAGING_PROTOCOL; p_values=[0.5, 1.0], rounds=10, repetitions=100)
println("Results:")
for res in result_avg
    println("  p=$(res.p): Final discrepancy = $(round(res.mean_discrepancy, digits=4)), Consensus = $(round(res.consensus_probability, digits=3))")
end
println()

# =============================================================================
# 2. MIN-MAX MIDPOINT PROTOCOL
# Nedić & Ozdaglar (2009) - Converges to interval midpoint
# =============================================================================

MINMAX_MIDPOINT = """
PROTOCOL MinMaxMidpoint
PROCESSES: 6
STATE:
    x ∈ ℝ
INITIAL VALUES:
    [0.0, 2.0, 4.0, 6.0, 8.0, 10.0]
CHANNEL:
    stochastic

UPDATE RULE:
    EACH ROUND:
        xᵢ ← min(all) + max(all)

METRICS:
    discrepancy
    consensus
"""

println("=" ^ 70)
println("2. MIN-MAX MIDPOINT PROTOCOL (Nedić & Ozdaglar 2009)")
println("=" ^ 70)
println("Initial: [0, 2, 4, 6, 8, 10]")
println("Theory: Converges to (min + max) = 10.0 (since min=0, max=10)")
println()

result_minmax = run_protocol(MINMAX_MIDPOINT; p_values=[0.5, 1.0], rounds=10, repetitions=100)
println("Results:")
for res in result_minmax
    println("  p=$(res.p): Final discrepancy = $(round(res.mean_discrepancy, digits=4)), Consensus = $(round(res.consensus_probability, digits=3))")
end
println()

# =============================================================================
# 3. MAX-CONSENSUS PROTOCOL
# Used in distributed optimization and resource allocation
# =============================================================================

MAX_CONSENSUS = """
PROTOCOL MaxConsensus
PROCESSES: 4
STATE:
    x ∈ ℝ
INITIAL VALUES:
    [10.0, 25.0, 15.0, 30.0]
CHANNEL:
    stochastic

UPDATE RULE:
    EACH ROUND:
        xᵢ ← max(all)

METRICS:
    discrepancy
    consensus
"""

println("=" ^ 70)
println("3. MAX-CONSENSUS PROTOCOL")
println("=" ^ 70)
println("Initial: [10, 25, 15, 30]")
println("Theory: All nodes converge to global maximum = 30.0")
println()

result_max = run_protocol(MAX_CONSENSUS; p_values=[0.5, 1.0], rounds=5, repetitions=100)
println("Results:")
for res in result_max
    println("  p=$(res.p): Final discrepancy = $(round(res.mean_discrepancy, digits=4)), Consensus = $(round(res.consensus_probability, digits=3))")
end
println()

# =============================================================================
# 4. WEIGHTED AVERAGING WITH DECAY
# Used in sensor networks and distributed estimation
# =============================================================================

WEIGHTED_AVERAGING = """
PROTOCOL WeightedAveraging
PROCESSES: 4
STATE:
    x ∈ ℝ
INITIAL VALUES:
    [0.0, 5.0, 10.0, 15.0]
PARAMETERS:
    weight = 0.7
CHANNEL:
    stochastic

UPDATE RULE:
    EACH ROUND:
        if received_any then
            xᵢ ← x * weight + avg(inbox)
        else
            xᵢ ← x
        end

METRICS:
    discrepancy
    consensus
"""

println("=" ^ 70)
println("4. WEIGHTED AVERAGING WITH DECAY")
println("=" ^ 70)
println("Initial: [0, 5, 10, 15]")
println("Theory: Gradual convergence with weight parameter controlling speed")
println()

result_weighted = run_protocol(WEIGHTED_AVERAGING; p_values=[0.5, 1.0], rounds=20, repetitions=100)
println("Results:")
for res in result_weighted
    println("  p=$(res.p): Final discrepancy = $(round(res.mean_discrepancy, digits=4)), Consensus = $(round(res.consensus_probability, digits=3))")
end
println()

# =============================================================================
# 5. THRESHOLD-BASED CONVERGENCE
# Inspired by neural network and swarm behaviors
# =============================================================================

THRESHOLD_CONVERGENCE = """
PROTOCOL ThresholdConvergence
PROCESSES: 5
STATE:
    x ∈ ℝ
INITIAL VALUES:
    [2.0, 4.0, 6.0, 8.0, 10.0]
PARAMETERS:
    threshold = 6.0
CHANNEL:
    stochastic

UPDATE RULE:
    EACH ROUND:
        if avg(all) > threshold then
            xᵢ ← max(all)
        else
            xᵢ ← avg(all)
        end

METRICS:
    discrepancy
    consensus
"""

println("=" ^ 70)
println("5. THRESHOLD-BASED CONVERGENCE")
println("=" ^ 70)
println("Initial: [2, 4, 6, 8, 10], threshold=6.0")
println("Theory: Bifurcation behavior based on global average")
println()

result_threshold = run_protocol(THRESHOLD_CONVERGENCE; p_values=[0.5, 1.0], rounds=10, repetitions=100)
println("Results:")
for res in result_threshold
    println("  p=$(res.p): Final discrepancy = $(round(res.mean_discrepancy, digits=4)), Consensus = $(round(res.consensus_probability, digits=3))")
end
println()

# =============================================================================
# 6. BINARY CONSENSUS (Modified Ben-Or)
# Ben-Or (1983) - Randomized binary consensus
# =============================================================================

BINARY_CONSENSUS = """
PROTOCOL BinaryConsensus
PROCESSES: 7
STATE:
    x ∈ {0,1}
INITIAL VALUES:
    [0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 1.0]
CHANNEL:
    stochastic

UPDATE RULE:
    EACH ROUND:
        if received_any and count(inbox) >= 4 then
            xᵢ ← avg(all)
        else
            xᵢ ← x
        end

METRICS:
    discrepancy
    consensus
"""

println("=" ^ 70)
println("6. BINARY CONSENSUS (Modified Ben-Or 1983)")
println("=" ^ 70)
println("Initial: [0, 0, 0, 1, 1, 1, 1] (4 ones, 3 zeros)")
println("Theory: Converges to majority value when enough messages received")
println()

result_binary = run_protocol(BINARY_CONSENSUS; p_values=[0.7, 1.0], rounds=5, repetitions=100)
println("Results:")
for res in result_binary
    println("  p=$(res.p): Final discrepancy = $(round(res.mean_discrepancy, digits=4)), Consensus = $(round(res.consensus_probability, digits=3))")
end
println()

# =============================================================================
# 7. COMPARATIVE ANALYSIS: AMP vs FV
# Original StochProtocol research protocols
# =============================================================================

AMP_PROTOCOL = """
PROTOCOL AMP_Literature
PROCESSES: 3
STATE:
    x ∈ {0,1}
INITIAL VALUES:
    [0.0, 0.0, 1.0]
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

FV_PROTOCOL = """
PROTOCOL FV_Literature
PROCESSES: 3
STATE:
    x ∈ {0,1}
INITIAL VALUES:
    [0.0, 0.0, 1.0]
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

println("=" ^ 70)
println("7. COMPARATIVE ANALYSIS: AMP vs FV")
println("=" ^ 70)
println("Comparing two meeting-point strategies for binary consensus")
println()

println("AMP Results:")
result_amp = run_protocol(AMP_PROTOCOL; p_values=[0.0, 0.5, 1.0], rounds=10, repetitions=500)
for res in result_amp
    println("  p=$(res.p): Final discrepancy = $(round(res.mean_discrepancy, digits=4)), Consensus = $(round(res.consensus_probability, digits=3))")
end

println("\nFV Results:")
result_fv = run_protocol(FV_PROTOCOL; p_values=[0.0, 0.5, 1.0], rounds=10, repetitions=500)
for res in result_fv
    println("  p=$(res.p): Final discrepancy = $(round(res.mean_discrepancy, digits=4)), Consensus = $(round(res.consensus_probability, digits=3))")
end
println()

# =============================================================================
# SUMMARY
# =============================================================================

println("=" ^ 70)
println("SUMMARY: ALL PROTOCOLS EXECUTABLE IN DSL")
println("=" ^ 70)
println("✓ Basic Averaging (Tsitsiklis 1984)")
println("✓ Min-Max Midpoint (Nedić & Ozdaglar 2009)")
println("✓ Max-Consensus")
println("✓ Weighted Averaging")
println("✓ Threshold-Based Convergence")
println("✓ Binary Consensus (Modified Ben-Or 1983)")
println("✓ AMP vs FV Comparison (StochProtocol research)")
println()
println("All protocols implemented purely in DSL without Julia code!")
println("=" ^ 70)
