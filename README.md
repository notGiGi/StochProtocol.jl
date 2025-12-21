# StochProtocol.jl

*Simulation and analysis of distributed consensus protocols under stochastic communication*

[![Documentation](https://img.shields.io/badge/docs-stable-blue.svg)](https://notGiGi.github.io/StochProtocol.jl/)
[![GitHub Actions](https://github.com/notGiGi/StochProtocol.jl/workflows/Documentation/badge.svg)](https://github.com/notGiGi/StochProtocol.jl/actions)
[![Binder](https://mybinder.org/badge_logo.svg)](https://mybinder.org/v2/gh/notGiGi/StochProtocol.jl/main?urlpath=pluto/open?path=notebooks/interactive_example.jl)

## Overview

StochProtocol.jl is a Julia framework for researchers and engineers working on distributed consensus algorithms. Define protocols in clean, mathematical notation and analyze their behavior under unreliable communication.

## Quick Start

### Try it Now - No Installation Required

**Option 1: Google Colab (Recommended for researchers)**

[![Open In Colab](https://colab.research.google.com/assets/colab-badge.svg)](https://colab.research.google.com/github/notGiGi/StochProtocol.jl/blob/main/notebooks/colab_quickstart.ipynb)

- **First run**: ~5 minutes setup, then instant
- **Requires**: Google account (most people already have one)
- **Best for**: Serious experiments, long sessions
- **Pro**: Doesn't disconnect for 90 minutes

**Option 2: Pluto.jl via Binder**

[![Binder](https://mybinder.org/badge_logo.svg)](https://mybinder.org/v2/gh/notGiGi/StochProtocol.jl/main?urlpath=pluto/open?path=notebooks/interactive_example.jl)

- **First run**: ~3 minutes, then ~1 minute
- **Requires**: Nothing! No account needed
- **Best for**: Quick demos, exploration
- **Note**: Disconnects after 10 minutes of inactivity

### Or Install Locally

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


plot_discrepancy_vs_p(results; save_path="amp.png")
```

## Features

- **Declarative** - Focus on protocol logic, not implementation details
- **Automatic Monte Carlo** - Run thousands of simulations effortlessly
- **Metrics** - Discrepancy, consensus probability, round-by-round dynamics
- **Beautiful Output** - Interactive tables and plots
- **Protocol Comparison** - Analyze multiple protocols side by side


## Documentation

Full documentation is available at [notGiGi.github.io/StochProtocol.jl](https://notgigi.github.io/StochProtocol.jl/dev/)


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

Contributions are welcome. Please feel free to submit a Pull Request.
