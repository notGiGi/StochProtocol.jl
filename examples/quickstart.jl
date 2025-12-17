#=
Quickstart script (run with `julia --project examples/quickstart.jl`).
If running from elsewhere, activate the project explicitly:
# using Pkg; Pkg.activate(joinpath(@__DIR__, ".."))
=#

using StochProtocol
using StochProtocol.Core: Inbox, Message
import StochProtocol.Core: apply_protocol
using StochProtocol.Protocols: Protocol, ProtocolInstance
using StochProtocol.Channels: BernoulliChannel
using StochProtocol.Experiments: ExperimentSpec, SweepPSpec, run_sweep_p
using Printf

"""
Toy averaging protocol: each node updates `:x` to the average of its own value
and any numeric payloads received. It then broadcasts its value to all peers.
"""
struct AveragingProtocol <: Protocol
end

function apply_protocol(state::Dict{Symbol,Any}, inbox::Inbox, params::Dict{Symbol,Any})
    haskey(state, :x) || error("AveragingProtocol expects state[:x]")
    haskey(state, :id) || error("AveragingProtocol expects state[:id]")
    x_self = Float64(state[:x])
    node_id = Int(state[:id])
    received = [Float64(m.payload) for m in inbox if m.payload isa Number]
    new_x = isempty(received) ? x_self : (x_self + sum(received)) / (length(received) + 1)
    num_nodes = get(params, :num_nodes, 0)
    outbound = Message[]
    for target in 1:num_nodes
        target == node_id && continue
        push!(outbound, Message(node_id, target, new_x))
    end
    return Dict(:id => node_id, :x => new_x), outbound
end

# Base experiment parameters.
num_nodes = 7
num_rounds = 10
p_values = collect(0.0:0.1:1.0)
repetitions = 200
seed = 1234
consensus_eps = 1e-6  # Consensus threshold; adjust if needed (e.g., 1e-4).
# Example: run_protocol(...; consensus_eps=1e-4)

protocol = AveragingProtocol()
params = Dict{Symbol,Any}(:num_nodes => num_nodes)
protocol_instance = ProtocolInstance(protocol, params)
channel = BernoulliChannel(0.5)  # Placeholder; overwritten during sweep.
init_state(i) = Dict(:id => i, :x => Float64(i - 1))
base_experiment = ExperimentSpec(num_nodes, num_rounds, channel, protocol_instance, init_state)

sweep_spec = SweepPSpec(base_experiment, p_values, repetitions, seed)
results = run_sweep_p(sweep_spec; consensus_eps=consensus_eps)

println("Consensus threshold eps = $(consensus_eps)")
println("p\tmean_discrepancy\tconsensus_probability")
for r in results
    @printf("%.2f\t%.4f\t%.3f\n", r.p, r.mean_discrepancy, r.consensus_probability)
end
