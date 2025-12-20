"""
    ConvergenceAnalysis

Advanced convergence metrics and analysis tools for distributed protocols.

This module provides sophisticated metrics beyond basic discrepancy and consensus,
including convergence rates, stability analysis, and Lyapunov-style measures.

# Available Metrics

- `convergence_rate(results)` - Exponential decay rate
- `time_to_epsilon_consensus(results, epsilon)` - Rounds to ε-consensus
- `stability_metric(results)` - Variance in convergence behavior
- `lyapunov_function(results)` - Energy-like convergence measure
- `mixing_time(results, epsilon)` - Time to near-uniform distribution
- `diameter_bound_efficiency(results, topology)` - How close to theoretical bound

# Example

```julia
using StochProtocol

results = run_protocol(protocol; p_values=0.5:0.1:1.0, repetitions=1000)

# Compute convergence rate
rate = convergence_rate(results)

# Time to 0.01-consensus
t_eps = time_to_epsilon_consensus(results, 0.01)

# Stability analysis
stability = stability_metric(results)
```
"""
module ConvergenceAnalysis

export convergence_rate, time_to_epsilon_consensus,
       stability_metric, lyapunov_function,
       mixing_time, diameter_bound_efficiency,
       tail_bound_analysis, phase_transition_detection,
       convergence_probability, expected_rounds_to_consensus,
       spectral_gap_estimate

using Statistics

"""
    convergence_rate(discrepancies::Vector{Float64}) → Float64

Estimate exponential convergence rate from discrepancy trajectory.
Fits D(t) ≈ D₀ * exp(-λt) and returns λ.

Returns NaN if convergence is not exponential.
"""
function convergence_rate(discrepancies::Vector{Float64})
    # Remove zeros to avoid log(0)
    valid_idx = findall(d -> d > 1e-10, discrepancies)

    if length(valid_idx) < 3
        return NaN
    end

    log_disc = log.(discrepancies[valid_idx])
    rounds = Float64.(valid_idx)

    # Linear regression on log scale
    n = length(rounds)
    x_mean = mean(rounds)
    y_mean = mean(log_disc)

    numerator = sum((rounds[i] - x_mean) * (log_disc[i] - y_mean) for i in 1:n)
    denominator = sum((rounds[i] - x_mean)^2 for i in 1:n)

    if abs(denominator) < 1e-10
        return NaN
    end

    slope = numerator / denominator

    # Convergence rate is negative slope
    return -slope
end

"""
    time_to_epsilon_consensus(discrepancies::Vector{Float64}, epsilon::Float64) → Int

Find first round where discrepancy falls below epsilon.
Returns -1 if never achieved.
"""
function time_to_epsilon_consensus(discrepancies::Vector{Float64}, epsilon::Float64)
    for (round, disc) in enumerate(discrepancies)
        if disc < epsilon
            return round
        end
    end
    return -1
end

"""
    stability_metric(discrepancy_trajectories::Vector{Vector{Float64}}) → Float64

Measure stability across multiple runs. Lower values indicate more consistent convergence.

Computes average standard deviation of discrepancies across runs at each round.
"""
function stability_metric(discrepancy_trajectories::Vector{Vector{Float64}})
    # Ensure all trajectories have same length
    min_length = minimum(length.(discrepancy_trajectories))

    if min_length == 0
        return NaN
    end

    variances = Float64[]
    for round in 1:min_length
        values = [traj[round] for traj in discrepancy_trajectories]
        push!(variances, std(values))
    end

    return mean(variances)
end

"""
    lyapunov_function(states::Vector{Vector{Float64}}) → Float64

Compute Lyapunov-like energy function for current state.
V(x) = Σᵢ (xᵢ - x̄)² where x̄ is the mean.

Useful for proving convergence theoretically.
"""
function lyapunov_function(states::Vector{Float64})
    x_mean = mean(states)
    return sum((x - x_mean)^2 for x in states)
end

function lyapunov_function(state_history::Vector{Vector{Float64}})
    return [lyapunov_function(states) for states in state_history]
end

"""
    mixing_time(distribution_history::Vector{Vector{Float64}}, epsilon::Float64) → Int

Estimate mixing time: rounds until distribution is ε-close to stationary.

For consensus protocols, stationary distribution is uniform at consensus value.
Returns -1 if not achieved.
"""
function mixing_time(state_history::Vector{Vector{Float64}}, epsilon::Float64)
    if isempty(state_history)
        return -1
    end

    # Target is consensus (all equal)
    target_value = mean(state_history[end])

    for (round, states) in enumerate(state_history)
        # Check if all within epsilon of target
        if all(abs(x - target_value) < epsilon for x in states)
            return round
        end
    end

    return -1
end

"""
    diameter_bound_efficiency(
        actual_rounds::Int,
        diameter::Int,
        p::Float64
    ) → Float64

Compare actual convergence time to theoretical diameter-based bound.

For many protocols, E[T] ≈ O(diameter / p).
Returns ratio: actual / theoretical (lower is better).
"""
function diameter_bound_efficiency(actual_rounds::Int, diameter::Int, p::Float64)
    if p < 1e-10 || diameter == 0
        return NaN
    end

    theoretical_bound = diameter / p
    return actual_rounds / theoretical_bound
end

