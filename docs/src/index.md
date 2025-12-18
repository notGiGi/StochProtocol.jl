# StochProtocol.jl

```@raw html
<div style="text-align: center; margin: 2rem 0 3rem 0; padding: 3rem 2rem; background: var(--brand-gradient-subtle); border-radius: 16px; border: 2px solid var(--border-primary);">
    <p style="font-size: 1.5rem; color: var(--text-primary); font-weight: 400; margin: 0; line-height: 1.6;">
        Beautiful simulation framework for distributed consensus<br>under stochastic communication
    </p>
    <div style="margin-top: 2rem; display: flex; gap: 1rem; justify-content: center; flex-wrap: wrap;">
        <a href="quickstart/" style="display: inline-block; padding: 0.875rem 2rem; background: var(--brand-gradient); color: white; border-radius: 8px; font-weight: 600; text-decoration: none; box-shadow: var(--shadow-lg); transition: all 0.2s;">Get Started</a>
        <a href="https://github.com/notGiGi/StochProtocol.jl" style="display: inline-block; padding: 0.875rem 2rem; background: var(--bg-elevated); border: 2px solid var(--brand-primary); color: var(--brand-primary); border-radius: 8px; font-weight: 600; text-decoration: none; transition: all 0.2s;">View on GitHub</a>
    </div>
</div>
```

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
        <pre style="margin-top: 1rem; font-size: 0.85rem;">UPDATE RULE:
    EACH ROUND:
        xᵢ ← avg(inbox_with_self)</pre>
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
        <ul style="margin: 0.5rem 0;">
            <li>Multiple delivery models (standard, guaranteed, broadcast)</li>
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

```@raw html
<div style="overflow-x: auto; margin: 2rem 0;">
```

| Feature | Description |
|---------|-------------|
| **Protocol DSL** | Paper-like syntax with full Julia expressions |
| **Delivery Models** | Standard, guaranteed delivery, broadcast, hybrid |
| **Metrics** | Discrepancy, consensus probability, custom metrics |
| **Visualization** | Built-in plotting and table generation |
| **Monte Carlo** | Automatic statistical analysis over thousands of runs |
| **Comparison** | Side-by-side protocol performance analysis |

```@raw html
</div>
```

---

## Learn More

```@raw html
<div class="feature-grid">
    <a href="quickstart/" style="text-decoration: none; color: inherit;">
        <div class="feature-card" style="border-left: 4px solid var(--accent-green);">
            <h4 style="color: var(--accent-green); margin-top: 0;">Quick Start</h4>
            <p style="font-size: 0.95rem; color: var(--text-secondary);">Get up and running in 5 minutes</p>
        </div>
    </a>

    <a href="guides/dsl/" style="text-decoration: none; color: inherit;">
        <div class="feature-card" style="border-left: 4px solid var(--brand-primary);">
            <h4 style="color: var(--brand-primary); margin-top: 0;">Protocol DSL</h4>
            <p style="font-size: 0.95rem; color: var(--text-secondary);">Complete language reference</p>
        </div>
    </a>

    <a href="guides/delivery_models/" style="text-decoration: none; color: inherit;">
        <div class="feature-card" style="border-left: 4px solid var(--accent-orange);">
            <h4 style="color: var(--accent-orange); margin-top: 0;">Delivery Models</h4>
            <p style="font-size: 0.95rem; color: var(--text-secondary);">Communication model options</p>
        </div>
    </a>

    <a href="examples/overview/" style="text-decoration: none; color: inherit;">
        <div class="feature-card" style="border-left: 4px solid var(--accent-blue);">
            <h4 style="color: var(--accent-blue); margin-top: 0;">Examples</h4>
            <p style="font-size: 0.95rem; color: var(--text-secondary);">Real protocols from research papers</p>
        </div>
    </a>

    <a href="api/core/" style="text-decoration: none; color: inherit;">
        <div class="feature-card" style="border-left: 4px solid var(--accent-purple);">
            <h4 style="color: var(--accent-purple); margin-top: 0;">API Reference</h4>
            <p style="font-size: 0.95rem; color: var(--text-secondary);">Complete function documentation</p>
        </div>
    </a>

    <a href="guides/experiments/" style="text-decoration: none; color: inherit;">
        <div class="feature-card" style="border-left: 4px solid var(--accent-pink);">
            <h4 style="color: var(--accent-pink); margin-top: 0;">Running Experiments</h4>
            <p style="font-size: 0.95rem; color: var(--text-secondary);">Simulation and analysis guide</p>
        </div>
    </a>
</div>
```

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
