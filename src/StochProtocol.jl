module StochProtocol

include("Core.jl")
include("Channels.jl")
include("Protocols.jl")
include("Metrics.jl")
include("DSL.jl")
include("Experiments.jl")
include("Explore.jl")
include("Comparisons.jl")
include("ProtocolString.jl")

using .Core
using .Channels
using .Protocols
using .Metrics
using .DSL: @protocol
using .Experiments
using .Explore: @protocol_str, @proto_str, run_protocol, study, summary, table
using .Explore: plot_discrepancy_vs_p, plot_consensus_vs_p, plot_comparison
using .Explore: results_table, results_comparison_table
using .Comparisons
using .ProtocolString: Protocol

# API pública: API explícita y macro declarativa para notebooks.
export @protocol_str,
       @proto_str,
       run_protocol,
       compare,
       study,
       summary,
       table,
       plot_discrepancy_vs_p,
       plot_consensus_vs_p,
       plot_comparison,
       results_table,
       results_comparison_table,
       Protocol

end
