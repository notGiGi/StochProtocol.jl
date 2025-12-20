"""
    Faults

Fault models for distributed systems: crash failures, Byzantine faults, network partitions.

This module provides realistic failure models to test protocol robustness under adversarial
or unreliable conditions.

# Available Fault Models

- `NoFaults()` - All processes behave correctly (default)
- `CrashFaults(crash_prob, crash_round)` - Processes crash and stop sending
- `ByzantineFaults(byzantine_nodes, strategy)` - Malicious behavior
- `NetworkPartition(partition_round, partition_duration, groups)` - Network splits
- `MessageCorruption(corruption_prob)` - Messages get corrupted
- `DelayFaults(delay_prob, max_delay)` - Variable message delays

# Example

```julia
using StochProtocol

# Test protocol with 20% crash probability at round 5
results = run_protocol(protocol;
    fault_model = CrashFaults(crash_prob=0.2, crash_round=5),
    repetitions = 1000
)

# Byzantine fault with 2 malicious nodes
results = run_protocol(protocol;
    fault_model = ByzantineFaults(byzantine_nodes=[1, 2], strategy=:max_value),
    rounds = 20
)

# Network partition
results = run_protocol(protocol;
    fault_model = NetworkPartition(
        partition_round = 5,
        partition_duration = 3,
        groups = [[1,2,3], [4,5,6]]
    )
)
```
"""
module Faults

export FaultModel,
       NoFaults, CrashFaults, ByzantineFaults,
       NetworkPartition, MessageCorruption, DelayFaults,
       TransientFaults, CompositeFaults,
       apply_faults, is_faulty, crashed_nodes

using Random

"""
    FaultModel

Abstract type for fault models in distributed systems.
"""
abstract type FaultModel end

"""
    NoFaults()

No faults - all processes behave correctly. This is the default.
"""
struct NoFaults <: FaultModel end

"""
    CrashFaults(crash_prob::Float64, crash_round::Int)

Crash failure model. Processes crash at `crash_round` with probability `crash_prob`.
Once crashed, a process stops sending messages permanently.

# Fields
- `crash_prob`: Probability each process crashes (0.0 to 1.0)
- `crash_round`: Round at which crashes occur
- `seed`: Random seed for reproducibility

# Example
```julia
CrashFaults(crash_prob=0.3, crash_round=5)  # 30% crash at round 5
```
"""
struct CrashFaults <: FaultModel
    crash_prob::Float64
    crash_round::Int
    seed::UInt32

    function CrashFaults(; crash_prob::Float64, crash_round::Int, seed::UInt32=UInt32(0))
        0.0 <= crash_prob <= 1.0 || error("crash_prob must be in [0,1]")
        crash_round > 0 || error("crash_round must be positive")
        new(crash_prob, crash_round, seed)
    end
end

"""
    ByzantineFaults

Byzantine failure model. Specified nodes behave maliciously according to a strategy.

# Strategies
- `:max_value` - Always send maximum possible value
- `:min_value` - Always send minimum possible value
- `:random` - Send random values
- `:opposite` - Send negated values
- `:silent` - Don't send any messages
- `:lie_to_half` - Send correct to half, lies to other half

# Fields
- `byzantine_nodes`: Vector of node IDs that are Byzantine
- `strategy`: Attack strategy (see above)

# Example
```julia
ByzantineFaults(byzantine_nodes=[1,2], strategy=:max_value)
```
"""
struct ByzantineFaults <: FaultModel
    byzantine_nodes::Vector{Int}
    strategy::Symbol

    function ByzantineFaults(; byzantine_nodes::Vector{Int}, strategy::Symbol=:random)
        isempty(byzantine_nodes) && error("byzantine_nodes cannot be empty")
        all(n -> n > 0, byzantine_nodes) || error("Node IDs must be positive")
        strategy in [:max_value, :min_value, :random, :opposite, :silent, :lie_to_half] ||
            error("Unknown Byzantine strategy: $strategy")
        new(byzantine_nodes, strategy)
    end
end

