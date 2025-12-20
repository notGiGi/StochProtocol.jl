# Tracing & Debugging

Detailed execution tracing and debugging tools for protocol development.

## Overview

The `Tracing` module provides deep visibility into protocol execution, making it easy to understand exactly what happens at each step, debug unexpected behaviors, and create visualizations.

## Trace Levels

Control verbosity of tracing:

```julia
using StochProtocol

# Available levels:
NoTrace()         # No tracing (default)
BasicTrace()      # Only major events
DetailedTrace()   # Message-level details
VerboseTrace()    # Everything including internals

# Enable tracing
enable_tracing(DetailedTrace())

# Disable tracing
disable_tracing()

# Change level
set_trace_level(VerboseTrace())
```

## Trace Execution

Run protocol with full execution trace:

```julia
trace = trace_execution(protocol;
    n_processes = 5,
    p = 0.7,
    rounds = 10,
    seed = UInt32(42)  # For reproducibility
)
```

This returns an `ExecutionTrace` object containing complete execution history.

## Trace Data Structure

```julia
struct ExecutionTrace
    protocol_name::String
    n_processes::Int
    p_value::Float64
    seed::UInt32
    rounds::Vector{RoundTrace}  # Per-round data
    initial_states::Vector{Float64}
    final_states::Vector{Float64}
    total_messages::Int
    delivered_messages::Int
    metadata::Dict{String, Any}
end
```

Each round contains:

```julia
struct RoundTrace
    round::Int
    messages::Vector{MessageTrace}      # All messages sent/received
    state_changes::Vector{StateChange}  # State updates
    discrepancy::Float64
    consensus_reached::Bool
    metadata::Dict{String, Any}
end
```

## Message Flow Diagram

Visualize message passing for a specific round:

```julia
# Show message flow for round 5
message_flow_diagram(trace; round=5)
```

Example output:

```
============================================================
Message Flow - Round 5
============================================================

Process 1 (value: 1.450)
  ✓ P1 ──→ P2  [1.450]
  ✓ P1 ──→ P3  [1.450]
  ✗ P1 ─⤫→ P4  [1.450]  # Not delivered

Process 2 (value: 2.300)
  ✓ P2 ──→ P1  [2.300]
  ✓ P2 ──→ P3  [2.300]

...

============================================================
Discrepancy: 0.123456
Messages: 20 sent, 14 delivered (70.0%)
============================================================
```

Symbols:
- `✓` = Message delivered
- `✗` = Message lost
- `──→` = Successful delivery
- `─⤫→` = Failed delivery

## State Evolution Table

See how each process's state changes over time:

```julia
state_evolution_table(trace)
```

Example output:

```
================================================================================
State Evolution
================================================================================
Round | P1     | P2     | P3     | P4     | P5     | Discrepancy
--------------------------------------------------------------------------------
  0   | 1.000  | 2.000  | 3.000  | 4.000  | 5.000  | 4.000000
  1   | 1.500  | 2.000  | 2.750  | 3.500  | 4.250  | 2.750000
  2   | 1.750  | 2.125  | 2.500  | 3.125  | 3.625  | 1.875000
  3   | 2.000  | 2.250  | 2.500  | 2.875  | 3.250  | 1.250000
  4   | 2.125  | 2.375  | 2.500  | 2.750  | 3.000  | 0.875000
  5   | 2.250  | 2.438  | 2.562  | 2.688  | 2.875  | 0.625000
  6   | 2.344  | 2.469  | 2.562  | 2.656  | 2.781  | 0.437000
  7   | 2.406  | 2.484  | 2.547  | 2.625  | 2.719  | 0.313000
  8   | 2.445  | 2.492  | 2.531  | 2.594  | 2.672  | 0.227000
  9   | 2.471  | 2.496  | 2.520  | 2.570  | 2.633  | 0.162000
 10   | 2.489  | 2.498  | 2.512  | 2.551  | 2.602  | 0.113000 ✓ CONSENSUS
================================================================================
```

## Trace Summary

High-level overview:

```julia
trace_summary(trace)
```

Output:

