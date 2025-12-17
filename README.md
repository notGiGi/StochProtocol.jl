# StochProtocol.jl

*Simulation and analysis of distributed consensus protocols under stochastic communication*

[![Documentation](https://img.shields.io/badge/docs-stable-blue.svg)](https://notGiGi.github.io/StochProtocol.jl/)

## Overview

StochProtocol.jl is a Julia framework for researchers and engineers working on distributed consensus algorithms. Define protocols in clean, mathematical notation and analyze their behavior under unreliable communication.

## Quick Start

```julia
using Pkg
Pkg.add("StochProtocol")
```

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

# Beautiful interactive tables
results_table(results)

# Publication-quality plots (300 DPI)
plot_discrepancy_vs_p(results; save_path="amp.png")
```

## Features

- **Declarative DSL** - Focus on protocol logic, not implementation details
- **Automatic Monte Carlo** - Run thousands of simulations effortlessly
- **Rich Metrics** - Discrepancy, consensus probability, round-by-round dynamics
- **Beautiful Output** - Interactive tables and publication-ready plots
- **Protocol Comparison** - Analyze multiple protocols side-by-side
- **Jupyter-Friendly** - Perfect integration with notebooks

## Documentation

Full documentation is available at [notGiGi.github.io/StochProtocol.jl](https://notGiGi.github.io/StochProtocol.jl/)

- [Quick Start Guide](https://notGiGi.github.io/StochProtocol.jl/quickstart/)
- [Protocol DSL Reference](https://notGiGi.github.io/StochProtocol.jl/guides/dsl/)
- [Examples](https://notGiGi.github.io/StochProtocol.jl/examples/amp/)
- [API Reference](https://notGiGi.github.io/StochProtocol.jl/api/core/)

## Example Notebooks

Check out the [examples](examples/) and [notebooks](notebooks/) directories for complete working examples.

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

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
