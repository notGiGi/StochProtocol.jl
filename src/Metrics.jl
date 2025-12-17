module Metrics

using ..Core: NodeId, node_value

"""
Tipo abstracto para métricas que midan propiedades del protocolo.
"""
abstract type Metric end

# Default consensus tolerance. Consensus is defined as discrepancy <= eps.
const DEFAULT_CONSENSUS_EPS = 1e-6

"""
Compute discrepancy D = max(x_i) - min(x_i) from a dictionary of local states.
"""
function discrepancy_from_locals(local_states::Dict{NodeId,Any})::Float64
    isempty(local_states) && error("Cannot compute discrepancy on an empty set of local states")
    values_float = map(node_value, values(local_states))
    return maximum(values_float) - minimum(values_float)
end

"""
Return true if nodes are in consensus, i.e. discrepancy is zero within tolerance.
"""
function consensus_from_locals(local_states::Dict{NodeId,Any}; eps::Float64=DEFAULT_CONSENSUS_EPS)::Bool
    discrepancy = discrepancy_from_locals(local_states)
    return discrepancy <= eps
end

"""
Summary of a single run, keeping final discrepancy, consensus flag, and the
discrepancy observed at each round (including the initial state at round 0).
"""
struct RunSummary
    discrepancy_final::Float64
    consensus_final::Bool
    discrepancy_by_round::Vector{Float64}
end

end
