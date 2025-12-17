using StochProtocol
using StochProtocol.DSL.Parser: parse_protocol_text

proto_text = """
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

println("\n=== PARSING TEST ===")
println("Input text:")
println(proto_text)
println("---")
ir = parse_protocol_text(proto_text)
println("Protocol name: ", ir.name)
println("Num processes: ", ir.num_processes)
println("Num phases: ", length(ir.phases))
for (i, phase) in enumerate(ir.phases)
    println("  Phase $i: $(phase.phase), rule type: $(typeof(phase.rule))")
end
println("==================\n")
