using Test
using StochProtocol
using StochProtocol.DSL.IR: ProtocolIR, UpdatePhaseIR, ConditionalIR, ReceivedAny, SimpleOpIR
using StochProtocol.DSL.Compiler: compile
using StochProtocol.Experiments: run_experiment

@testset "Inbox predicates and leader role" begin
    ir = ProtocolIR(
        "PredTest",
        3,
        i -> Float64(i),
        nothing,
        [UpdatePhaseIR(:each_round, false, ConditionalIR(ReceivedAny(), SimpleOpIR(:min)), nothing)],
        [:discrepancy],
        Dict(:leader_id => 1, :channel_guarantee => :none)
    )
    spec = compile(ir; p=1.0, rounds=1)
    res = run_experiment(spec; consensus_eps=1e-6)
    @test length(res.discrepancy_by_round) >= 2
end

@testset "Channel guarantees" begin
    ir = ProtocolIR(
        "GuaranteeTest",
        3,
        i -> Float64(i),
        nothing,
        [UpdatePhaseIR(:each_round, false, SimpleOpIR(:min), nothing)],
        [:discrepancy],
        Dict(:channel_guarantee => :at_least_one)
    )
    spec = compile(ir; p=0.0, rounds=1)
    res = run_experiment(spec; consensus_eps=1e-6)
    @test length(res.discrepancy_by_round) >= 2
end

@testset "Temporal phases" begin
    ir = ProtocolIR(
        "TemporalTest",
        3,
        i -> Float64(i),
        nothing,
        [UpdatePhaseIR(:first_round, false, SimpleOpIR(:min), nothing),
         UpdatePhaseIR(:after_rounds, false, SimpleOpIR(:max), 1)],
        [:discrepancy],
        Dict(:channel_guarantee => :none)
    )
    spec = compile(ir; p=1.0, rounds=2)
    res = run_experiment(spec; consensus_eps=1e-6)
    @test length(res.discrepancy_by_round) >= 3
end
