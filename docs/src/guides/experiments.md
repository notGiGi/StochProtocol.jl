# Running Experiments

Guide to running simulations and analyzing results with StochProtocol.

---

## Quick Start

The main function for running experiments is `run_protocol`:

```julia
using StochProtocol

results = run_protocol(my_protocol;
    p_values = 0.0:0.1:1.0,
    rounds = 1,
    repetitions = 2000,
    seed = 42
)
```

---

## `run_protocol` Function

### Signature

```julia
run_protocol(protocol;
    p_values = 0:0.05:1,
    rounds::Int = 1,
    repetitions::Int = 2000,
    seed::Union{Int,Nothing} = nothing,
    consensus_eps::Float64 = 1e-6,
    debug::Bool = false,
    trace::Bool = false,
    trace_limit::Int = 1
)
```

### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `protocol` | `Protocol` or `String` | - | Protocol definition or file path |
| `p_values` | `Range` or `Vector` | `0:0.05:1` | Delivery probabilities to test |
| `rounds` | `Int` | `1` | Number of communication rounds |
| `repetitions` | `Int` | `2000` | Monte Carlo repetitions per p value |
| `seed` | `Int` or `nothing` | `nothing` | Random seed (auto if `nothing`) |
| `consensus_eps` | `Float64` | `1e-6` | Consensus threshold (discrepancy ≤ ε) |
| `debug` | `Bool` | `false` | Print debug information |
| `trace` | `Bool` | `false` | Show detailed execution trace |
| `trace_limit` | `Int` | `1` | Max repetitions to trace |

### Return Value

Returns an `ExploreRun` object containing results for all p values.

---

## Configuring Experiments

### Probability Ranges

Test across different delivery probabilities:

```julia
# Coarse sweep
results = run_protocol(proto; p_values=0.0:0.2:1.0)

# Fine sweep
results = run_protocol(proto; p_values=0.0:0.01:1.0)

# Specific values
results = run_protocol(proto; p_values=[0.5, 0.7, 0.9, 1.0])

# High probability region
results = run_protocol(proto; p_values=0.8:0.02:1.0)
```

### Number of Rounds

Control how many communication rounds to simulate:

```julia
# Single round
results = run_protocol(proto; rounds=1)

# Multiple rounds to study convergence
results = run_protocol(proto; rounds=10)

# Many rounds for slow protocols
results = run_protocol(proto; rounds=100)
```

### Repetitions

More repetitions = better statistics but longer runtime:

```julia
# Quick test
results = run_protocol(proto; repetitions=100)

# Standard analysis
results = run_protocol(proto; repetitions=2000)

# High-precision analysis
results = run_protocol(proto; repetitions=10000)
```

**Guideline:**
- **100-500**: Quick testing
- **1000-2000**: Standard analysis
- **5000+**: Publication-quality results

### Random Seeds

Control reproducibility:

```julia
# Reproducible (same results every time)
results = run_protocol(proto; seed=42)

# Different seed
results = run_protocol(proto; seed=123)

# Random (different each run)
results = run_protocol(proto; seed=nothing)  # default
```

### Consensus Threshold

Adjust what counts as consensus:

```julia
# Strict consensus (default)
results = run_protocol(proto; consensus_eps=1e-6)

# Looser consensus
results = run_protocol(proto; consensus_eps=1e-3)

# Very loose (for noisy protocols)
results = run_protocol(proto; consensus_eps=0.01)
```

---

## Working with Results

### Viewing Results

```julia
# Beautiful table in Jupyter
results_table(results)

# With custom protocol name
results_table(results; protocol_name="My Protocol")

# Summary statistics
summary(results)

# Raw data access
for result in results
    println("p=$(result.p): E[D]=$(result.mean_discrepancy)")
end
```

### Extracting Data

```julia
# Get all p values tested
p_vals = [r.p for r in results]

# Get expected discrepancies
E_D = [r.mean_discrepancy for r in results]

# Get consensus probabilities
P_consensus = [r.consensus_probability for r in results]

# Get number of repetitions (useful for guaranteed models)
reps = [r.repetitions for r in results]
```

---

## Visualization

### Discrepancy vs Probability

```julia
using StochProtocol

plot_discrepancy_vs_p(results;
    title = "Protocol Performance",
    xlabel = "Delivery Probability p",
    ylabel = "Expected Discrepancy E[D]",
    save_path = "results.png"  # Optional: save to file
)
```

**Options:**
- `title`: Plot title
- `xlabel`, `ylabel`: Axis labels
- `save_path`: Save to file (PNG, PDF, SVG)
- `size`: Plot dimensions (default: `(800, 600)`)
- `dpi`: Resolution (default: 300)

