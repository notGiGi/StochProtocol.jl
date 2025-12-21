# Google Colab Optimization Guide

Tips and tricks for using StochProtocol.jl efficiently in Google Colab.

## Why is Colab Slow?

Google Colab is designed for Python. When using Julia:
- Must download and install Julia runtime (~100 MB)
- Must download all package dependencies (~200-500 MB)
- Must precompile everything from scratch
- Environment resets on disconnect

**First run: ~5-10 minutes**
**Subsequent runs (same session): ~30 seconds**

## Quick Start (Optimized)

Use our pre-configured notebook:

[![Open In Colab](https://colab.research.google.com/assets/colab-badge.svg)](https://colab.research.google.com/github/notGiGi/StochProtocol.jl/blob/main/notebooks/colab_quickstart.ipynb)

This notebook includes:
- Fast Julia installation
- Minimal dependencies
- Optimized precompilation
- Example workflows

## Manual Installation (Fastest Method)

### Cell 1: Install Julia

```python
%%shell
# Install Julia 1.10 (only needed first time)
if [ ! -x "$(command -v julia)" ]; then
    wget -q https://julialang-s3.julialang.org/bin/linux/x64/1.10/julia-1.10.0-linux-x86_64.tar.gz
    tar -xzf julia-1.10.0-linux-x86_64.tar.gz
    sudo mv julia-1.10.0 /opt/julia
    sudo ln -s /opt/julia/bin/julia /usr/local/bin/julia
    rm julia-1.10.0-linux-x86_64.tar.gz
fi
julia --version
```

### Cell 2: Install StochProtocol (Fast)

```bash
%%shell
julia -e '
using Pkg
Pkg.activate(temp=true)

# Skip auto-precompilation (do it manually later)
ENV["JULIA_PKG_PRECOMPILE_AUTO"] = "0"

# Install from GitHub
Pkg.add(url="https://github.com/notGiGi/StochProtocol.jl")
Pkg.add("Plots")

# Precompile only essentials
Pkg.precompile(["StochProtocol", "Plots"])
'
```

**Time: ~2-3 minutes** (vs 30+ minutes with standard install)

### Cell 3: Use StochProtocol

```julia
using StochProtocol
using Plots

# Your code here
protocol = Protocol("""
PROTOCOL MyProtocol
PROCESSES: 5
STATE: x ∈ ℝ
INITIAL: xᵢ = i
CHANNEL: stochastic

UPDATE RULE:
    EACH ROUND:
        xᵢ ← avg(inbox_with_self)

METRICS:
    discrepancy
""")

results = run_protocol(protocol;
    p_values = 0.5:0.1:1.0,
    rounds = 20,
    repetitions = 500
)

results_table(results)
```

## Optimization Tips

### 1. Use GR Backend for Plots

```julia
# Add to top of notebook
ENV["GKSwstype"] = "100"  # Headless GR backend
using Plots
gr()  # Use GR backend (fastest for Colab)
```

### 2. Reduce Repetitions for Prototyping

```julia
# During development - fast iterations
results = run_protocol(protocol; repetitions=100)

# For final results - accuracy
results = run_protocol(protocol; repetitions=2000)
```

### 3. Cache Results

```julia
# Run expensive computation once
if !@isdefined(cached_results)
    global cached_results = run_protocol(protocol; repetitions=2000)
end

# Use cached results
plot_discrepancy_vs_p(cached_results)
```

### 4. Use Fewer Processes for Testing

```julia
# Fast testing with 3 processes
PROTOCOL TestProtocol
PROCESSES: 3
...

# Production with 20 processes
PROTOCOL ProductionProtocol
PROCESSES: 20
...
```

### 5. Persistent Depot (Advanced)

Keep packages across sessions using Google Drive:

```python
from google.colab import drive
drive.mount('/content/drive')

# Set Julia depot to Google Drive
import os
os.environ['JULIA_DEPOT_PATH'] = '/content/drive/MyDrive/julia_depot'
```

Then packages persist between sessions!

## Troubleshooting

### "Package took too long to precompile"

**Solution**: Skip auto-precompilation

```julia
ENV["JULIA_PKG_PRECOMPILE_AUTO"] = "0"
using Pkg
Pkg.add("StochProtocol")
# Manually precompile later
Pkg.precompile()
```

### "Out of Memory"

**Solution 1**: Use fewer repetitions

```julia
results = run_protocol(protocol; repetitions=500)  # Instead of 2000
```

**Solution 2**: Use Colab Pro (more RAM)

### "Session Disconnected"

Colab disconnects after 90 minutes of inactivity.

**Solution**: Keep session alive with this JavaScript:

```javascript
// In browser console (F12)
function KeepClicking(){
    console.log("Clicking");
    document.querySelector("colab-connect-button").click();
}
setInterval(KeepClicking, 60000);  // Click every 60 seconds
```

### First Load Still Slow

**Solution**: Use Binder instead

Binder is better optimized for Julia than Colab:

[![Binder](https://mybinder.org/badge_logo.svg)](https://mybinder.org/v2/gh/notGiGi/StochProtocol.jl/main?urlpath=pluto/open?path=notebooks/interactive_example.jl)

- No account needed
- Julia-native environment
- Faster initial load (~2 minutes)
- Interactive Pluto.jl interface

## Comparison: Colab vs Binder vs Local

| Feature | Colab | Binder | Local |
|---------|-------|--------|-------|
| **First load** | 5-10 min | 2-3 min | 1 min |
| **Subsequent loads** | 30 sec | 30 sec | instant |
| **Requires account** | Yes (Google) | No | No |
| **Session timeout** | 90 min idle | 10 min idle | Never |
| **RAM** | 12 GB (free) / 25 GB (Pro) | ~2 GB | Unlimited |
| **Storage** | 15 GB (Google Drive) | Temporary | Unlimited |
| **GPU** | Yes (free) | No | Depends |
| **Best for** | Large experiments | Quick demos | Development |

## Recommendation

**For your researchers (older, non-technical):**

1. **First choice**: Binder + Pluto.jl
   - No account needed
   - Fastest for demos
   - Interactive interface
   - Just click and wait 2 minutes

2. **Second choice**: Colab with optimized notebook
   - If they already have Google account
   - Better for long experiments (no 10min timeout)
   - More RAM for large simulations

3. **Avoid**: Manual Colab setup
   - Too slow and complicated
   - 30+ minute install time
   - Lots of command-line work

## Example: Optimized Colab Workflow

```julia
# === CELL 1: One-time setup ===
# Run this once per session

using Pkg
Pkg.activate(temp=true)
ENV["JULIA_PKG_PRECOMPILE_AUTO"] = "0"
Pkg.add(url="https://github.com/notGiGi/StochProtocol.jl")
Pkg.add("Plots")
Pkg.precompile()

# === CELL 2: Load packages ===
using StochProtocol
using Plots
ENV["GKSwstype"] = "100"
gr()

# === CELL 3: Define protocol ===
protocol = Protocol("""
PROTOCOL AveragingProtocol
PROCESSES: 5
STATE: x ∈ ℝ
INITIAL: xᵢ = i
CHANNEL: stochastic

UPDATE RULE:
    EACH ROUND:
        xᵢ ← avg(inbox_with_self)

METRICS:
    discrepancy
""")

# === CELL 4: Run experiments ===
results = run_protocol(protocol;
    p_values = 0.5:0.1:1.0,
    rounds = 20,
    repetitions = 1000
)

# === CELL 5: Visualize ===
results_table(results)
plot_discrepancy_vs_p(results)
```

Total time: **~3-4 minutes** from start to results.
