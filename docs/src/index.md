# StochProtocol.jl

*Beautiful simulation framework for distributed consensus under stochastic communication*

---

## What is StochProtocol?

StochProtocol.jl is a **high-level Julia framework** that lets you **define**, **simulate**, and **analyze** distributed consensus protocols using clean mathematical notation.

**No boilerplate.** No manual message passing. **Just pure protocol logic.**

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

```@raw html
<div class="feature-grid">
    <div class="feature-card">
        <h3>Declarative Protocol Design</h3>
        <p>Write protocols in paper-like mathematical notation. No coding required for protocol logic.</p>
    </div>

    <div class="feature-card">
        <h3>Automatic Monte Carlo</h3>
        <p>Run thousands of randomized experiments automatically. Get statistical distributions with a single function call.</p>
    </div>

    <div class="feature-card">
        <h3>Publication-Ready Output</h3>
        <p>Beautiful interactive tables and plots ready for your papers and presentations.</p>
    </div>

    <div class="feature-card">
        <h3>Research-Grade Features</h3>
        <ul>
            <li>Multiple delivery models</li>
            <li>Process-specific configurations</li>
            <li>Multi-round dynamics tracking</li>
            <li>Protocol comparison tools</li>
        </ul>
    </div>

    <div class="feature-card">
        <h3>Fast & Efficient</h3>
        <p>Optimized Julia core with deterministic RNG for reproducibility. Simulate thousands of runs in seconds.</p>
    </div>

    <div class="feature-card">
        <h3>Flexible Delivery Models</h3>
        <p>Standard probabilistic, guaranteed delivery, broadcast semantics, or mix-and-match per process.</p>
    </div>
</div>
```

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
