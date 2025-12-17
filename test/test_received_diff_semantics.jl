using Test
using StochProtocol
using StochProtocol.DSL.IR: ReceivedDiffIR
using StochProtocol.DSL.Compiler: evaluate_predicate

@testset "received_diff predicate semantics" begin
    # New signature: evaluate_predicate(pred, inbox_values, diff_values, num_nodes, leader_id, node_id, params, x_self)
    # Test with snapshot provided in params
    snapshot = Dict(:x => [0.0, 1.0])
    params_with_snapshot = Dict{Symbol,Any}(:state_snapshot => snapshot)

    # Node 1 (x=0.0) receives [1.0] - should detect difference
    @test evaluate_predicate(ReceivedDiffIR(:x), Float64[1.0], Float64[1.0], 2, nothing, 1, params_with_snapshot, 0.0) == true

    # Node 1 (x=0.0) receives [0.0] - no difference
    @test evaluate_predicate(ReceivedDiffIR(:x), Float64[0.0], Float64[], 2, nothing, 1, params_with_snapshot, 0.0) == false

    # Node 1 (x=0.0) receives nothing - no difference
    @test evaluate_predicate(ReceivedDiffIR(:x), Float64[], Float64[], 2, nothing, 1, params_with_snapshot, 0.0) == false
end
