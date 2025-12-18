using StochProtocol

println("="^70)
println("DELIVERY MODELS DEMONSTRATION")
println("="^70)

# Example 1: Guaranteed Model
println("\n1. GUARANTEED MODEL (per-round)")
println("-"^50)

amp_guaranteed = Protocol("""
PROTOCOL AMP_Guaranteed
PROCESSES: 3
STATE:
    x ∈ {0,1}
INITIAL VALUES:
    [0.0, 0.5, 1.0]
PARAMETERS:
    y ∈ [0,1] = 0.5
CHANNEL:
    stochastic

MODEL:
    guaranteed k=2 scope=per_round

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
""")

println("\nGuaranteed Model: At least 2 messages must be delivered per round")
results_guaranteed = run_protocol(amp_guaranteed; p_values=[0.5, 0.7, 0.9], repetitions=100, seed=42)
results_table(results_guaranteed; protocol_name="AMP Guaranteed")

# Example 2: Broadcast Model
println("\n2. BROADCAST MODEL")
println("-"^50)

amp_broadcast = Protocol("""
PROTOCOL AMP_Broadcast
PROCESSES: 3
STATE:
    x ∈ {0,1}
INITIAL VALUES:
    [0.0, 0.5, 1.0]
PARAMETERS:
    y ∈ [0,1] = 0.5
CHANNEL:
    stochastic

MODEL:
    broadcast probability=per_source

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
""")

println("\nBroadcast Model: All-or-nothing delivery per source")
results_broadcast = run_protocol(amp_broadcast; p_values=[0.5, 0.7, 0.9], repetitions=100, seed=42)
results_table(results_broadcast; protocol_name="AMP Broadcast")

# Example 3: Hybrid Models
println("\n3. HYBRID MODELS")
println("-"^50)

hybrid = Protocol("""
PROTOCOL Hybrid_Averaging
PROCESSES: 4
STATE:
    x ∈ ℝ
INITIAL VALUES:
    [0.0, 1.0, 2.0, 3.0]
CHANNEL:
    stochastic

MODEL:
    process 1: standard
    process 2: broadcast
    process 3: broadcast
    process 4: standard

UPDATE RULE:
    EACH ROUND:
        xᵢ ← avg(inbox_with_self)

METRICS:
    discrepancy
    consensus
""")

println("\nHybrid Model: Processes 2 and 3 use broadcast, 1 and 4 use standard")
results_hybrid = run_protocol(hybrid; p_values=[0.5, 0.7, 0.9], repetitions=100, seed=42)
results_table(results_hybrid; protocol_name="Hybrid Averaging")

println("\n" * "="^70)
println("KEY INSIGHTS:")
println("="^70)
println("• Standard: Classic independent message delivery")
println("• Guaranteed: Filters out runs with <k messages (may reduce valid samples)")
println("• Broadcast: Correlated delivery - all messages from a source succeed/fail together")
println("• Hybrid: Mix models to simulate heterogeneous network conditions")
println("="^70)
