module Explore

include("Explore/Errors.jl")
include("Explore/Views.jl")
include("Explore/Run.jl")
include("Explore/Study.jl")
include("Explore/ProtocolMacro.jl")
include("Explore/Visualization.jl")

using .Errors
using .Views: summary, table, as_dataframe, ExploreRun
using .Run
using .Study
using .ProtocolMacro: @protocol_str, @proto_str
using .Visualization

const run = Run.run

export run_protocol, run, study, summary, table, ExploreError
export @protocol_str, @proto_str
export plot_discrepancy_vs_p, plot_consensus_vs_p, plot_comparison, results_table, results_comparison_table

end
