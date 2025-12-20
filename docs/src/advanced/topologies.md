# Network Topologies

StochProtocol.jl supports various network topologies to model realistic communication structures in distributed systems.

## Overview

By default, protocols assume a complete graph where all processes can communicate with all others. However, real distributed systems often have restricted communication patterns due to network structure.

The `Topologies` module allows you to specify these constraints.

## Available Topologies

### CompleteGraph

```julia
using StochProtocol

# Default: all processes connected
results = run_protocol(protocol;
    topology = CompleteGraph(),
    n_processes = 10
)
```

All processes can communicate with all others. This is the default if no topology is specified.

### Ring

```julia
# Ring topology: each process talks to neighbors
results = run_protocol(protocol;
    topology = Ring(),
    n_processes = 10
)
```

Each process can only communicate with its two neighbors in a circular arrangement.

**Use case**: Token-ring networks, circular consensus algorithms.

### Star

```julia
# Star topology: hub-and-spoke
results = run_protocol(protocol;
    topology = Star(),
    n_processes = 10
)
```

Process 1 acts as a hub connected to all others. Spoke processes can only communicate with the hub.

**Use case**: Client-server architectures, coordinator-based protocols.

### Grid

```julia
# 2D grid topology
results = run_protocol(protocol;
    topology = Grid(4, 4),  # 4×4 grid, 16 processes total
)
```

Processes arranged in a 2D grid with connections to immediate neighbors (up, down, left, right).

**Use case**: Sensor networks, mesh networks, spatial coordination.

### RandomGraph

```julia
# Erdős-Rényi random graph
results = run_protocol(protocol;
    topology = RandomGraph(0.3),  # Each edge exists with 30% probability
    n_processes = 20
)
```

Each pair of processes has an edge with probability `edge_prob`.

**Use case**: Peer-to-peer networks, random connectivity patterns.

### KRegular

```julia
# k-regular graph: each node has exactly k neighbors
results = run_protocol(protocol;
    topology = KRegular(3),  # Each process has 3 neighbors
    n_processes = 10
)
```

Each process has exactly `k` neighbors.

**Use case**: Structured overlay networks, degree-constrained systems.

### BipartiteGraph

```julia
# Bipartite graph: two disjoint sets
results = run_protocol(protocol;
    topology = BipartiteGraph(5, 5),  # 5 left, 5 right
)
```

Two disjoint groups with connections only between groups, none within.

**Use case**: Two-layer systems, client-server clusters.

### CustomTopology

```julia
# Define custom adjacency matrix
adj = [false true  false;
       true  false true;
       false true  false]

results = run_protocol(protocol;
    topology = CustomTopology(adj),
)
```

Specify exact connectivity using an adjacency matrix.

**Use case**: Specific network structures, hierarchical topologies.

## Topology Analysis

### Query Neighbors

```julia
topo = Ring()
n_processes = 10

# Get neighbors of process 5
nbrs = neighbors(topo, 5, n_processes)
# Returns: [4, 6]
```

### Check Connectivity

```julia
# Can process 2 communicate with process 7?
can_communicate(topo, 2, 7, n_processes)
```

### Compute Diameter

```julia
# Maximum shortest path distance
d = diameter(topo, n_processes)

# For Ring with 10 processes: d = 5
# For CompleteGraph: d = 1
# For Star: d = 2
```

### Visualize Topology

```julia
visualize_topology(Ring(), 5)
```

Prints ASCII representation of the topology structure.

## Example: Comparing Topologies

```julia
using StochProtocol

protocol = Protocol("""
PROTOCOL AveragingProtocol
PROCESSES: 20
STATE: x ∈ ℝ
INITIAL: xᵢ = i
CHANNEL: stochastic

UPDATE RULE:
    EACH ROUND:
        xᵢ ← avg(inbox_with_self)

METRICS:
    discrepancy
""")

# Compare different topologies
topologies = [
    ("Complete", CompleteGraph()),
    ("Ring", Ring()),
    ("Grid 4×5", Grid(4, 5)),
    ("3-Regular", KRegular(3))
]

for (name, topo) in topologies
    results = run_protocol(protocol;
        topology = topo,
        p_values = [0.7],
        rounds = 30,
        repetitions = 1000
    )

    println("$name topology:")
    println("  Diameter: ", diameter(topo, 20))
    results_table(results)
    println()
end
```

## Impact on Convergence

Topology significantly affects convergence speed:

- **Complete graphs**: Fastest convergence (diameter = 1)
- **Ring**: Slowest convergence (diameter = n/2)
- **Grid**: Moderate convergence (diameter = 2√n approximately)
- **Star**: Fast convergence (diameter = 2) but hub bottleneck

The relationship between diameter and convergence is typically:

**Expected rounds ≈ O(diameter / p)**

where `p` is the communication probability.
