# Protocol DSL Reference

*Complete reference for the StochProtocol protocol specification language*

---

## Overview

The Protocol DSL lets you define distributed consensus protocols using **mathematical notation** that mirrors research papers.

```@raw html
<div class="admonition is-info">
    <div class="admonition-header">✨ Design Philosophy</div>
    <p><strong>No boilerplate code—just the essential protocol logic.</strong> Write protocols the way you think about them, using the same notation you'd use in a paper.</p>
</div>
```

### Basic Structure

```julia
PROTOCOL <Name>                      # Protocol identifier
PROCESSES: <N>                       # Number of processes
STATE: <variable> ∈ <domain>         # State variable and domain
INITIAL VALUES: [v1, v2, ..., vN]    # Explicit initial values
  # OR
INITIAL: <expression>                # Formula-based initialization

PARAMETERS: <params>                 # Optional parameters
CHANNEL: stochastic                  # Channel type
MODEL: <delivery_model>              # Optional delivery model

UPDATE RULE:
    <phase>:                         # When to execute
        <rule>                       # How to update state

METRICS: <metric1>, <metric2>        # What to measure
```

```@raw html
<div class="admonition is-success">
    <div class="admonition-header">💡 Quick Tip</div>
    <p>Start with the simplest possible protocol, then add complexity incrementally. Every section except PARAMETERS and MODEL is required.</p>
</div>
```

---

## Sections

### PROTOCOL

```
PROTOCOL <ProtocolName>
```

**Required**. Defines the protocol name.

**Example:**
```
PROTOCOL AMP
PROTOCOL SimpleAveraging
PROTOCOL FV_Protocol
```

---

### PROCESSES

```
PROCESSES: <N>
```

**Required**. Specifies the number of processes in the system.

**Example:**
```
PROCESSES: 2
PROCESSES: 10
PROCESSES: 100
```

---

### STATE

```
STATE:
    <variable> ∈ <domain>
```

**Required**. Declares the state variable and its domain.

**Supported Domains:**
- `{0,1}` - Binary values
- `ℝ` or `R` - Real numbers
- `[a,b]` - Interval (parsed as real)

**Example:**
```
STATE:
    x ∈ {0,1}

STATE:
    x ∈ ℝ

STATE:
    value ∈ [0,1]
```

---

### INITIAL VALUES / INITIAL

Two ways to initialize state:

#### Option 1: Explicit Values

```
INITIAL VALUES:
    [v1, v2, ..., vN]
```

Provide explicit initial values for each process.

**Example:**
```
INITIAL VALUES:
    [0.0, 1.0]          # 2 processes

INITIAL VALUES:
    [0.0, 0.5, 1.0]     # 3 processes
```

#### Option 2: Formula

```
INITIAL:
    xᵢ = <expression in i>
```

Use a formula where `i` is the process ID (1-indexed).

**Example:**
```
INITIAL:
    xᵢ = i              # Process i starts with value i

INITIAL:
    xᵢ = i / N          # Normalized by number of processes

INITIAL:
    xᵢ = (i - 1) * 0.1  # 0.0, 0.1, 0.2, ...
```

---

### PARAMETERS

```
PARAMETERS:
    <param> ∈ <domain> = <default>
```

**Optional**. Define protocol parameters (e.g., meeting points).

**Example:**
```
PARAMETERS:
    y ∈ [0,1] = 0.5

PARAMETERS:
    alpha = 0.3
    beta ∈ ℝ = 1.0
```

Access parameters in update rules:
```
UPDATE RULE:
    EACH ROUND:
        xᵢ ← y          # Use parameter y
```

---

### CHANNEL

```
CHANNEL:
    stochastic
```

**Required**. Currently only `stochastic` (Bernoulli) channels are supported.

---

### MODEL

```
MODEL:
    <model_specification>
```

**Optional**. Specifies the message delivery model. Defaults to `standard` if omitted.

#### Standard Model (Default)

```
MODEL:
    standard
```

Independent probabilistic delivery for each message.

#### Guaranteed Model

```
MODEL:
    guaranteed k=<N> scope=<per_round|total>
```

Ensures minimum `k` messages delivered.

**Parameters:**
- `k`: Minimum messages required
- `scope`:
  - `per_round`: Guarantee applies each round
  - `total`: Guarantee applies to sum across all rounds

**Example:**
```
MODEL:
    guaranteed k=3 scope=per_round
```

Filters out simulation runs where any round has < 3 messages delivered.

#### Broadcast Model

```
MODEL:
    broadcast probability=<per_source|uniform>
```

All-or-nothing delivery per source process.

**Example:**
```
MODEL:
    broadcast probability=per_source
```

#### Process-Specific Models

