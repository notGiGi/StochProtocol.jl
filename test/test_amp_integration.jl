using Test
using StochProtocol
using StochProtocol.Explore.Run: run_protocol

@testset "AMP integration p=1" begin
    proto = """
    PROTOCOL AMP
    PROCESSES: 2
    STATE:
        x ∈ {0,1}

    INITIAL VALUES:
        [0, 1]

    PARAMETERS:
        y ∈ [0,1] = 0.0

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
    res = run_protocol(proto; p_values=[1.0], rounds=1, repetitions=1000, seed=1)
    @test res[1].mean_discrepancy < 0.01
    @test res[1].consensus_probability > 0.99
end
