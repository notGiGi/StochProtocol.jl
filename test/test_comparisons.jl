using Test
using StochProtocol: compare

const AMP_PROTO = abspath(joinpath(@__DIR__, "..", "examples", "protocols", "amp.protocol"))
const FV_PROTO  = abspath(joinpath(@__DIR__, "..", "examples", "protocols", "fv.protocol"))

@test begin
    compare(AMP_PROTO,
            FV_PROTO;
            p_values=0:0.1:1,
            rounds=1,
            repetitions=1000) do
        """
        for p > 0.6:
            AMP.consensus > FV.consensus
        """
    end
    true
end

@test begin
    compare(AMP_PROTO,
            FV_PROTO;
            p_values=0:0.1:1,
            rounds=1,
            repetitions=1000) do
        """
        for p < 0.4:
            FV.consensus > AMP.consensus
        """
    end
    true
end