"""
    tail_bound_analysis(
        convergence_rounds::Vector{Int},
        confidence::Float64 = 0.95
    ) → (mean, lower, upper)

Compute confidence interval for convergence time using tail bounds.

Returns (mean, lower_bound, upper_bound) for given confidence level.
"""
function tail_bound_analysis(convergence_rounds::Vector{Int}; confidence::Float64=0.95)
    if isempty(convergence_rounds)
        return (NaN, NaN, NaN)
    end

    sorted = sort(convergence_rounds)
    n = length(sorted)

    mean_rounds = mean(sorted)

    # Empirical quantiles
    alpha = 1.0 - confidence
    lower_idx = max(1, floor(Int, n * alpha / 2))
    upper_idx = min(n, ceil(Int, n * (1 - alpha / 2)))

    lower_bound = sorted[lower_idx]
    upper_bound = sorted[upper_idx]

    return (mean_rounds, lower_bound, upper_bound)
end

"""
    phase_transition_detection(
        p_values::Vector{Float64},
        convergence_times::Vector{Float64}
    ) → Float64

Detect phase transition in p where convergence time drops sharply.

Returns p* where maximum derivative occurs (steepest drop).
Returns NaN if no clear transition.
"""
function phase_transition_detection(p_values::Vector{Float64}, convergence_times::Vector{Float64})
    if length(p_values) < 3
        return NaN
    end

    # Compute discrete derivative
    derivatives = Float64[]
    for i in 2:length(p_values)
        dp = p_values[i] - p_values[i-1]
        dt = convergence_times[i] - convergence_times[i-1]
        if abs(dp) > 1e-10
            push!(derivatives, abs(dt / dp))
        else
            push!(derivatives, 0.0)
        end
    end

    if isempty(derivatives)
        return NaN
    end

    # Find maximum derivative (steepest change)
    max_idx = argmax(derivatives)
    return p_values[max_idx + 1]  # +1 because derivatives start at index 2
end

"""
    convergence_probability(
        discrepancies::Vector{Vector{Float64}},
        epsilon::Float64,
        max_round::Int
    ) → Float64

Estimate probability of ε-consensus within max_round rounds.
"""
function convergence_probability(
    discrepancy_trajectories::Vector{Vector{Float64}},
    epsilon::Float64,
    max_round::Int
)
    if isempty(discrepancy_trajectories)
        return 0.0
    end

    converged_count = 0
    for trajectory in discrepancy_trajectories
        if length(trajectory) >= max_round && trajectory[max_round] < epsilon
            converged_count += 1
        end
    end

    return converged_count / length(discrepancy_trajectories)
end

"""
    expected_rounds_to_consensus(
        convergence_rounds::Vector{Int}
    ) → (mean, median, p90, p99)

Compute summary statistics for rounds to consensus.

Returns (mean, median, 90th percentile, 99th percentile).
"""
function expected_rounds_to_consensus(convergence_rounds::Vector{Int})
    if isempty(convergence_rounds)
        return (NaN, NaN, NaN, NaN)
    end

    # Filter out -1 (never converged)
    valid = filter(r -> r > 0, convergence_rounds)

    if isempty(valid)
        return (NaN, NaN, NaN, NaN)
    end

    sorted = sort(valid)
    n = length(sorted)

    mean_val = mean(sorted)
    median_val = sorted[div(n, 2) + 1]
    p90 = sorted[min(n, ceil(Int, 0.9 * n))]
    p99 = sorted[min(n, ceil(Int, 0.99 * n))]

    return (mean_val, median_val, p90, p99)
end

"""
    spectral_gap_estimate(
        convergence_rate::Float64,
        topology_diameter::Int
    ) → Float64

Estimate spectral gap of the system from convergence rate.

For many protocols, λ₂ (second eigenvalue) relates to convergence.
Returns estimated 1 - λ₂ (spectral gap).
"""
function spectral_gap_estimate(convergence_rate::Float64, topology_diameter::Int)
    if topology_diameter == 0
        return NaN
    end

    # Heuristic: convergence_rate ≈ spectral_gap / diameter
    return convergence_rate * topology_diameter
end

"""
    contraction_factor(
        discrepancy_before::Float64,
        discrepancy_after::Float64
    ) → Float64

Compute single-round contraction factor.
ρ = D(t+1) / D(t)

ρ < 1 indicates contraction, ρ = 0 indicates immediate consensus.
"""
function contraction_factor(discrepancy_before::Float64, discrepancy_after::Float64)
    if discrepancy_before < 1e-10
        return 0.0  # Already at consensus
    end
    return discrepancy_after / discrepancy_before
end

"""
    average_contraction(discrepancies::Vector{Float64}) → Float64

Compute geometric mean of contraction factors across all rounds.
"""
function average_contraction(discrepancies::Vector{Float64})
    if length(discrepancies) < 2
        return NaN
    end

    factors = Float64[]
    for i in 2:length(discrepancies)
        if discrepancies[i-1] > 1e-10
            push!(factors, discrepancies[i] / discrepancies[i-1])
        end
    end

    if isempty(factors)
        return NaN
    end

    # Geometric mean
    return exp(mean(log.(factors)))
end

"""
    variance_reduction_rate(states_history::Vector{Vector{Float64}}) → Float64

Measure how quickly variance across processes decreases.
"""
function variance_reduction_rate(states_history::Vector{Vector{Float64}})
    variances = [var(states) for states in states_history]
    return convergence_rate(variances)
end

end  # module ConvergenceAnalysis
