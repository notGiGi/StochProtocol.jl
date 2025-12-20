# Convergence Analysis

Advanced metrics and analysis tools for understanding protocol convergence behavior.

## Overview

Beyond basic discrepancy tracking, the `ConvergenceAnalysis` module provides sophisticated metrics to characterize convergence speed, stability, and probabilistic guarantees.

## Convergence Rate

Estimate exponential decay rate of discrepancy.

```julia
using StochProtocol

results = run_protocol(protocol;
    p_values = [0.7],
    rounds = 30,
    repetitions = 1000
)

# Extract discrepancy trajectory
discrepancies = results[1].discrepancy_trace

# Compute convergence rate λ
# Discrepancy follows: D(t) ≈ D₀ exp(-λt)
λ = convergence_rate(discrepancies)

println("Convergence rate: $λ")
println("Half-life: $(log(2)/λ) rounds")
```

**Interpretation:**
- Higher λ = faster convergence
- λ ≈ 0 = no convergence
- Half-life = rounds to reduce discrepancy by 50%

## Time to ε-Consensus

Find when discrepancy drops below threshold.

```julia
# Rounds to reach 0.01-consensus
ε = 0.01
t_consensus = time_to_epsilon_consensus(discrepancies, ε)

println("Reached ε=$ε at round: $t_consensus")
```

Returns `-1` if never achieved.

## Stability Metric

Measure consistency across multiple runs.

```julia
# Run multiple times
all_trajectories = []
for i in 1:100
    result = run_protocol(protocol; p=0.7, rounds=20, seed=UInt32(i))
    push!(all_trajectories, result.discrepancy_trace)
end

# Compute stability (lower = more consistent)
stability = stability_metric(all_trajectories)

println("Stability score: $stability")
```

**Interpretation:**
- Low stability = consistent behavior across runs
- High stability = high variance between runs

## Lyapunov Function

Energy-like measure for convergence proofs.

```julia
# Current state of all processes
states = [1.5, 2.3, 1.9, 2.1]

# Compute Lyapunov function V(x) = Σ(xᵢ - x̄)²
V = lyapunov_function(states)

# For convergence proofs, show V decreases over time
state_history = [states_at_round_0, states_at_round_1, ...]
V_trajectory = lyapunov_function(state_history)

# Should be monotonically decreasing
```

**Use case:** Formal convergence proofs, theoretical analysis.

## Mixing Time

Time until distribution is ε-close to stationary (consensus).

```julia
state_history = [
    [1.0, 2.0, 3.0],  # Round 0
    [1.5, 2.0, 2.5],  # Round 1
    [1.8, 2.0, 2.2],  # Round 2
    # ...
]

ε = 0.1
t_mix = mixing_time(state_history, ε)

println("Mixing time: $t_mix rounds")
```

## Diameter Bound Efficiency

Compare actual convergence to theoretical bound.

```julia
using StochProtocol

# Run on ring topology
results = run_protocol(protocol;
    topology = Ring(),
    p_values = [0.7],
    rounds = 50,
    n_processes = 20,
    repetitions = 1000
)

# Get actual convergence time
actual_rounds = time_to_epsilon_consensus(results[1].discrepancy_trace, 0.01)

# Ring diameter
topo = Ring()
d = diameter(topo, 20)  # d = 10 for ring with 20 nodes

p = 0.7
efficiency = diameter_bound_efficiency(actual_rounds, d, p)

println("Theoretical bound: $(d/p) rounds")
println("Actual: $actual_rounds rounds")
println("Efficiency ratio: $efficiency")
```

**Interpretation:**
- Ratio < 1.0 = faster than theoretical bound (tight analysis)
- Ratio ≈ 1.0 = matches theory
- Ratio > 1.0 = slower than expected

## Tail Bound Analysis

Confidence intervals for convergence time.

```julia
# Collect convergence times from many runs
convergence_times = Int[]

for i in 1:1000
    result = run_protocol(protocol; p=0.7, rounds=50, seed=UInt32(i))
    t = time_to_epsilon_consensus(result.discrepancy_trace, 0.01)
    if t > 0
        push!(convergence_times, t)
    end
end

# Compute 95% confidence interval
mean_t, lower, upper = tail_bound_analysis(convergence_times; confidence=0.95)

println("Mean convergence time: $mean_t rounds")
println("95% CI: [$lower, $upper]")
```

## Phase Transition Detection

Find critical p where convergence behavior changes dramatically.

