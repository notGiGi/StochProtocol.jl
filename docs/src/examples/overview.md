# Examples

*Real-world protocols and use cases to get you started*

```@raw html
<div class="admonition is-success">
    <div class="admonition-header">💡 Learning Path</div>
    <p>Start with the <strong>Hello World</strong> example to understand the basics, then explore <strong>Classic Protocols</strong> for common patterns, and finally dive into <strong>Advanced Examples</strong> for research-grade implementations.</p>
</div>
```

---

## Getting Started Examples

### Hello World: AMP Protocol

The simplest meaningful protocol - averaging with meeting point.

```julia
using StochProtocol

AMP = Protocol("""
PROTOCOL AMP
PROCESSES: 2
STATE: x ∈ {0,1}
INITIAL VALUES: [0.0, 1.0]
PARAMETERS: y = 0.5
CHANNEL: stochastic

UPDATE RULE:
    EACH ROUND:
        if received_diff then xᵢ ← y else xᵢ ← x end

METRICS: discrepancy, consensus
""")

results = run_protocol(AMP; p_values=0.0:0.1:1.0, repetitions=2000)
results_table(results)
plot_discrepancy_vs_p(results)
```

**Takeaway**: When processes disagree, they move to meeting point `y=0.5`.

---

## Classic Protocols

### Simple Averaging

Processes average their values with received messages.

```julia
averaging = Protocol("""
PROTOCOL Averaging
PROCESSES: 10
STATE: x ∈ ℝ
INITIAL: xᵢ = i
CHANNEL: stochastic

UPDATE RULE:
    EACH ROUND:
        xᵢ ← avg(inbox_with_self)

METRICS: discrepancy, consensus
""")

results = run_protocol(averaging; rounds=10, p_values=0.5:0.1:1.0)
```

**Use Case**: Study convergence rates under different communication probabilities.

---

### Minimum Protocol

Processes converge to the minimum value.

```julia
minimum = Protocol("""
PROTOCOL Minimum
PROCESSES: 5
STATE: x ∈ ℝ
INITIAL VALUES: [5.0, 3.0, 8.0, 1.0, 6.0]
CHANNEL: stochastic

UPDATE RULE:
    EACH ROUND:
        if received_any then
            xᵢ ← min(inbox_with_self)
        else
            xᵢ ← x
        end

METRICS: discrepancy, consensus
""")
```

**Insight**: Minimum spreads through network, but requires at least one message delivery.

---

## Delivery Model Examples

### Guaranteed Delivery

Ensure minimum connectivity requirements.

```julia
guaranteed = Protocol("""
PROTOCOL GuaranteedAMP
PROCESSES: 3
STATE: x ∈ {0,1}
INITIAL VALUES: [0.0, 0.5, 1.0]
PARAMETERS: y = 0.5
CHANNEL: stochastic

MODEL:
    guaranteed k=2 scope=per_round

UPDATE RULE:
    EACH ROUND:
        if received_diff then xᵢ ← y else xᵢ ← x end

METRICS: discrepancy, consensus
""")

# At low p, many runs will be filtered out
results = run_protocol(guaranteed; p_values=0.5:0.1:1.0, repetitions=2000)
```

**Use Case**: Study protocols under QoS guarantees or minimum connectivity assumptions.

---

### Broadcast Communication

All-or-nothing delivery per source.

```julia
broadcast = Protocol("""
PROTOCOL BroadcastAveraging
PROCESSES: 4
STATE: x ∈ ℝ
INITIAL VALUES: [0.0, 1.0, 2.0, 3.0]
CHANNEL: stochastic

MODEL:
    broadcast probability=per_source

UPDATE RULE:
    EACH ROUND:
        xᵢ ← avg(inbox_with_self)

METRICS: discrepancy, consensus
""")
```

**Use Case**: Simulate atomic broadcast or correlated failures.

---

### Hybrid Models

Different processes with different delivery characteristics.

```julia
hybrid = Protocol("""
PROTOCOL HeterogeneousNetwork
PROCESSES: 6
STATE: x ∈ ℝ
INITIAL: xᵢ = i
CHANNEL: stochastic

MODEL:
    process 1: standard
    process 2: standard
    process 3: broadcast
    process 4: broadcast
    process 5: guaranteed k=3 scope=per_round
    process 6: guaranteed k=3 scope=per_round

UPDATE RULE:
    EACH ROUND:
        xᵢ ← avg(inbox_with_self)

METRICS: discrepancy, consensus
""")
```

**Use Case**: Simulate heterogeneous networks with different node capabilities.

---

## Advanced Examples

### Multi-Round Convergence Study

```julia
using StochProtocol

proto = Protocol("""
PROTOCOL ConvergenceStudy
PROCESSES: 20
STATE: x ∈ ℝ
INITIAL: xᵢ = i
CHANNEL: stochastic

UPDATE RULE:
    EACH ROUND:
        xᵢ ← avg(inbox_with_self)

METRICS: discrepancy, consensus
""")

# Study convergence over increasing rounds
for rounds in [1, 2, 5, 10, 20, 50]
    results = run_protocol(proto;
        rounds = rounds,
        p_values = [0.7, 0.9],
        repetitions = 1000
    )

    println("Rounds: $rounds")
    println("  p=0.7: E[D]=$(results[1].mean_discrepancy)")
    println("  p=0.9: E[D]=$(results[2].mean_discrepancy)")
end
```

