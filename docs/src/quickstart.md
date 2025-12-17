# Quick Start

Get up and running with StochProtocol.jl in 5 minutes.

## Installation

```julia-repl
julia> using Pkg

julia> Pkg.add("StochProtocol")
```

## Your First Protocol

Let's analyze the **AMP (Averaging Meeting Point)** protocol.

###  Step 1: Load the Package

```julia
using StochProtocol
```

### Step 2: Define the Protocol

Use the `Protocol()` wrapper for beautiful display:

```julia
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

When you display `AMP`, you'll see:

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

### Step 3: Run Experiments

```julia
results = run_protocol(AMP;
                       p_values=0.0:0.1:1.0,  # Message delivery probabilities
                       rounds=1,               # Communication rounds
                       repetitions=2000)       # Monte Carlo samples
```

!!! tip "Parameter Shortcuts"
    - `p_values` accepts ranges: `0.0:0.1:1.0` or lists: `[0.2, 0.5, 0.8]`
    - `seed` is optional - omit for random, specify for reproducibility
    - Default `repetitions=2000` balances speed and accuracy

### Step 4: View Results

**Interactive Table** (beautiful in Jupyter!):

```julia
results_table(results; protocol_name="AMP (y=0.5)")
```

Output:
```
Results: AMP (y=0.5)

11×4 DataFrame (colored & interactive in Jupyter)
 Row │ p        E_D       P_consensus  Trials
     │ Float64  Float64   Float64      Int64
─────┼────────────────────────────────────────
   1 │     0.0  1.0             0.0      2000
   2 │     0.1  0.9        0.00015      2000
  ...
```

**Publication Plot**:

```julia
plot_discrepancy_vs_p(results;
                      title="AMP: Expected Discrepancy vs p",
                      save_path="amp_discrepancy.png")
```

The plot is automatically:
- ✅ Professional styling
- ✅ Saved as PNG
- ✅ Displayed inline (in Jupyter)

## What's Next?

### Compare Protocols

```julia
# Define FV protocol
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

# Side-by-side comparison
results_comparison_table(Dict(
    "AMP" => results,
    "FV" => results_fv
))

# Comparative plot
plot_comparison(
    Dict("AMP" => results, "FV" => results_fv);
    metric=:discrepancy,
    save_path="comparison.png"
)
```


### Jupyter Notebook Setup

```julia
using Pkg
Pkg.activate(".")  # Activate project environment
using StochProtocol

# Define, run, visualize - no semicolons needed!
AMP = Protocol("""...""")
results = run_protocol(AMP; p_values=0.0:0.1:1.0)
results_table(results)
```

### Reproducible Research

```julia
# Fixed seed for reproducibility
results = run_protocol(AMP;
                       p_values=0.0:0.05:1.0,
                       repetitions=5000,
                       seed=42)  # Same results every time
```

### Parameter Sweeps

```julia
# Analyze how parameter y affects performance
for y in [0.3, 0.4, 0.5, 0.6, 0.7]
    protocol = make_amp_protocol(y)  # Helper function
    results = run_protocol(protocol; p_values=0.0:0.1:1.0)
    plot_discrepancy_vs_p(results;
                          title="AMP (y=$y)",
                          save_path="amp_y$(y).png")
end
```

## Tips & Tricks

!!! tip "Protocol() Display"
    Use `Protocol("""...""")` instead of plain strings - it displays beautifully without needing `;`

!!! tip "Jupyter Tables"
    In Jupyter, `results_table()` returns an interactive DataFrame with:
    - ✅ Colored headers
    - ✅ Sortable columns
    - ✅ Hover tooltips
    - ✅ Easy copy/paste

!!! tip "Fast Iteration"
    Use fewer `repetitions` (e.g., 500) while developing, then increase to 5000+ for final results.

!!! warning "Memory Usage"
    Very large parameter sweeps (many p-values × high repetitions × many rounds) can use significant memory. Start small and scale up.