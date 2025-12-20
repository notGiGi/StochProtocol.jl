"""
    Topologies

Network topology models for distributed protocols.

This module provides various network topologies that restrict communication patterns
beyond simple stochastic channels. Useful for modeling real-world distributed systems
with specific network structures.

# Available Topologies

- `CompleteGraph()` - All processes can communicate with all others (default)
- `Ring()` - Each process communicates only with neighbors in a ring
- `Star()` - Hub-and-spoke topology with one central coordinator
- `Grid(rows, cols)` - 2D grid topology
- `RandomGraph(edge_prob)` - Erdős-Rényi random graph
- `KRegular(k)` - Each node has exactly k neighbors
- `BipartiteGraph(left_size, right_size)` - Two disjoint sets with cross-edges
- `CustomTopology(adjacency_matrix)` - User-defined topology

# Example

```julia
using StochProtocol

# Run protocol on a ring topology
results = run_protocol(protocol;
    topology = Ring(),
    p_values = 0.0:0.1:1.0,
    repetitions = 1000
)

# Run on 4x4 grid
results = run_protocol(protocol;
    topology = Grid(4, 4),
    rounds = 20
)
```
"""
module Topologies

export Topology,
       CompleteGraph, Ring, Star, Grid,
       RandomGraph, KRegular, BipartiteGraph,
       CustomTopology,
       neighbors, can_communicate, diameter,
       visualize_topology

using Random

"""
    Topology

Abstract type for network topologies. Defines which processes can communicate.
"""
abstract type Topology end

"""
    CompleteGraph()

Complete graph topology - all processes can communicate with all others.
This is the default topology if none is specified.
"""
struct CompleteGraph <: Topology end

"""
    Ring()

Ring topology - process i can communicate with i-1 and i+1 (modulo n).
Models token-ring networks and circular communication patterns.
"""
struct Ring <: Topology end

"""
    Star()

Star topology - process 1 is the hub, all others are spokes.
Hub can communicate with everyone, spokes only with hub.
Models client-server or coordinator-based architectures.
"""
struct Star <: Topology end

"""
    Grid(rows::Int, cols::Int)

2D grid topology. Processes arranged in rows×cols grid with
connections to immediate neighbors (up, down, left, right).

# Example
```julia
Grid(4, 4)  # 4×4 grid with 16 processes
```
"""
struct Grid <: Topology
    rows::Int
    cols::Int

    function Grid(rows::Int, cols::Int)
        rows > 0 || error("Grid rows must be positive")
        cols > 0 || error("Grid cols must be positive")
        new(rows, cols)
    end
end

"""
    RandomGraph(edge_prob::Float64)

Erdős-Rényi random graph. Each pair of processes has an edge
with probability `edge_prob`.

# Example
```julia
RandomGraph(0.3)  # Each edge exists with 30% probability
```
"""
struct RandomGraph <: Topology
    edge_prob::Float64
    seed::UInt32

    function RandomGraph(edge_prob::Float64; seed::UInt32=UInt32(0))
        0.0 <= edge_prob <= 1.0 || error("edge_prob must be in [0,1]")
        new(edge_prob, seed)
    end
end

"""
    KRegular(k::Int)

k-regular graph - each process has exactly k neighbors.
Note: May not be possible for all (n, k) combinations.

# Example
```julia
KRegular(3)  # Each process has exactly 3 neighbors
```
"""
struct KRegular <: Topology
    k::Int
    seed::UInt32

    function KRegular(k::Int; seed::UInt32=UInt32(0))
        k >= 0 || error("k must be non-negative")
        new(k, seed)
    end
end

"""
    BipartiteGraph(left_size::Int, right_size::Int)

Complete bipartite graph with `left_size` nodes on left,
`right_size` on right. All edges go between sides, none within.

Models two-layer systems or client-server architectures.
"""
struct BipartiteGraph <: Topology
    left_size::Int
    right_size::Int

    function BipartiteGraph(left_size::Int, right_size::Int)
        left_size > 0 || error("left_size must be positive")
        right_size > 0 || error("right_size must be positive")
        new(left_size, right_size)
    end
end

"""
    CustomTopology(adjacency::Matrix{Bool})

User-defined topology specified by adjacency matrix.
`adjacency[i,j] = true` means process i can send to process j.

# Example
```julia
adj = [false true  false;
       true  false true;
       false true  false]
CustomTopology(adj)  # Linear chain: 1 → 2 → 3
```
"""
struct CustomTopology <: Topology
    adjacency::Matrix{Bool}

    function CustomTopology(adjacency::Matrix{Bool})
        n, m = size(adjacency)
        n == m || error("Adjacency matrix must be square")
        new(adjacency)
    end
end

# ============================================================================
# Topology Query Functions
# ============================================================================

"""
    neighbors(topo::Topology, node::Int, n_processes::Int) → Vector{Int}

Return list of neighbors for given node in the topology.
"""
function neighbors(topo::CompleteGraph, node::Int, n_processes::Int)
    return [i for i in 1:n_processes if i != node]
end

function neighbors(topo::Ring, node::Int, n_processes::Int)
    prev = node == 1 ? n_processes : node - 1
    next = node == n_processes ? 1 : node + 1
    return [prev, next]
end

function neighbors(topo::Star, node::Int, n_processes::Int)
    if node == 1  # Hub
        return [i for i in 2:n_processes]
    else  # Spoke
        return [1]
    end
end

