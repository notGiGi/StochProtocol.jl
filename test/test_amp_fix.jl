using Test
using StochProtocol
using StochProtocol.DSL.Parser: parse_indexed_lhs
using StochProtocol.Explore.Run: run_protocol

@testset "Indexed LHS parsing" begin
    lhs1 = parse_indexed_lhs("xᵢ", 1)
    lhs2 = parse_indexed_lhs("x_i", 1)
    lhs3 = parse_indexed_lhs("x[i]", 1)
    @test lhs1.name == :x && lhs1.index == :self
    @test lhs2.name == :x && lhs2.index == :self
    @test lhs3.name == :x && lhs3.index == :self
end

@testset "AMP consensus smoke" begin
    proto = """
    PROTOCOL AMP
    PROCESSES: 2
    STATE:
        x ∈ {0,1}

    INITIAL VALUES:
        [0, 1]

    PARAMETERS:
        y ∈ [0,1] = 0.5

    CHANNEL:
        stochastic

    UPDATE RULE:
        if received_diff(x) then
            xᵢ ← y
        else
            xᵢ ← xᵢ
        end

    METRICS:
        discrepancy
        consensus
    """
    res = run_protocol(proto; p_values=[1.0], rounds=1, repetitions=2000, seed=1)
    @test res[1].mean_discrepancy < 0.05
    @test res[1].consensus_probability > 0.95
end
