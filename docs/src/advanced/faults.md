# Fault Models

Test protocol robustness under failures and adversarial conditions.

## Overview

Real distributed systems face failures: processes crash, messages get corrupted, networks partition, and malicious actors may exist. The `Faults` module lets you simulate these scenarios to test protocol resilience.

## Available Fault Models

### NoFaults (Default)

```julia
using StochProtocol

# No faults - all processes behave correctly
results = run_protocol(protocol;
    fault_model = NoFaults()
)
```

### CrashFaults

Processes crash and stop sending messages permanently.

```julia
# 30% of processes crash at round 5
results = run_protocol(protocol;
    fault_model = CrashFaults(
        crash_prob = 0.3,
        crash_round = 5
    ),
    rounds = 20,
    repetitions = 1000
)
```

**Parameters:**
- `crash_prob`: Probability each process crashes (0.0 to 1.0)
- `crash_round`: Round at which crashes occur
- `seed`: Random seed for reproducibility

**Use case**: Server failures, node crashes, power outages.

### ByzantineFaults

Malicious processes that send incorrect or adversarial values.

```julia
# Processes 1 and 2 are Byzantine
results = run_protocol(protocol;
    fault_model = ByzantineFaults(
        byzantine_nodes = [1, 2],
        strategy = :max_value
    ),
    rounds = 20
)
```

**Strategies:**
- `:max_value` - Always send maximum possible value
- `:min_value` - Always send minimum possible value
- `:random` - Send random values
- `:opposite` - Send negated values
- `:silent` - Don't send any messages
- `:lie_to_half` - Send correct to half, lies to other half

**Use case**: Security attacks, malicious nodes, Byzantine consensus.

### NetworkPartition

Network splits into disconnected groups.

```julia
# Split network at round 5 for 3 rounds
results = run_protocol(protocol;
    fault_model = NetworkPartition(
        partition_round = 5,
        partition_duration = 3,
        groups = [[1,2,3], [4,5,6]]
    ),
    rounds = 20
)
```

**Parameters:**
- `partition_round`: When partition begins
- `partition_duration`: How many rounds it lasts (0 = permanent)
- `groups`: Vector of node groups (processes in different groups can't communicate)

**Use case**: Network failures, data center outages, split-brain scenarios.

### MessageCorruption

Messages get corrupted with given probability.

```julia
# 10% of messages get corrupted
results = run_protocol(protocol;
    fault_model = MessageCorruption(
        corruption_prob = 0.1,
        corruption_type = :random
    ),
    rounds = 20
)
```

**Corruption types:**
- `:random` - Replace with random value
- `:zero` - Replace with zero
- `:max` - Replace with very large value
- `:flip_bits` - Flip bits (for binary values)

**Use case**: Noisy channels, bit errors, data corruption.

### DelayFaults

Messages delayed by multiple rounds.

```julia
# 20% of messages delayed up to 3 rounds
results = run_protocol(protocol;
    fault_model = DelayFaults(
        delay_prob = 0.2,
        max_delay = 3
    ),
    rounds = 30
)
```

**Use case**: High latency networks, congestion, buffering.

### TransientFaults

Random faults occurring during a time window.

```julia
# Transient faults between rounds 5-15
results = run_protocol(protocol;
    fault_model = TransientFaults(
        fault_prob = 0.05,
        start_round = 5,
        end_round = 15,
        fault_type = :send_wrong
    ),
    rounds = 30
)
```

**Fault types:**
- `:send_wrong` - Send incorrect value
- `:skip_update` - Don't update state
- `:corrupt_state` - Corrupt internal state

**Use case**: Temporary glitches, intermittent failures.

### CompositeFaults

Combine multiple fault models.

```julia
# Multiple faults simultaneously
results = run_protocol(protocol;
    fault_model = CompositeFaults([
        CrashFaults(crash_prob=0.1, crash_round=5),
        MessageCorruption(corruption_prob=0.05),
        NetworkPartition(
            partition_round=10,
            partition_duration=2,
            groups=[[1,2,3], [4,5,6]]
        )
    ]),
    rounds = 30
)
```

**Use case**: Realistic scenarios with multiple failure types.

## Example: Byzantine Tolerance

Test if a protocol can tolerate Byzantine faults:

```julia
using StochProtocol

protocol = Protocol("""
PROTOCOL ByzantineRobustProtocol
PROCESSES: 7
STATE: x ∈ ℝ
INITIAL: xᵢ = i
CHANNEL: stochastic

UPDATE RULE:
    EACH ROUND:
        # Use median instead of average for Byzantine tolerance
        xᵢ ← median(inbox_with_self)

METRICS:
    discrepancy
    consensus
""")

# Test with 2 Byzantine nodes (< n/3)
results = run_protocol(protocol;
    fault_model = ByzantineFaults(
        byzantine_nodes = [1, 2],
        strategy = :max_value
    ),
    p_values = [1.0],
    rounds = 20,
    repetitions = 500
)

results_table(results)

# Compare: can tolerate f < n/3 Byzantine nodes
# 7 processes → can tolerate 2 Byzantine nodes
# If 3+ are Byzantine, consensus may fail
```

## Example: Network Resilience

Test recovery from network partition:

```julia
# Temporary partition then recovery
results = run_protocol(protocol;
    fault_model = NetworkPartition(
        partition_round = 5,
        partition_duration = 5,  # Partition for 5 rounds
        groups = [[1,2,3,4], [5,6,7,8]]
    ),
    rounds = 30,
    repetitions = 1000
)

# Analyze: does protocol recover after partition heals?
plot_discrepancy_vs_p(results)
```

## Fault Checking Functions

### Check if Node is Faulty

```julia
fault_model = CrashFaults(crash_prob=0.3, crash_round=5)

# Is process 2 faulty at round 10?
is_faulty(fault_model, 2, 10)
```

### Get Crashed Nodes

```julia
# Which nodes crashed?
crashed = crashed_nodes(fault_model, 10)  # 10 total processes
```

## Best Practices

1. **Start Simple**: Test with `NoFaults` first, then add faults
2. **Byzantine Tolerance**: Use median/voting instead of average with Byzantine faults
3. **Network Partitions**: Test both during partition and after recovery
4. **Realistic Scenarios**: Use `CompositeFaults` for real-world modeling
5. **High Repetitions**: Faults add randomness - use more repetitions (1000+)

## Theoretical Bounds

Common fault tolerance results:

- **Crash failures**: Can tolerate up to f < n crashes with 2f+1 processes
- **Byzantine failures**: Requires n ≥ 3f+1 for consensus
- **Partitions**: Need majority quorum (> n/2) to make progress
