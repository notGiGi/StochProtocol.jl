# Examples using process-specific conditions and filtering
# Demonstrates: received_from, value_from, and filtered aggregations

using StochProtocol

println("="^70)
println("Process-Specific Conditions Examples")
println("="^70)

# Example 1: Coordinator Protocol
# Only process 1 coordinates; others follow process 1
println("\n1. Coordinator Protocol")
println("-"^70)

coordinator = Protocol("""
PROTOCOL Coordinator
PROCESSES: 5
STATE: x ∈ ℝ
INITIAL VALUES: [0.0, 1.0, 2.0, 3.0, 4.0]
CHANNEL: stochastic

UPDATE RULE:
    EACH ROUND:
        if received_from(1) then
            xᵢ ← value_from(1)
        else
            xᵢ ← x
        end

METRICS: discrepancy, consensus
""")

println("Running coordinator protocol...")
results_coord = run_protocol(coordinator; p_values=[0.5, 0.7, 0.9], rounds=3, repetitions=1000)
results_table(results_coord; protocol_name="Coordinator")

# Example 2: Trusted Nodes Protocol
# Only trust updates from processes 1 and 2
println("\n\n2. Trusted Nodes Protocol")
println("-"^70)

trusted = Protocol("""
PROTOCOL TrustedNodes
PROCESSES: 10
STATE: x ∈ ℝ
INITIAL: xᵢ = i / 10
CHANNEL: stochastic

UPDATE RULE:
    EACH ROUND:
        if received_from(1) or received_from(2) then
            xᵢ ← avg(inbox_from(1, 2))
        else
            xᵢ ← x
        end

METRICS: discrepancy, consensus
""")

println("Running trusted nodes protocol...")
results_trust = run_protocol(trusted; p_values=[0.6, 0.8, 1.0], rounds=5, repetitions=1000)
results_table(results_trust; protocol_name="Trusted Nodes")

# Example 3: Conditional Value Selection
# Use value from process 5 if available, otherwise from process 1
println("\n\n3. Conditional Value Selection")
println("-"^70)

conditional = Protocol("""
PROTOCOL ConditionalValue
PROCESSES: 10
STATE: x ∈ ℝ
INITIAL: xᵢ = i
CHANNEL: stochastic

UPDATE RULE:
    EACH ROUND:
        if received_from(5) then
            xᵢ ← value_from(5)
        else if received_from(1) then
            xᵢ ← value_from(1)
        else
            xᵢ ← x
        end
        end

METRICS: discrepancy, consensus
""")

println("Running conditional value selection protocol...")
results_cond = run_protocol(conditional; p_values=[0.7, 0.9], rounds=3, repetitions=1000)
results_table(results_cond; protocol_name="Conditional Value")

# Example 4: Leader-based Consensus with Filtering
# Processes 1-3 are leaders; average only their values
println("\n\n4. Leader-based Consensus")
println("-"^70)

leaders = Protocol("""
PROTOCOL LeaderConsensus
PROCESSES: 10
STATE: x ∈ ℝ
INITIAL: xᵢ = i * 0.1
CHANNEL: stochastic

UPDATE RULE:
    EACH ROUND:
        if received_from(1) and received_from(2) and received_from(3) then
            xᵢ ← avg(inbox_from(1, 2, 3))
        else
            xᵢ ← x
        end

METRICS: discrepancy, consensus
""")

println("Running leader-based consensus...")
results_leaders = run_protocol(leaders; p_values=[0.8, 0.9, 1.0], rounds=10, repetitions=1000)
results_table(results_leaders; protocol_name="Leader Consensus")

println("\n" * "="^70)
println("All examples completed!")
println("="^70)