"""
    NetworkPartition

Network partition model. The network splits into disconnected groups.

# Fields
- `partition_round`: Round when partition begins
- `partition_duration`: How many rounds partition lasts (0 = permanent)
- `groups`: Vector of node groups (e.g., [[1,2], [3,4]])

# Example
```julia
# Split into two groups at round 5 for 3 rounds
NetworkPartition(
    partition_round = 5,
    partition_duration = 3,
    groups = [[1,2,3], [4,5,6]]
)
```
"""
struct NetworkPartition <: FaultModel
    partition_round::Int
    partition_duration::Int
    groups::Vector{Vector{Int}}

    function NetworkPartition(; partition_round::Int, partition_duration::Int, groups::Vector{Vector{Int}})
        partition_round > 0 || error("partition_round must be positive")
        partition_duration >= 0 || error("partition_duration must be non-negative")
        length(groups) >= 2 || error("Need at least 2 groups for partition")
        # Check groups are disjoint
        all_nodes = reduce(vcat, groups)
        length(all_nodes) == length(unique(all_nodes)) || error("Groups must be disjoint")
        new(partition_round, partition_duration, groups)
    end
end

"""
    MessageCorruption(corruption_prob::Float64)

Message corruption model. Messages get corrupted with given probability.

# Fields
- `corruption_prob`: Probability a message gets corrupted (0.0 to 1.0)
- `corruption_type`: How to corrupt (:flip_bits, :zero, :max, :random)
- `seed`: Random seed

# Example
```julia
MessageCorruption(corruption_prob=0.1, corruption_type=:random)
```
"""
struct MessageCorruption <: FaultModel
    corruption_prob::Float64
    corruption_type::Symbol
    seed::UInt32

    function MessageCorruption(; corruption_prob::Float64, corruption_type::Symbol=:random, seed::UInt32=UInt32(0))
        0.0 <= corruption_prob <= 1.0 || error("corruption_prob must be in [0,1]")
        corruption_type in [:flip_bits, :zero, :max, :random] ||
            error("Unknown corruption type: $corruption_type")
        new(corruption_prob, corruption_type, seed)
    end
end

"""
    DelayFaults(delay_prob::Float64, max_delay::Int)

Message delay model. Messages can be delayed by up to `max_delay` rounds.

# Fields
- `delay_prob`: Probability a message gets delayed
- `max_delay`: Maximum rounds a message can be delayed

# Example
```julia
DelayFaults(delay_prob=0.2, max_delay=3)  # 20% delayed up to 3 rounds
```
"""
struct DelayFaults <: FaultModel
    delay_prob::Float64
    max_delay::Int
    seed::UInt32

    function DelayFaults(; delay_prob::Float64, max_delay::Int, seed::UInt32=UInt32(0))
        0.0 <= delay_prob <= 1.0 || error("delay_prob must be in [0,1]")
        max_delay > 0 || error("max_delay must be positive")
        new(delay_prob, max_delay, seed)
    end
end

"""
    TransientFaults

Transient fault model. Faults occur randomly during a time window.

# Fields
- `fault_prob`: Probability of fault per round per node
- `start_round`: When transient faults can begin
- `end_round`: When transient faults stop (0 = never)
- `fault_type`: Type of transient fault (:send_wrong, :skip_update, :corrupt_state)

# Example
```julia
TransientFaults(
    fault_prob = 0.05,
    start_round = 3,
    end_round = 10,
    fault_type = :send_wrong
)
```
"""
struct TransientFaults <: FaultModel
    fault_prob::Float64
    start_round::Int
    end_round::Int
    fault_type::Symbol
    seed::UInt32

    function TransientFaults(; fault_prob::Float64, start_round::Int, end_round::Int=0,
                             fault_type::Symbol=:send_wrong, seed::UInt32=UInt32(0))
        0.0 <= fault_prob <= 1.0 || error("fault_prob must be in [0,1]")
        start_round > 0 || error("start_round must be positive")
        end_round >= 0 || error("end_round must be non-negative")
        fault_type in [:send_wrong, :skip_update, :corrupt_state] ||
            error("Unknown transient fault type: $fault_type")
        new(fault_prob, start_round, end_round, seed)
    end
end

"""
    CompositeFaults(models::Vector{FaultModel})

Combine multiple fault models. All faults apply simultaneously.

# Example
```julia
CompositeFaults([
    CrashFaults(crash_prob=0.1, crash_round=5),
    MessageCorruption(corruption_prob=0.05)
])
```
"""
struct CompositeFaults <: FaultModel
    models::Vector{FaultModel}

    function CompositeFaults(models::Vector{FaultModel})
        !isempty(models) || error("CompositeFaults needs at least one model")
        new(models)
    end
end

# ============================================================================
# Fault Application Functions
# ============================================================================