### Consensus vs Probability

```julia
plot_consensus_vs_p(results;
    title = "Consensus Probability",
    save_path = "consensus.png"
)
```

### Comparing Multiple Protocols

```julia
results_amp = run_protocol(amp; p_values=0.0:0.1:1.0)
results_fv = run_protocol(fv; p_values=0.0:0.1:1.0)

plot_comparison([
    ("AMP", results_amp),
    ("FV", results_fv)
];
    title = "Protocol Comparison",
    save_path = "comparison.png"
)
```

---

## Advanced Usage

### Debugging

Enable debug mode to see what's happening:

```julia
results = run_protocol(proto;
    p_values = [0.5],
    repetitions = 10,
    debug = true
)
```

### Execution Traces

See detailed round-by-round execution:

```julia
results = run_protocol(proto;
    p_values = [0.7],
    repetitions = 5,
    trace = true,
    trace_limit = 2  # Only trace first 2 repetitions
)
```

Output shows:
- State before each round
- Messages received
- State after update
- Discrepancy and consensus status

### Parameter Sweeps

Explore protocol behavior across parameter spaces:

```julia
using StochProtocol

function make_amp(y_val)
    return Protocol("""
    PROTOCOL AMP_y$y_val
    PROCESSES: 2
    STATE: x ∈ {0,1}
    INITIAL VALUES: [0.0, 1.0]
    PARAMETERS: y = $y_val
    CHANNEL: stochastic
    UPDATE RULE:
        EACH ROUND:
            if received_diff then xᵢ ← y else xᵢ ← x end
    METRICS: discrepancy, consensus
    """)
end

for y in 0.0:0.1:1.0
    proto = make_amp(y)
    results = run_protocol(proto; p_values=0.5:0.1:1.0, repetitions=1000)
    println("y=$y, E[D] at p=0.8: $(results[7].mean_discrepancy)")
end
```

### Batch Analysis

Run multiple experiments efficiently:

```julia
protocols = [
    ("AMP", amp_protocol),
    ("FV", fv_protocol),
    ("MIN", min_protocol)
]

all_results = []

for (name, proto) in protocols
    println("Running $name...")
    results = run_protocol(proto;
        p_values = 0.0:0.05:1.0,
        repetitions = 2000,
        seed = 42
    )
    push!(all_results, (name, results))

    # Save individual results
    plot_discrepancy_vs_p(results;
        title = "$name Protocol",
        save_path = "$(name)_results.png"
    )
end

# Compare all
results_comparison_table(all_results)
```

---

## Performance Tips

### Optimize Repetitions

```julia
# Start with fewer repetitions during development
dev_results = run_protocol(proto; p_values=0.0:0.2:1.0, repetitions=100)

# Scale up for final analysis
final_results = run_protocol(proto; p_values=0.0:0.05:1.0, repetitions=5000)
```

### Reduce p-value Granularity

```julia
# Coarse first
quick = run_protocol(proto; p_values=0.0:0.1:1.0, repetitions=500)

# Then zoom into interesting regions
detailed = run_protocol(proto; p_values=0.7:0.01:0.9, repetitions=2000)
```

### Guaranteed Models

For guaranteed delivery models, you may need more attempts:

```julia
# Standard model: 2000 repetitions = 2000 valid runs
# Guaranteed model at low p: may need 100x attempts to get 2000 valid runs

results = run_protocol(guaranteed_proto;
    p_values = 0.3:0.1:1.0,  # Start from higher p
    repetitions = 1000        # May get fewer than 1000 at low p
)
```

---

## Common Patterns

### Quick Test

```julia
# Fast test during development
test = run_protocol(my_proto;
    p_values = [0.5, 0.9],
    repetitions = 100,
    seed = 42
)
```

### Publication Analysis

```julia
# High-quality results for papers
final = run_protocol(my_proto;
    p_values = 0.0:0.02:1.0,
    repetitions = 5000,
    seed = 42
)

plot_discrepancy_vs_p(final;
    title = "Protocol Performance",
    save_path = "figure1.pdf",
    dpi = 300
)
```

### Convergence Study

```julia
# Study how many rounds needed
for rounds in [1, 5, 10, 20, 50]
    results = run_protocol(proto;
        rounds = rounds,
        p_values = 0.7:0.1:1.0,
        repetitions = 1000
    )
    println("Rounds=$rounds, E[D] at p=0.9: $(results[3].mean_discrepancy)")
end
```

---

## See Also

- [Protocol DSL](dsl.md) - Define protocols
- [Delivery Models](delivery_models.md) - Communication models
- [Visualization Guide](visualization.md) - Plotting and tables
- [API Reference](../api/core.md) - Function details
