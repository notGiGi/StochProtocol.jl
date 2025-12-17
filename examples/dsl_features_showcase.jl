"""
# DSL Features Showcase

This file demonstrates all the extended DSL features added to StochProtocol:
- Arithmetic operations (+, -, *, /)
- Aggregation functions (sum, avg, min, max, count)
- Comparison predicates (>, <, >=, <=, ==, !=)
- Logical operators (and, or, not)
- Custom parameters
- Numeric literals

Each example is a complete, runnable protocol that can be executed with run_protocol().
"""

using StochProtocol
using StochProtocol.Explore.Run: run_protocol

# =============================================================================
# Example 1: Min-Max Midpoint Protocol
# Demonstrates: Arithmetic operations, aggregations
# =============================================================================

MINMAX_PROTOCOL = """
PROTOCOL MinMaxMidpoint
PROCESSES: 5
STATE:
    x ∈ ℝ
INITIAL VALUES:
    [1.0, 3.0, 5.0, 7.0, 9.0]
CHANNEL:
    stochastic

UPDATE RULE:
    EACH ROUND:
        xᵢ ← min(all) + max(all)

METRICS:
    discrepancy
    consensus
"""

println("Example 1: Min-Max Midpoint")
println("=" ^ 60)
result1 = run_protocol(MINMAX_PROTOCOL; p_values=[1.0], rounds=1, repetitions=1)
println("Initial values: [1.0, 3.0, 5.0, 7.0, 9.0]")
println("After 1 round: all nodes converge to min + max = 10.0")
println("Consensus achieved: $(result1[1].consensus_probability ≈ 1.0)")
println()

# =============================================================================
# Example 2: Threshold-Based Update
# Demonstrates: Comparison predicates, conditionals
# =============================================================================

THRESHOLD_PROTOCOL = """
PROTOCOL ThresholdUpdate
PROCESSES: 4
STATE:
    x ∈ ℝ
INITIAL VALUES:
    [2.0, 4.0, 6.0, 8.0]
PARAMETERS:
    threshold = 5.0
CHANNEL:
    stochastic

UPDATE RULE:
    EACH ROUND:
        if xᵢ < threshold then
            xᵢ ← threshold
        else
            xᵢ ← xᵢ
        end

METRICS:
    discrepancy
"""

println("Example 2: Threshold-Based Update")
println("=" ^ 60)
result2 = run_protocol(THRESHOLD_PROTOCOL; p_values=[1.0], rounds=1, repetitions=1)
println("Initial values: [2.0, 4.0, 6.0, 8.0], threshold=5.0")
println("After 1 round: nodes below 5.0 update to 5.0")
println("Expected discrepancy: 8.0 - 5.0 = 3.0")
println("Actual discrepancy: $(result2[1].mean_discrepancy)")
println()

# =============================================================================
# Example 3: Majority-Based Consensus
# Demonstrates: Logical operators, aggregations, comparisons
# =============================================================================

MAJORITY_PROTOCOL = """
PROTOCOL MajorityConsensus
PROCESSES: 5
STATE:
    x ∈ {0,1}
INITIAL VALUES:
    [0.0, 0.0, 1.0, 1.0, 1.0]
CHANNEL:
    stochastic

UPDATE RULE:
    EACH ROUND:
        if received_any and count(all) > 2 then
            xᵢ ← avg(all)
        else
            xᵢ ← xᵢ
        end

METRICS:
    consensus
"""

println("Example 3: Majority-Based Consensus")
println("=" ^ 60)
result3 = run_protocol(MAJORITY_PROTOCOL; p_values=[1.0], rounds=1, repetitions=1)
println("Initial values: [0, 0, 1, 1, 1] (majority is 1)")
println("After 1 round with full communication: avg = 3/5 = 0.6")
println("All nodes converge to 0.6")
println("Consensus probability: $(result3[1].consensus_probability)")
println()

# =============================================================================
# Example 4: Adaptive Averaging
# Demonstrates: Multiple aggregations in one rule
# =============================================================================

ADAPTIVE_PROTOCOL = """
PROTOCOL AdaptiveAveraging
PROCESSES: 3
STATE:
    x ∈ ℝ
INITIAL VALUES:
    [1.0, 5.0, 9.0]
CHANNEL:
    stochastic

UPDATE RULE:
    EACH ROUND:
        if max(inbox) > 6 then
            xᵢ ← max(inbox)
        else
            xᵢ ← avg(all)
        end

METRICS:
    consensus
"""

println("Example 4: Adaptive Averaging")
println("=" ^ 60)
result4 = run_protocol(ADAPTIVE_PROTOCOL; p_values=[1.0], rounds=1, repetitions=1)
println("Initial values: [1, 5, 9]")
println("Node 1: max(inbox)=9 > 6, so xᵢ ← 9")
println("Node 2: max(inbox)=9 > 6, so xᵢ ← 9")
println("Node 3: max(inbox)=5 < 6, so xᵢ ← avg(all)=5")
println("Result: nodes don't fully converge")
println("Consensus probability: $(result4[1].consensus_probability)")
println()

# =============================================================================
# Example 5: Count-Based Selection
# Demonstrates: Count aggregation, equality comparison
# =============================================================================

COUNT_PROTOCOL = """
PROTOCOL CountBasedSelection
PROCESSES: 3
STATE:
    x ∈ ℝ
INITIAL VALUES:
    [1.0, 1.0, 1.0]
CHANNEL:
    stochastic

UPDATE RULE:
    EACH ROUND:
        if count(inbox) == 2 then
            xᵢ ← sum(inbox)
        else
            xᵢ ← xᵢ
        end

METRICS:
    consensus
"""

println("Example 5: Count-Based Selection")
println("=" ^ 60)
result5 = run_protocol(COUNT_PROTOCOL; p_values=[1.0], rounds=1, repetitions=1)
println("Initial values: all nodes at 1.0")
println("With p=1.0, each node receives exactly 2 messages")
println("Update: xᵢ ← sum(inbox) = 2.0")
println("All converge to 2.0")
println("Consensus probability: $(result5[1].consensus_probability)")
println()

# =============================================================================
# Example 6: Parameter-Driven Protocol
# Demonstrates: Custom parameter usage in expressions
# =============================================================================

PARAM_PROTOCOL = """
PROTOCOL ParameterDriven
PROCESSES: 2
STATE:
    x ∈ ℝ
INITIAL VALUES:
    [0.0, 10.0]
PARAMETERS:
    meeting_point = 5.0
CHANNEL:
    stochastic

UPDATE RULE:
    EACH ROUND:
        if received_diff then
            xᵢ ← meeting_point
        else
            xᵢ ← xᵢ
        end

METRICS:
    consensus
"""

println("Example 6: Parameter-Driven Protocol")
println("=" ^ 60)
result6 = run_protocol(PARAM_PROTOCOL; p_values=[1.0], rounds=1, repetitions=1)
println("Initial values: [0, 10], meeting_point=5.0")
println("With p=1.0, both nodes receive different values")
println("Both update to meeting_point = 5.0")
println("Consensus probability: $(result6[1].consensus_probability)")
println()

# =============================================================================
# Summary
# =============================================================================

println("=" ^ 60)
println("DSL FEATURES SUMMARY")
println("=" ^ 60)
println("✓ Arithmetic: +, -, *, /")
println("✓ Aggregations: sum, avg, min, max, count")
println("✓ Comparisons: >, <, >=, <=, ==, !=")
println("✓ Logic: and, or, not")
println("✓ Literals: numeric constants (1.0, 2.5, etc.)")
println("✓ Parameters: custom named parameters")
println()
println("All examples executed successfully!")
