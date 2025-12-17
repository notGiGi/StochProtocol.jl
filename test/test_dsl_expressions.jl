using Test
using StochProtocol
using StochProtocol.Explore.Run: run_protocol

@testset "DSL Extended Expressions" begin
    @testset "Arithmetic Operations - Addition" begin
        proto_add = """
        PROTOCOL ArithmeticAdd
        PROCESSES: 3
        STATE:
            x ∈ ℝ
        INITIAL VALUES:
            [1.0, 2.0, 3.0]
        CHANNEL:
            stochastic

        UPDATE RULE:
            EACH ROUND:
                xᵢ ← xᵢ + 1

        METRICS:
            discrepancy
        """

        res = run_protocol(proto_add; p_values=[1.0], rounds=1, repetitions=1, seed=1)
        # After 1 round with p=1.0, each node should have added 1: [2.0, 3.0, 4.0]
        # Max discrepancy = 4.0 - 2.0 = 2.0
        @test res[1].mean_discrepancy ≈ 2.0
    end

    @testset "Aggregation - Average All" begin
        proto_avg = """
        PROTOCOL AggregateAvg
        PROCESSES: 3
        STATE:
            x ∈ ℝ
        INITIAL VALUES:
            [0.0, 3.0, 6.0]
        CHANNEL:
            stochastic

        UPDATE RULE:
            EACH ROUND:
                xᵢ ← avg(all)

        METRICS:
            consensus
            discrepancy
        """

        res_avg = run_protocol(proto_avg; p_values=[1.0], rounds=1, repetitions=1, seed=1)
        # avg(all) = (0 + 3 + 6) / 3 = 3.0 for all nodes
        @test res_avg[1].consensus_probability ≈ 1.0
        @test res_avg[1].mean_discrepancy < 0.01
    end

    @testset "Comparison - Greater Than" begin
        proto_gt = """
        PROTOCOL ComparisonGT
        PROCESSES: 2
        STATE:
            x ∈ ℝ
        INITIAL VALUES:
            [1.0, 5.0]
        CHANNEL:
            stochastic

        UPDATE RULE:
            EACH ROUND:
                if max(inbox) > 3 then
                    xᵢ ← max(inbox)
                else
                    xᵢ ← xᵢ
                end

        METRICS:
            consensus
        """

        res_gt = run_protocol(proto_gt; p_values=[1.0], rounds=1, repetitions=1, seed=1)
        # Node 1 receives [5.0], max > 3, so updates to 5.0
        # Node 2 receives [1.0], max = 1 < 3, stays at 5.0
        # Both converge to 5.0
        @test res_gt[1].consensus_probability ≈ 1.0
    end

    @testset "Logical AND" begin
        proto_and = """
        PROTOCOL LogicalAND
        PROCESSES: 2
        STATE:
            x ∈ ℝ
        INITIAL VALUES:
            [2.0, 5.0]
        CHANNEL:
            stochastic

        UPDATE RULE:
            EACH ROUND:
                if received_any and count(inbox) >= 1 then
                    xᵢ ← avg(all)
                else
                    xᵢ ← xᵢ
                end

        METRICS:
            consensus
        """

        res_and = run_protocol(proto_and; p_values=[1.0], rounds=1, repetitions=1, seed=1)
        # Both conditions true, both update to avg(all) = 3.5
        @test res_and[1].consensus_probability ≈ 1.0
    end

    @testset "Complex - Parameter Reference" begin
        proto_param = """
        PROTOCOL ParamReference
        PROCESSES: 2
        STATE:
            x ∈ ℝ
        INITIAL VALUES:
            [1.0, 9.0]
        PARAMETERS:
            target = 5.0
        CHANNEL:
            stochastic

        UPDATE RULE:
            EACH ROUND:
                xᵢ ← target

        METRICS:
            consensus
        """

        res_param = run_protocol(proto_param; p_values=[1.0], rounds=1, repetitions=1, seed=1)
        # Both nodes should converge to target=5.0
        @test res_param[1].consensus_probability ≈ 1.0
    end

    println("\n✓ All DSL extended expression tests passed!")
end