```
============================================================
Execution Trace Summary
============================================================
Protocol: AveragingProtocol
Processes: 5
Delivery probability: 0.70
Seed: 42
Rounds executed: 10
Total messages: 200 sent, 140 delivered (70.0%)

Initial discrepancy: 4.0
Final discrepancy: 0.113
Consensus reached: Round 10
============================================================
```

## Anomaly Detection

Automatically detect potential issues:

```julia
anomalies = detect_anomalies(trace)

for anomaly in anomalies
    println("⚠️  ", anomaly)
end
```

Detects:
- Processes that never receive messages
- Non-decreasing discrepancy (convergence failure)
- Very low delivery rates
- Processes that never update state
- Other unexpected behaviors

Example output:

```
⚠️  Process 3 never received any messages
⚠️  Discrepancy increased at round 7
⚠️  Low delivery rate: 35.0%
```

## Filter Trace

Focus on specific process or round:

```julia
# Filter by process
trace_p3 = filter_trace(trace; process=3)

# Filter by round
trace_r5 = filter_trace(trace; round=5)

# Both
trace_p3_r5 = filter_trace(trace; process=3, round=5)
```

## Export Trace

Save trace for external analysis:

```julia
# Export to JSON
export_trace(trace, "execution.json"; format=:json)

# Export to CSV
export_trace(trace, "execution.csv"; format=:csv)
```

## Example: Debugging Convergence Failure

```julia
using StochProtocol

protocol = Protocol("""
PROTOCOL DebugProtocol
PROCESSES: 5
STATE: x ∈ ℝ
INITIAL: xᵢ = i
CHANNEL: stochastic

UPDATE RULE:
    EACH ROUND:
        xᵢ ← avg(inbox_with_self)

METRICS:
    discrepancy
""")

# Enable detailed tracing
enable_tracing(DetailedTrace())

# Run with low p (might not converge)
trace = trace_execution(protocol;
    n_processes = 5,
    p = 0.2,  # Very low delivery probability
    rounds = 20,
    seed = UInt32(123)
)

# Analyze
println("\n📊 TRACE SUMMARY")
trace_summary(trace)

println("\n🔍 DETECTED ANOMALIES")
anomalies = detect_anomalies(trace)
if isempty(anomalies)
    println("✅ No anomalies detected")
else
    for anomaly in anomalies
        println("⚠️  ", anomaly)
    end
end

println("\n📈 STATE EVOLUTION")
state_evolution_table(trace)

# Check specific rounds with issues
println("\n📨 MESSAGE FLOW - ROUND 5")
message_flow_diagram(trace; round=5)

println("\n📨 MESSAGE FLOW - ROUND 15")
message_flow_diagram(trace; round=15)
```

## Example: Comparing Different Seeds

```julia
# Trace two runs with different seeds
trace1 = trace_execution(protocol; p=0.7, rounds=15, seed=UInt32(1))
trace2 = trace_execution(protocol; p=0.7, rounds=15, seed=UInt32(2))

println("Run 1:")
println("  Final discrepancy: ", trace1.rounds[end].discrepancy)
println("  Consensus at round: ", findfirst(r -> r.consensus_reached, trace1.rounds))

println("\nRun 2:")
println("  Final discrepancy: ", trace2.rounds[end].discrepancy)
println("  Consensus at round: ", findfirst(r -> r.consensus_reached, trace2.rounds))
```

## Best Practices

1. **Use for Development**: Enable tracing during protocol development
2. **Disable for Performance**: Turn off tracing for large-scale experiments
3. **Start with Summary**: Use `trace_summary()` first, then drill down
4. **Check Anomalies**: Always run `detect_anomalies()` on failed runs
5. **Reproducible Seeds**: Use fixed seeds when debugging
6. **Filter Large Traces**: Use `filter_trace()` for protocols with many processes/rounds

## Performance Notes

Tracing adds overhead:
- **NoTrace**: Zero overhead
- **BasicTrace**: ~5-10% overhead
- **DetailedTrace**: ~20-30% overhead
- **VerboseTrace**: ~50%+ overhead

For production experiments with thousands of repetitions, keep tracing disabled.

For debugging and understanding, detailed tracing is invaluable.
