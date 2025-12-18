# StochProtocol.jl

*Beautiful simulation framework for distributed consensus under stochastic communication*

---

## What is StochProtocol?

StochProtocol.jl is a high-level Julia framework that lets you **define**, **simulate**, and **analyze** distributed consensus protocols using clean mathematical notation—no boilerplate, no manual message passing, just pure protocol logic.

```julia
using StochProtocol

# Define a protocol in 30 seconds
AMP = Protocol("""
PROTOCOL AMP
PROCESSES: 2
STATE: x ∈ {0,1}
INITIAL VALUES: [0.0, 1.0]
CHANNEL: stochastic

UPDATE RULE:
    EACH ROUND:
        if received_diff then xᵢ ← 0.5 else xᵢ ← x end

METRICS: discrepancy, consensus
""")

# Run 10,000 simulations across probability range
results = run_protocol(AMP; p_values=0.0:0.05:1.0, repetitions=2000)

# Beautiful visualizations
plot_discrepancy_vs_p(results)
results_table(results)
```

That's it. No event loops, no network simulation, no manual statistics—StochProtocol handles it all.

---

## Why StochProtocol?

### 🎯 **Declarative Protocol Design**
Write protocols in paper-like mathematical notation. No coding required for protocol logic.

```julia
UPDATE RULE:
    EACH ROUND:
        xᵢ ← avg(inbox_with_self)
```

### ⚡ **Automatic Monte Carlo**
Run thousands of randomized experiments automatically. Get statistical distributions, not single runs.

### 📊 **Publication-Ready Output**
Interactive tables in Jupyter, 300 DPI plots for papers, and CSV export for further analysis.

### 🔬 **Research-Grade Features**
- Multiple delivery models (standard, guaranteed, broadcast)
- Process-specific configurations
- Multi-round dynamics tracking
- Protocol comparison tools
- Extensible DSL

### 🚀 **Fast & Efficient**
Optimized Julia core with deterministic RNG for reproducibility.

---

## Quick Example: Averaging Protocol

```julia
using StochProtocol

# Define the protocol
averaging = Protocol("""
PROTOCOL SimpleAveraging
PROCESSES: 10
STATE: x ∈ ℝ
INITIAL: xᵢ = i
CHANNEL: stochastic

UPDATE RULE:
    EACH ROUND:
        xᵢ ← avg(inbox_with_self)

METRICS:
    discrepancy
    consensus
""")

# Run experiments
results = run_protocol(averaging;
    p_values = 0.5:0.1:1.0,
    rounds = 5,
    repetitions = 1000
)

# Visualize
plot_discrepancy_vs_p(results;
    title = "Convergence Rate vs Probability",
    save_path = "averaging_results.png"
)
```

**Output**: A beautiful plot showing how quickly consensus is reached as communication probability increases.

---

## Key Features

| Feature | Description |
|---------|-------------|
| **Protocol DSL** | Paper-like syntax with full Julia expressions |
| **Delivery Models** | Standard, guaranteed delivery, broadcast, hybrid |
| **Metrics** | Discrepancy, consensus probability, custom metrics |
| **Visualization** | Built-in plotting and table generation |
| **Monte Carlo** | Automatic statistical analysis over thousands of runs |
| **Comparison** | Side-by-side protocol performance analysis |

---

## Learn More

- **[Quick Start](quickstart.md)** - Get up and running in 5 minutes
- **[Protocol DSL](guides/dsl.md)** - Complete language reference
- **[Delivery Models](guides/delivery_models.md)** - Communication model options
- **[Examples](examples/overview.md)** - Real protocols from research papers
- **[API Reference](api/core.md)** - Function documentation

---

## Installation

```julia
using Pkg
Pkg.add("StochProtocol")
```

Or from GitHub:

```julia
using Pkg
Pkg.add(url="https://github.com/notGiGi/StochProtocol.jl")
```

---

## Community & Support

- **GitHub**: [notGiGi/StochProtocol.jl](https://github.com/notGiGi/StochProtocol.jl)
- **Issues**: [Report bugs or request features](https://github.com/notGiGi/StochProtocol.jl/issues)

---

## Citation

If you use StochProtocol.jl in your research, please cite:

```bibtex
@software{stochprotocol2025,
  title = {StochProtocol.jl: Simulation of Stochastic Consensus Protocols},
  author = {notGiGi},
  year = {2025},
  url = {https://github.com/notGiGi/StochProtocol.jl}
}
```

---

## License

MIT License - Free for academic and commercial use.