```julia
p_values = 0.0:0.05:1.0
convergence_times = Float64[]

for p in p_values
    result = run_protocol(protocol; p=p, rounds=100, repetitions=500)
    avg_time = mean([time_to_epsilon_consensus(r.discrepancy_trace, 0.01)
                     for r in result])
    push!(convergence_times, avg_time)
end

# Find phase transition point
p_critical = phase_transition_detection(p_values, convergence_times)

println("Phase transition at p ≈ $p_critical")
```

**Use case:** Find minimum communication probability needed for efficient convergence.

## Convergence Probability

Estimate probability of reaching consensus within time limit.

```julia
# Run many times
trajectories = [run_protocol(protocol; p=0.6, rounds=20, seed=UInt32(i)).discrepancy_trace
                for i in 1:1000]

# Probability of 0.01-consensus within 15 rounds
prob = convergence_probability(trajectories, 0.01, 15)

println("P(consensus by round 15) = $prob")
```

## Expected Rounds to Consensus

Summary statistics for convergence time distribution.

```julia
convergence_times = [time_to_epsilon_consensus(traj, 0.01) for traj in trajectories]

mean_t, median_t, p90, p99 = expected_rounds_to_consensus(convergence_times)

println("Mean: $mean_t rounds")
println("Median: $median_t rounds")
println("90th percentile: $p90 rounds")
println("99th percentile: $p99 rounds")
```

**Interpretation:**
- **Mean**: Average case
- **Median**: Typical case
- **90th percentile**: Most runs finish by this time
- **99th percentile**: Nearly all runs finish by this time

## Spectral Gap Estimate

Estimate spectral gap from convergence rate.

```julia
λ = convergence_rate(discrepancies)
d = diameter(topology, n_processes)

spectral_gap = spectral_gap_estimate(λ, d)

println("Estimated spectral gap: $spectral_gap")
```

**Use case:** Connect empirical observations to theoretical graph properties.

## Contraction Factor

Single-round contraction of discrepancy.

```julia
D_before = 10.0
D_after = 7.5

ρ = contraction_factor(D_before, D_after)
# ρ = 0.75 means 25% reduction per round
```

Average over all rounds:

```julia
avg_ρ = average_contraction(discrepancies)

println("Average contraction factor: $avg_ρ")
println("Per-round reduction: $(100*(1-avg_ρ))%")
```

## Variance Reduction Rate

How quickly variance across processes decreases.

```julia
state_history = [
    [1.0, 5.0, 3.0, 2.0],  # Round 0
    [2.0, 4.0, 3.0, 2.5],  # Round 1
    [2.5, 3.5, 3.0, 2.8],  # Round 2
    # ...
]

rate = variance_reduction_rate(state_history)

println("Variance reduction rate: $rate")
```

## Complete Example

Comprehensive convergence analysis:

```julia
using StochProtocol

protocol = Protocol("""
PROTOCOL TestProtocol
PROCESSES: 10
STATE: x ∈ ℝ
INITIAL: xᵢ = i
CHANNEL: stochastic

UPDATE RULE:
    EACH ROUND:
        xᵢ ← avg(inbox_with_self)

METRICS:
    discrepancy
""")

# Run experiments
results = run_protocol(protocol;
    p_values = 0.5:0.1:1.0,
    rounds = 50,
    repetitions = 1000
)

println("="^60)
println("Convergence Analysis Report")
println("="^60)

for (i, p) in enumerate(0.5:0.1:1.0)
    println("\nCommunication probability p = $p")
    println("-"^40)

    disc = results[i].discrepancy_trace

    # Convergence rate
    λ = convergence_rate(disc)
    println("Convergence rate λ: $(round(λ, digits=4))")
    println("Half-life: $(round(log(2)/λ, digits=2)) rounds")

    # Time to consensus
    t_001 = time_to_epsilon_consensus(disc, 0.01)
    println("Time to 0.01-consensus: $t_001 rounds")

    # Contraction
    ρ = average_contraction(disc)
    println("Average contraction: $(round(100*(1-ρ), digits=1))% per round")
end

println("\n" * "="^60)
```

## Best Practices

1. **Multiple metrics**: Use several metrics for complete picture
2. **High repetitions**: Statistical metrics need many samples (1000+)
3. **Appropriate ε**: Choose epsilon based on application needs
4. **Compare scenarios**: Analyze across different p, topologies, etc.
5. **Theoretical validation**: Compare empirical results to known bounds
