# Delivery Models in StochProtocol

*Flexible communication models for realistic network simulation*

---

StochProtocol supports multiple communication delivery models that allow you to experiment with different network conditions and message delivery guarantees.

## Overview

```@raw html
<div class="admonition is-info">
    <div class="admonition-header">🎯 Why Delivery Models Matter</div>
    <p>Different delivery models capture different assumptions about network behavior: simple probabilistic channels, guaranteed delivery semantics, broadcast primitives, or complex hybrid scenarios. Choose the model that matches your research question.</p>
</div>
```

Delivery models control how messages are delivered between processes in your protocol:

- **Global models**: Apply the same model to all processes
- **Process-specific models**: Different processes can use different delivery models
- **Hybrid configurations**: Mix and match models for heterogeneous networks

## Available Models

### 1. Standard Model (Default)

Classic probabilistic delivery where each message is delivered independently with probability `p`.

**Syntax:**
```
MODEL:
    standard
```

**Characteristics:**
- Each message has independent probability `p` of delivery
- Default behavior if no MODEL section specified
- Best for simulating typical unreliable networks

**Example:**
```julia
protocol"""
PROTOCOL MyProtocol
...
MODEL:
    standard
...
"""
```

### 2. Guaranteed Model

Ensures a minimum number of messages are delivered, either per round or across the entire execution.

**Syntax:**
```
MODEL:
    guaranteed k=<number> scope=<per_round|total>
```

**Parameters:**
- `k`: Minimum number of messages that must be delivered
- `scope`:
  - `per_round`: Guarantee applies to each round individually
  - `total`: Guarantee applies to total messages across all rounds

**Characteristics:**
- Runs that don't meet the guarantee are filtered out (not counted in statistics)
- May reduce the number of valid repetitions for low `p` values
- Useful for modeling networks with minimum reliability requirements

**Example:**
```julia
protocol"""
PROTOCOL ReliableProtocol
PROCESSES: 4
...
MODEL:
    guaranteed k=3 scope=per_round
...
"""
```

This ensures at least 3 messages are delivered in every round. Runs with fewer messages are discarded.

### 3. Broadcast Model

All-or-nothing delivery per source process. If any message from a process is delivered, all its messages are delivered.

**Syntax:**
```
MODEL:
    broadcast probability=<per_source|uniform>
```

**Parameters:**
- `probability`:
  - `per_source`: Each source independently decides to broadcast with probability `p`
  - `uniform`: Global probability `p` for all sources

**Characteristics:**
- Correlated delivery: all messages from a source succeed/fail together
- Models broadcast primitives or atomic multicast
- Useful for protocols that rely on complete information from sources

**Example:**
```julia
protocol"""
PROTOCOL BroadcastProtocol
PROCESSES: 3
...
MODEL:
    broadcast probability=per_source
...
"""
```

## Process-Specific Models

You can assign different models to different processes for heterogeneous networks.

**Syntax:**
```
MODEL:
    process <id>: <model_spec>
    process <id>: <model_spec>
    ...
```

**Example:**
```julia
protocol"""
PROTOCOL HybridProtocol
PROCESSES: 4
...
MODEL:
    process 1: standard
    process 2: broadcast
    process 3: broadcast
    process 4: guaranteed k=2 scope=per_round
...
"""
```

In this configuration:
- Process 1 uses independent delivery
- Processes 2 & 3 use broadcast (all-or-nothing)
- Process 4 guarantees at least 2 messages per round

## Complete Examples

### Example 1: Comparing Models on AMP Protocol

```julia
using StochProtocol

# Standard model
amp_standard = Protocol("""
PROTOCOL AMP_Standard
PROCESSES: 3
STATE: x ∈ {0,1}
INITIAL VALUES: [0.0, 0.5, 1.0]
PARAMETERS: y ∈ [0,1] = 0.5
CHANNEL: stochastic
MODEL: standard
UPDATE RULE:
    EACH ROUND:
        if received_diff then xᵢ ← y else xᵢ ← x end
METRICS: discrepancy, consensus
""")

# Guaranteed model
amp_guaranteed = Protocol("""
PROTOCOL AMP_Guaranteed
PROCESSES: 3
STATE: x ∈ {0,1}
INITIAL VALUES: [0.0, 0.5, 1.0]
PARAMETERS: y ∈ [0,1] = 0.5
CHANNEL: stochastic
MODEL: guaranteed k=2 scope=per_round
UPDATE RULE:
    EACH ROUND:
        if received_diff then xᵢ ← y else xᵢ ← x end
METRICS: discrepancy, consensus
""")

# Run and compare
results_std = run_protocol(amp_standard; p_values=0.0:0.1:1.0, repetitions=2000)
results_gua = run_protocol(amp_guaranteed; p_values=0.0:0.1:1.0, repetitions=2000)

plot_comparison([("Standard", results_std), ("Guaranteed k=2", results_gua)])
```

### Example 2: Hybrid Network Simulation

```julia
# Simulate a network where some nodes have better connectivity
heterogeneous = Protocol("""
PROTOCOL HeterogeneousAveraging
PROCESSES: 6
STATE: x ∈ ℝ
INITIAL VALUES: [0.0, 1.0, 2.0, 3.0, 4.0, 5.0]
CHANNEL: stochastic

MODEL:
    process 1: standard
    process 2: standard
    process 3: broadcast
    process 4: broadcast
    process 5: guaranteed k=4 scope=per_round
    process 6: guaranteed k=4 scope=per_round

UPDATE RULE:
    EACH ROUND:
        xᵢ ← avg(inbox_with_self)

METRICS:
    discrepancy
    consensus
""")

results = run_protocol(heterogeneous; p_values=[0.5, 0.7, 0.9], repetitions=1000)
results_table(results)
```

## Implementation Details

### How Guaranteed Models Work

When using a guaranteed model with `scope=per_round`:
1. Protocol runs normally
2. After each round, delivered messages are counted
3. If count < k, the entire run is discarded
4. Only runs that satisfy the guarantee contribute to statistics

This means:
- At low `p` values, you may get far fewer than requested repetitions
- StochProtocol will attempt up to 100× the requested repetitions
- A warning is issued if insufficient valid runs are found

### Performance Considerations

- **Standard**: Fastest, no filtering needed
- **Broadcast**: Slightly faster than standard (fewer random numbers generated)
- **Guaranteed**: Slowest for low `p` (many runs discarded)

For guaranteed models with strict constraints and low `p`, consider:
- Increasing repetitions budget
- Using less strict guarantees
- Focusing analysis on higher `p` values

## Use Cases

| Model | Best For |
|-------|----------|
| **Standard** | General-purpose, typical unreliable networks |
| **Guaranteed** | Modeling QoS guarantees, studying minimum connectivity requirements |
| **Broadcast** | Atomic broadcast primitives, correlated failures, gossip protocols |
| **Hybrid** | Heterogeneous networks, partial broadcast, tiered architectures |

## Advanced: Model Configuration in Code

You can also inspect and modify delivery models programmatically (for advanced use cases):

```julia
# Models are parsed from the protocol definition
# and stored in the ProtocolIR structure
using StochProtocol.DSL.IR: DeliveryModelSpec

# Example: programmatically create a model spec
spec = DeliveryModelSpec(
    :guaranteed,  # model type
    Dict(:min_messages => 3, :scope => :per_round),  # parameters
    nothing  # process_id (nothing = global)
)
```

## See Also

- [Protocol DSL Reference](guides/dsl.md)
- [Experiments Guide](guides/experiments.md)
- [Examples](../examples/delivery_models_demo.jl)
