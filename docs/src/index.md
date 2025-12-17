# StochProtocol.jl

*Simulation and analysis of distributed consensus protocols under stochastic communication*

---

StochProtocol.jl is a Julia framework for researchers and engineers working on distributed consensus algorithms. Write protocols in a clean, mathematical way.

## Installation

```julia-repl
julia> ] add StochProtocol
```

## 60-Second Example

```julia
using StochProtocol

# Define a protocol in mathematical notation
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

# Run Monte Carlo simulations
results = run_protocol(AMP; p_values=0.0:0.1:1.0, repetitions=2000)

# Get beautiful interactive tables
results_table(results)

# Generate publication-quality plots (300 DPI)
plot_discrepancy_vs_p(results; save_path="amp.png")
```

## Why StochProtocol?

### Write Protocols, Not Boilerplate

```julia
# Traditional approach: hundreds of lines
# StochProtocol: mathematical notation that mirrors papers
PROTOCOL MyProtocol
PROCESSES: N
STATE: x ∈ Domain
UPDATE RULE: ...
```

### From Theory to Results in Minutes

- **Declarative DSL** - Focus on the protocol logic, not implementation
- **Automatic Monte Carlo** - Run thousands of simulations effortlessly
- **Rich Metrics** - Discrepancy, consensus probability, round-by-round dynamics
- **Beautiful Output** - Interactive tables and publication-ready plots

### Built for Research

```julia
# Compare multiple protocols
results_comparison_table(Dict(
    "AMP" => results_amp,
    "FV"  => results_fv,
    "Custom" => results_custom
))

# Analyze across parameter spaces
for y in 0.3:0.1:0.7
    results = run_protocol(make_protocol(y); p_values=0.0:0.05:1.0)
    # Analyze...
end
```

## Key Features

!!! tip "Perfect for Jupyter Notebooks"
    `Protocol()` objects display beautifully, tables are interactive DataFrames.

**Core Capabilities**
- Mathematical protocol specification language
- Stochastic message delivery simulation
- Monte Carlo analysis with configurable parameters
- Automatic parallelization for performance

**Analysis Tools**
- Expected discrepancy E[D]
- Consensus probability P(consensus)
- Round-by-round state evolution
- Multi-protocol comparisons


## Getting Started

New to StochProtocol? Check out the [Quick Start Guide](quickstart.md) to learn the basics in 5 minutes.

**Learn by Example:**
- [AMP Protocol](examples/amp.md) - Classic averaging consensus
- [Protocol Comparison](examples/comparison.md) - Compare AMP vs FV
- [Multiple Rounds](examples/multirounds.md) - Analyze convergence

**Understand the Fundamentals:**
- [Protocol DSL](guides/dsl.md) - Master the protocol language
- [Running Experiments](guides/experiments.md) - Configure simulations
- [Visualization](guides/visualization.md) - Create beautiful plots

## Citation

If you use StochProtocol.jl in your research, please cite:

```bibtex
@software{stochprotocol2025,
  title = {StochProtocol.jl: Simulation of Stochastic Consensus Protocols},
  year = {2025},
  url = {https://github.com/notGiGi/StochProtocol.jl}
}
```

## Contributing

Contributions are welcome! Please see our [contribution guidelines](https://github.com/notGiGi/StochProtocol.jl/blob/main/CONTRIBUTING.md).

## License

MIT License - see [LICENSE](https://github.com/notGiGi/StochProtocol.jl/blob/main/LICENSE) for details.