function neighbors(topo::Grid, node::Int, n_processes::Int)
    rows, cols = topo.rows, topo.cols
    n_processes == rows * cols || error("Grid size doesn't match n_processes")

    row = (node - 1) ÷ cols + 1
    col = (node - 1) % cols + 1

    nbrs = Int[]

    # Up
    if row > 1
        push!(nbrs, (row - 2) * cols + col)
    end
    # Down
    if row < rows
        push!(nbrs, row * cols + col)
    end
    # Left
    if col > 1
        push!(nbrs, (row - 1) * cols + col - 1)
    end
    # Right
    if col < cols
        push!(nbrs, (row - 1) * cols + col + 1)
    end

    return nbrs
end

function neighbors(topo::RandomGraph, node::Int, n_processes::Int)
    # Generate deterministic neighbors based on seed
    rng = Random.MersenneTwister(topo.seed + node)
    nbrs = Int[]
    for i in 1:n_processes
        if i != node && rand(rng) < topo.edge_prob
            push!(nbrs, i)
        end
    end
    return nbrs
end

function neighbors(topo::KRegular, node::Int, n_processes::Int)
    # Simple k-regular construction: connect to k nearest nodes
    k = topo.k
    k < n_processes || error("k must be less than n_processes")

    if k == 0
        return Int[]
    end

    # Connect to k/2 nodes on each side (circular)
    nbrs = Int[]
    for offset in 1:(k÷2 + k%2)
        left = mod1(node - offset, n_processes)
        push!(nbrs, left)
        if length(nbrs) < k
            right = mod1(node + offset, n_processes)
            push!(nbrs, right)
        end
    end

    return unique(nbrs)[1:min(k, length(unique(nbrs)))]
end

function neighbors(topo::BipartiteGraph, node::Int, n_processes::Int)
    left_size = topo.left_size
    right_size = topo.right_size
    n_processes == left_size + right_size || error("BipartiteGraph size mismatch")

    if node <= left_size  # Left partition
        return [(left_size + 1):(left_size + right_size)...]
    else  # Right partition
        return [1:left_size...]
    end
end

function neighbors(topo::CustomTopology, node::Int, n_processes::Int)
    n = size(topo.adjacency, 1)
    n == n_processes || error("Adjacency matrix size doesn't match n_processes")

    return [i for i in 1:n_processes if topo.adjacency[node, i]]
end

"""
    can_communicate(topo::Topology, from::Int, to::Int, n_processes::Int) → Bool

Check if process `from` can send messages to process `to`.
"""
function can_communicate(topo::Topology, from::Int, to::Int, n_processes::Int)
    return to in neighbors(topo, from, n_processes)
end

"""
    diameter(topo::Topology, n_processes::Int) → Int

Compute the diameter of the topology (longest shortest path).
Returns -1 if graph is disconnected.
"""
function diameter(topo::CompleteGraph, n_processes::Int)
    return 1  # Everyone connected to everyone
end

function diameter(topo::Ring, n_processes::Int)
    return n_processes ÷ 2
end

function diameter(topo::Star, n_processes::Int)
    return 2  # Spoke → Hub → Spoke
end

function diameter(topo::Grid, n_processes::Int)
    return (topo.rows - 1) + (topo.cols - 1)  # Manhattan distance
end

function diameter(topo::Topology, n_processes::Int)
    # Generic BFS-based diameter computation
    max_dist = 0

    for start in 1:n_processes
        # BFS from start
        visited = Set{Int}([start])
        queue = [(start, 0)]
        local_max = 0

        while !isempty(queue)
            node, dist = popfirst!(queue)
            local_max = max(local_max, dist)

            for neighbor in neighbors(topo, node, n_processes)
                if !(neighbor in visited)
                    push!(visited, neighbor)
                    push!(queue, (neighbor, dist + 1))
                end
            end
        end

        # Check if disconnected
        if length(visited) < n_processes
            return -1  # Disconnected
        end

        max_dist = max(max_dist, local_max)
    end

    return max_dist
end

"""
    visualize_topology(topo::Topology, n_processes::Int)

Print ASCII visualization of the topology structure.
"""
function visualize_topology(topo::CompleteGraph, n_processes::Int)
    println("Complete Graph (K_$n_processes)")
    println("All $n_processes processes fully connected")
end

function visualize_topology(topo::Ring, n_processes::Int)
    println("Ring Topology")
    println(join(["P$i" for i in 1:n_processes], " → ") * " → P1")
end

function visualize_topology(topo::Star, n_processes::Int)
    println("Star Topology")
    println("       P1 (hub)")
    for i in 2:n_processes
        println("        ↓")
        println("       P$i")
    end
end

function visualize_topology(topo::Grid, n_processes::Int)
    println("Grid Topology ($(topo.rows)×$(topo.cols))")
    for row in 1:topo.rows
        for col in 1:topo.cols
            node = (row - 1) * topo.cols + col
            print("P$(lpad(node, 2)) ")
        end
        println()
    end
end

function visualize_topology(topo::CustomTopology, n_processes::Int)
    println("Custom Topology")
    println("Adjacency Matrix:")
    for i in 1:n_processes
        for j in 1:n_processes
            print(topo.adjacency[i, j] ? "1 " : "0 ")
        end
        println()
    end
end

function visualize_topology(topo::Topology, n_processes::Int)
    println("$(typeof(topo)) Topology")
    println("Neighbors:")
    for node in 1:n_processes
        nbrs = neighbors(topo, node, n_processes)
        println("  P$node → ", join(["P$n" for n in nbrs], ", "))
    end
end

end  # module Topologies
