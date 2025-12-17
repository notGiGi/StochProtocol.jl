using Test
using StochProtocol
using StochProtocol.Explore.Errors: ExploreError

const SIMPLE_PROTO = """
PROTOCOL Simple

PROCESSES: 2

STATE:
    x ∈ ℝ

INITIAL VALUES:
    [0,1]

CHANNEL:
    stochastic

UPDATE RULE:
    EACH ROUND:
        xᵢ ← self

METRICS:
    discrepancy
    consensus
"""

@testset "protocol macro runs" begin
    res = StochProtocol.Explore.Run.run(SIMPLE_PROTO; quiet=true)
    @test length(res) > 0
end

@testset "run_protocol accepts text" begin
    res = run_protocol(SIMPLE_PROTO; repetitions=2, rounds=1, p_values=0:1)
    @test length(res) == 2
end

@testset "compare accepts macro results" begin
    resA = StochProtocol.Explore.Run.run(SIMPLE_PROTO; quiet=true)
    resB = StochProtocol.Explore.Run.run(SIMPLE_PROTO; quiet=true)
    comp = compare(resA, resB; p_values=0:1, rounds=1, repetitions=2) do
        """
        for p > -1:
            AMP.consensus >= FV.consensus
        """
    end
    @test comp.success
end

@testset "show is human friendly" begin
    res = run_protocol(SIMPLE_PROTO; repetitions=1, rounds=1, p_values=0:1)
    s = sprint(show, MIME("text/plain"), res)
    @test !occursin("ExploreRun(", s)
end

@testset "invalid protocol raises ExploreError" begin
    bad = """
    PROTOCOL Broken
    STATE:
        x ∈ ℝ
    METRICS:
        discrepancy
    """
    @test_throws ExploreError run_protocol(bad; repetitions=1)
end
