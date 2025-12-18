### A Pluto.jl notebook ###
# v0.19.40

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
end

# ╔═╡ 1
begin
    using StochProtocol
    using PlutoUI
    using Plots
end

# ╔═╡ 2
md"""
# StochProtocol.jl - Interactive Demo

Welcome! This notebook lets you experiment with distributed consensus protocols interactively.

**No installation required** - everything runs in your browser through Binder.
"""

# ╔═╡ 3
md"""
## Configure Protocol Parameters

Adjust the sliders below to see how different parameters affect protocol behavior:
"""

# ╔═╡ 4
md"""
**Number of Processes:** $(@bind n_processes Slider(2:20, default=5, show_value=true))

**Communication Probability (p):** $(@bind p_value Slider(0.0:0.05:1.0, default=0.7, show_value=true))

**Number of Rounds:** $(@bind n_rounds Slider(1:20, default=10, show_value=true))

**Repetitions (for Monte Carlo):** $(@bind repetitions Slider(100:100:2000, default=1000, show_value=true))
"""

# ╔═╡ 5
md"""
## Protocol Definition

This is the **Averaging Protocol** - each process averages values from received messages:
"""

# ╔═╡ 6
begin
    protocol_def = """
    PROTOCOL AveragingProtocol
    PROCESSES: $n_processes
    STATE: x ∈ ℝ
    INITIAL: xᵢ = i
    CHANNEL: stochastic

    UPDATE RULE:
        EACH ROUND:
            xᵢ ← avg(inbox_with_self)

    METRICS:
        discrepancy
        consensus
    """

    Markdown.parse("""
    ```
    $protocol_def
    ```
    """)
end

# ╔═╡ 7
md"""
## Run Simulation

Click the button below to run the simulation with your chosen parameters:
"""

# ╔═╡ 8
@bind run_button CounterButton("Run Simulation")

# ╔═╡ 9
begin
    run_button  # Trigger reactivity

    # Define protocol
    averaging = Protocol(protocol_def)

    # Run simulation
    results = run_protocol(averaging;
        p_values = [p_value],
        rounds = n_rounds,
        repetitions = repetitions
    )

    md"""
    ✅ Simulation complete with **$repetitions repetitions**!
    """
end

# ╔═╡ 10
md"""
## Results

### Convergence Analysis
"""

# ╔═╡ 11
begin
    # Plot discrepancy over rounds
    plot_discrepancy_vs_p(results;
        title = "Discrepancy vs Rounds (p=$p_value)",
        xlabel = "Round",
        ylabel = "Discrepancy",
        legend = false
    )
end

# ╔═╡ 12
md"""
### Summary Statistics
"""

# ╔═╡ 13
results_table(results)

# ╔═╡ 14
md"""
---

## What's Happening?

- **Discrepancy**: Measures how far apart the processes are (max - min values)
- **Consensus Probability**: Chance that all processes have the exact same value
- **Higher p**: More communication → faster convergence
- **More rounds**: More opportunities to average → values get closer

### Try This:
1. Set **p = 1.0** (guaranteed delivery) - watch how fast it converges!
2. Set **p = 0.2** (low probability) - convergence is slower
3. Increase **processes** to 20 - see how network size affects dynamics
4. Change **rounds** to see the trajectory over time

---

**Want to learn more?** Visit the [StochProtocol.jl documentation](https://notGiGi.github.io/StochProtocol.jl/)
"""

# ╔═╡ Cell order:
# ╟─1
# ╟─2
# ╟─3
# ╟─4
# ╟─5
# ╟─6
# ╟─7
# ╟─8
# ╟─9
# ╟─10
# ╟─11
# ╟─12
# ╟─13
# ╟─14