```
MODEL:
    process <id>: <model_spec>
    process <id>: <model_spec>
    ...
```

Assign different models to different processes.

**Example:**
```
MODEL:
    process 1: standard
    process 2: broadcast
    process 3: guaranteed k=2 scope=per_round
```

See [Delivery Models Guide](delivery_models.md) for details.

---

### UPDATE RULE

```
UPDATE RULE:
    <PHASE>:
        <rule>
```

**Required**. Defines how processes update their state.

#### Phases

- `EACH ROUND` - Execute every round
- `END` - Execute once after all rounds
- `FIRST ROUND` - Execute only in round 1
- `AFTER ROUNDS <k>` - Execute starting from round k+1
- `UNTIL CONSENSUS` - Execute until consensus is reached

**Example:**
```
UPDATE RULE:
    EACH ROUND:
        xᵢ ← avg(inbox_with_self)

    END:
        xᵢ ← min(inbox_with_self)
```

#### Update Rules

**Simple Assignment:**
```
xᵢ ← <expression>
```

**Conditional:**
```
if <condition> then
    xᵢ ← <expr1>
else
    xᵢ ← <expr2>
end
```

**Conditions:**
- `received_diff` - Inbox contains value different from own
- `received_any` - Inbox is not empty
- `received_all` - Received message from all other processes
- `received_at_least(k)` - Received at least k messages
- `received_majority` - Received from majority

**Arithmetic:**
```
xᵢ ← x + 1
xᵢ ← x * 2 + y
xᵢ ← (x + sum(inbox)) / 2
```

**Aggregations:**
- `avg(inbox)` - Average of received values
- `avg(inbox_with_self)` - Average including own value
- `sum(inbox)` - Sum of received values
- `min(inbox)` - Minimum of received values
- `max(inbox)` - Maximum of received values
- `count(inbox)` - Number of messages received

**Special Values:**
- `x` or `self` - Own current value
- `y` - Parameter (if defined)
- `received_other_value` - A different value from inbox (for FV-like protocols)

**Example:**
```
UPDATE RULE:
    EACH ROUND:
        if received_diff then
            xᵢ ← y
        else
            xᵢ ← x
        end
```

---

### METRICS

```
METRICS:
    <metric1>
    <metric2>
```

**Optional**. Defaults to `discrepancy` and `consensus` if omitted.

**Supported Metrics:**
- `discrepancy` - max(x) - min(x)
- `consensus` - Whether all processes agree (within ε)

**Example:**
```
METRICS:
    discrepancy
    consensus
```

---

## Complete Examples

### Example 1: AMP Protocol

```julia
Protocol("""
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
```

### Example 2: Simple Averaging

```julia
Protocol("""
PROTOCOL Averaging
PROCESSES: 10
STATE:
    x ∈ ℝ
INITIAL:
    xᵢ = i
CHANNEL:
    stochastic

UPDATE RULE:
    EACH ROUND:
        xᵢ ← avg(inbox_with_self)

METRICS:
    discrepancy
    consensus
""")
```

### Example 3: Minimum with Broadcast

```julia
Protocol("""
PROTOCOL MinProtocol
PROCESSES: 5
STATE:
    x ∈ ℝ
INITIAL VALUES:
    [5.0, 3.0, 8.0, 1.0, 6.0]
CHANNEL:
    stochastic

MODEL:
    broadcast probability=per_source

UPDATE RULE:
    EACH ROUND:
        if received_any then
            xᵢ ← min(inbox_with_self)
        else
            xᵢ ← x
        end

METRICS:
    discrepancy
    consensus
""")
```

---

## Advanced Features

### Complex Expressions

```julia
UPDATE RULE:
    EACH ROUND:
        xᵢ ← (x + avg(inbox)) / 2
```

### Multiple Conditions

```julia
UPDATE RULE:
    EACH ROUND:
        if received_majority then
            xᵢ ← avg(inbox_with_self)
        else
            xᵢ ← x
        end
```

### Multi-Phase Updates

```julia
UPDATE RULE:
    EACH ROUND:
        xᵢ ← avg(inbox_with_self)

    END:
        xᵢ ← min(inbox_with_self)
```

---

## Tips & Best Practices

1. **Start Simple**: Begin with basic protocols before adding complexity
2. **Test Small**: Use `PROCESSES: 2` or `3` for initial testing
3. **Use Parameters**: Make protocols configurable with `PARAMETERS`
4. **Descriptive Names**: Use clear protocol names
5. **Comments**: While not officially supported, keep protocol definitions well-structured

---

## See Also

- [Quick Start](../quickstart.md) - Get started quickly
- [Delivery Models](delivery_models.md) - Communication models
- [Examples](../examples/overview.md) - Real-world protocols
- [API Reference](../api/core.md) - Function documentation