"""
    is_faulty(fault_model::FaultModel, node::Int, round::Int) → Bool

Check if a node is experiencing a fault at the given round.
"""
function is_faulty(fault_model::NoFaults, node::Int, round::Int)
    return false
end

function is_faulty(fault_model::CrashFaults, node::Int, round::Int)
    if round >= fault_model.crash_round
        rng = Random.MersenneTwister(fault_model.seed + UInt32(node))
        return rand(rng) < fault_model.crash_prob
    end
    return false
end

function is_faulty(fault_model::ByzantineFaults, node::Int, round::Int)
    return node in fault_model.byzantine_nodes
end

function is_faulty(fault_model::NetworkPartition, node::Int, round::Int)
    # Partition is not a node-level property
    return false
end

function is_faulty(fault_model::TransientFaults, node::Int, round::Int)
    if round >= fault_model.start_round
        if fault_model.end_round == 0 || round <= fault_model.end_round
            rng = Random.MersenneTwister(fault_model.seed + UInt32(node * 1000 + round))
            return rand(rng) < fault_model.fault_prob
        end
    end
    return false
end

function is_faulty(fault_model::CompositeFaults, node::Int, round::Int)
    return any(m -> is_faulty(m, node, round), fault_model.models)
end

"""
    crashed_nodes(fault_model::FaultModel, n_processes::Int) → Set{Int}

Return set of permanently crashed nodes.
"""
function crashed_nodes(fault_model::NoFaults, n_processes::Int)
    return Set{Int}()
end

function crashed_nodes(fault_model::CrashFaults, n_processes::Int)
    crashed = Set{Int}()
    for node in 1:n_processes
        rng = Random.MersenneTwister(fault_model.seed + UInt32(node))
        if rand(rng) < fault_model.crash_prob
            push!(crashed, node)
        end
    end
    return crashed
end

function crashed_nodes(fault_model::CompositeFaults, n_processes::Int)
    all_crashed = Set{Int}()
    for model in fault_model.models
        union!(all_crashed, crashed_nodes(model, n_processes))
    end
    return all_crashed
end

function crashed_nodes(fault_model::FaultModel, n_processes::Int)
    return Set{Int}()  # Default: no crashes
end

"""
    can_communicate_with_faults(
        fault_model::FaultModel,
        from::Int, to::Int,
        round::Int
    ) → Bool

Check if `from` can send to `to` at `round` given the fault model.
"""
function can_communicate_with_faults(fault_model::NoFaults, from::Int, to::Int, round::Int)
    return true
end

function can_communicate_with_faults(fault_model::CrashFaults, from::Int, to::Int, round::Int)
    # If sender crashed, can't send
    return !is_faulty(fault_model, from, round)
end

function can_communicate_with_faults(fault_model::ByzantineFaults, from::Int, to::Int, round::Int)
    # Byzantine nodes can still send (but will lie)
    return true
end

function can_communicate_with_faults(fault_model::NetworkPartition, from::Int, to::Int, round::Int)
    # Check if partition is active
    if round < fault_model.partition_round
        return true
    end
    if fault_model.partition_duration > 0 &&
       round >= fault_model.partition_round + fault_model.partition_duration
        return true
    end

    # Partition is active - check if from and to are in same group
    for group in fault_model.groups
        if from in group && to in group
            return true
        end
    end
    return false
end

function can_communicate_with_faults(fault_model::CompositeFaults, from::Int, to::Int, round::Int)
    # All models must allow communication
    return all(m -> can_communicate_with_faults(m, from, to, round), fault_model.models)
end

function can_communicate_with_faults(fault_model::FaultModel, from::Int, to::Int, round::Int)
    return true  # Default: no restriction
end

"""
    apply_byzantine_strategy(strategy::Symbol, true_value, node::Int, round::Int) → value

Apply Byzantine strategy to modify the true value.
"""
function apply_byzantine_strategy(strategy::Symbol, true_value::Float64, node::Int, round::Int)
    if strategy == :max_value
        return 1e10  # Very large value
    elseif strategy == :min_value
        return -1e10  # Very small value
    elseif strategy == :random
        rng = Random.MersenneTwister(UInt32(node * 1000 + round))
        return rand(rng) * 100 - 50  # Random in [-50, 50]
    elseif strategy == :opposite
        return -true_value
    elseif strategy == :silent
        return NaN  # Signal to not send
    else
        return true_value
    end
end

end  # module Faults