---

### Protocol Comparison

```julia
using StochProtocol

# Define multiple protocols
protocols = Dict(
    "AMP" => Protocol("""
        PROTOCOL AMP
        PROCESSES: 3
        STATE: x ∈ {0,1}
        INITIAL VALUES: [0.0, 0.5, 1.0]
        PARAMETERS: y = 0.5
        CHANNEL: stochastic
        UPDATE RULE:
            EACH ROUND:
                if received_diff then xᵢ ← y else xᵢ ← x end
        METRICS: discrepancy, consensus
    """),

    "Averaging" => Protocol("""
        PROTOCOL Averaging
        PROCESSES: 3
        STATE: x ∈ ℝ
        INITIAL VALUES: [0.0, 0.5, 1.0]
        CHANNEL: stochastic
        UPDATE RULE:
            EACH ROUND:
                xᵢ ← avg(inbox_with_self)
        METRICS: discrepancy, consensus
    """),

    "Minimum" => Protocol("""
        PROTOCOL Minimum
        PROCESSES: 3
        STATE: x ∈ ℝ
        INITIAL VALUES: [0.0, 0.5, 1.0]
        CHANNEL: stochastic
        UPDATE RULE:
            EACH ROUND:
                xᵢ ← min(inbox_with_self)
        METRICS: discrepancy, consensus
    """)
)

# Run all protocols
all_results = []
p_range = 0.0:0.1:1.0

for (name, proto) in protocols
    println("Running $name...")
    results = run_protocol(proto; p_values=p_range, repetitions=2000, seed=42)
    push!(all_results, (name, results))
end

# Compare
results_comparison_table(all_results)
plot_comparison(all_results; save_path="comparison.png")
```

---

### Parameter Sweep

Explore how protocol parameters affect performance.

```julia
function create_amp(y_value)
    Protocol("""
    PROTOCOL AMP_y$(y_value)
    PROCESSES: 2
    STATE: x ∈ {0,1}
    INITIAL VALUES: [0.0, 1.0]
    PARAMETERS: y = $y_value
    CHANNEL: stochastic
    UPDATE RULE:
        EACH ROUND:
            if received_diff then xᵢ ← y else xᵢ ← x end
    METRICS: discrepancy, consensus
    """)
end

# Sweep over y parameter
y_values = 0.0:0.1:1.0
p_test = 0.8

for y in y_values
    proto = create_amp(y)
    results = run_protocol(proto; p_values=[p_test], repetitions=1000)
    E_D = results[1].mean_discrepancy

    println("y=$y, p=$p_test: E[D]=$E_D")
end
```

---

## Real-World Inspired Examples

### Sensor Network Averaging

```julia
sensor_net = Protocol("""
PROTOCOL SensorNetwork
PROCESSES: 25
STATE: x ∈ ℝ
INITIAL: xᵢ = 20.0 + randn()  # Temperature readings with noise
CHANNEL: stochastic

UPDATE RULE:
    EACH ROUND:
        xᵢ ← 0.8 * x + 0.2 * avg(inbox)  # Weighted average

METRICS:
    discrepancy
    consensus
""")
```

### Leader Election Simulation

```julia
leader = Protocol("""
PROTOCOL LeaderElection
PROCESSES: 10
STATE: x ∈ ℝ
INITIAL: xᵢ = i  # Each process has unique ID
CHANNEL: stochastic

UPDATE RULE:
    EACH ROUND:
        xᵢ ← max(inbox_with_self)  # Propagate maximum ID

    END:
        # Leader is process with max ID
        xᵢ ← max(inbox_with_self)

METRICS:
    discrepancy
    consensus
""")
```

---

## Running the Examples

All examples are available in the `examples/` directory:

```bash
# Run delivery models demo
julia examples/delivery_models_demo.jl

# Run quickstart examples
julia examples/quickstart.jl

# Run protocol comparison
julia examples/literature_protocols.jl
```

---

## Creating Your Own Examples

### Template

```julia
using StochProtocol

my_protocol = Protocol("""
PROTOCOL MyProtocol
PROCESSES: N
STATE: x ∈ Domain
INITIAL VALUES: [...]
CHANNEL: stochastic

MODEL:
    # Optional delivery model

UPDATE RULE:
    EACH ROUND:
        # Your update logic

METRICS:
    discrepancy
    consensus
""")

# Experiment
results = run_protocol(my_protocol;
    p_values = 0.0:0.1:1.0,
    rounds = 1,
    repetitions = 2000
)

# Analyze
results_table(results)
plot_discrepancy_vs_p(results)
```

---

## See Also

- [Quick Start](../quickstart.md) - Get started in 5 minutes
- [Protocol DSL](../guides/dsl.md) - Language reference
- [Delivery Models](../guides/delivery_models.md) - Communication models
- [Experiments Guide](../guides/experiments.md) - Running simulations
