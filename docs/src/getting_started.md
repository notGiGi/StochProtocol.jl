# Getting Started

This guide will walk you through using StochProtocol.jl to define, simulate, and analyze distributed consensus protocols.

## Installation

```julia
using Pkg
Pkg.add("StochProtocol")
```

## Your First Protocol

Let's implement the **AMP (Averaging Meeting Point)** protocol:

```julia
using StochProtocol

# Define the protocol using the Protocol wrapper
AMP = Protocol("""
PROTOCOL AMP
PROCESSES: 2
STATE:
    x ∈ {0,1}
INITIAL VALUES:
    [0.0, 1.0]
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
""")
```

When you display `AMP` in a notebook, you'll see:

```
╭─────────────────────────────────────────────────────────────╮
│  Protocol: AMP                                             │
╰─────────────────────────────────────────────────────────────╯

  PROTOCOL AMP
  PROCESSES: 2
  STATE:
      x ∈ {0,1}
  ...

  ✓ Protocol loaded and ready to run
```

## Running Experiments

Run the protocol across different message delivery probabilities:

```julia
results = run_protocol(AMP;
                       p_values=0.0:0.1:1.0,  # Range of probabilities
                       rounds=1,               # Number of rounds
                       repetitions=2000)       # Monte Carlo samples
```

### Parameters

- **`p_values`**: Probability range or list (e.g., `0.0:0.1:1.0` or `[0.2, 0.5, 0.8]`)
- **`rounds`**: Number of communication rounds
- **`repetitions`**: Number of Monte Carlo simulations per p-value
- **`seed`**: (Optional) Random seed for reproducibility

## Viewing Results

### Interactive Tables

```julia
results_table(results; protocol_name="AMP (y=0.5)")
```

Output in Jupyter:
```
Results: AMP (y=0.5)

11×4 DataFrame (interactive, colored)
 Row │ p        E_D      P_consensus  Trials
     │ Float64  Float64  Float64      Int64
─────┼───────────────────────────────────────
   1 │     0.0   1.0           0.0      2000
   2 │     0.1   0.9       0.00015      2000
   3 │     0.2   0.8        0.0032      2000
  ...
```

### Plots

```julia
# Discrepancy plot
plot_discrepancy_vs_p(results;
                      title="AMP: Expected Discrepancy vs p",
                      save_path="amp_discrepancy.png")

# Consensus probability plot
plot_consensus_vs_p(results;
                    title="AMP: Consensus Probability vs p",
                    save_path="amp_consensus.png")
```

All plots are 300 DPI and ready for publication!

## Comparing Protocols

```julia
# Define another protocol
FV = Protocol("""
PROTOCOL FV
PROCESSES: 2
STATE:
    x ∈ {0,1}
INITIAL VALUES:
    [0.0, 1.0]
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
""")

results_fv = run_protocol(FV; p_values=0.0:0.1:1.0, repetitions=2000)

# Comparison table
results_comparison_table(Dict(
    "AMP" => results,
    "FV" => results_fv
))

# Comparison plot
plot_comparison(
    Dict("AMP" => results, "FV" => results_fv);
    metric=:discrepancy,
    save_path="amp_vs_fv.png"
)
```

## Jupyter Notebooks

For the best experience, use StochProtocol in Jupyter notebooks:

1. **Interactive tables** - DataFrames with colors and sorting
2. **Inline plots** - See results immediately

Example notebook setup:

```julia
using Pkg
Pkg.activate(".")
using StochProtocol

# Define, run, visualize
AMP = Protocol("""...""")
results = run_protocol(AMP; p_values=0.0:0.1:1.0)
results_table(results)
```