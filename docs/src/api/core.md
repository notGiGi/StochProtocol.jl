# Core Functions

Core API for defining and running protocols.

## Protocol Definition

```@docs
Protocol
```

### Usage

```julia
using StochProtocol

# Define a protocol
AMP = Protocol("""
PROTOCOL AMP
PROCESSES: 2
...
""")
```

The `Protocol` wrapper provides beautiful display in notebooks and REPL.

## Running Experiments

```@docs
run_protocol
```

### Examples

**Basic usage:**
```julia
results = run_protocol(AMP; p_values=0.0:0.1:1.0)
```

**With all parameters:**
```julia
results = run_protocol(AMP;
                       p_values=[0.2, 0.5, 0.8],  # Custom probabilities
                       rounds=3,                    # Multiple rounds
                       repetitions=5000,            # High accuracy
                       seed=42,                     # Reproducible
                       consensus_eps=1e-6)          # Consensus threshold
```

**From file:**
```julia
results = run_protocol("protocols/amp.txt";
                       p_values=0.0:0.05:1.0)
```

## Results

### ExploreRun

Results are returned as an `ExploreRun` object:

```julia
results = run_protocol(...)

# Access properties
results.name           # Protocol name
results.num_processes  # Number of processes
results.rounds         # Number of rounds
results.repetitions    # Monte Carlo samples
results.p_values       # Probabilities tested
results.results        # Individual MonteCarloResult objects

# Iterate over results
for r in results
    println("p=$(r.p), E[D]=$(r.mean_discrepancy)")
end

# Index access
first_result = results[1]
```

### MonteCarloResult

Each p-value has a `MonteCarloResult`:

```julia
r = results[1]

r.p                      # Delivery probability
r.repetitions            # Number of trials
r.mean_discrepancy       # E[D]
r.var_discrepancy        # Var[D]
r.consensus_probability  # P(consensus)
r.mean_discrepancy_by_round  # Round-by-round E[D]
```

## Utility Functions

```@docs
summary
table
```

### Usage

```julia
# Text summary
summary(results)

# Tabular data
df = table(results)  # Returns DataFrame if available
```

## Parameters

### `p_values`

Message delivery probability. Accepts:
- **Range**: `0.0:0.1:1.0`
- **List**: `[0.2, 0.5, 0.8]`
- **Single value**: `0.5` (converted to `[0.5]`)

### `rounds`

Number of communication rounds. Default: `1`

```julia
# Single round
results = run_protocol(AMP; rounds=1)

# Analyze convergence over multiple rounds
results = run_protocol(AMP; rounds=10)
```

### `repetitions`

Monte Carlo samples per p-value. Default: `2000`

- **500-1000**: Fast prototyping
- **2000-5000**: Standard analysis
- **10000+**: High-precision results

### `seed`

Random seed for reproducibility. Default: `nothing` (random)

```julia
# Reproducible results
results1 = run_protocol(AMP; seed=42)
results2 = run_protocol(AMP; seed=42)
# results1 == results2  ✓

# Random (different each time)
results = run_protocol(AMP)
```

### `consensus_eps`

Threshold for consensus detection. Default: `1e-10`

Two processes are in consensus if `|x₁ - x₂| ≤ consensus_eps`.

```julia
# Stricter consensus
results = run_protocol(AMP; consensus_eps=1e-12)

# Looser consensus
results = run_protocol(AMP; consensus_eps=1e-6)
```

## See Also

- [Protocol DSL](dsl.md) - Protocol specification language
- [Visualization](visualization.md) - Plotting and tables
- [Examples](../examples/amp.md) - Complete examples
