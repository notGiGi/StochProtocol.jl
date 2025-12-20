module StochProtocol

include("Core.jl")
include("Channels.jl")
include("DeliveryModels.jl")
include("Protocols.jl")
include("Metrics.jl")
include("DSL.jl")
include("Experiments.jl")
include("Explore.jl")
include("Comparisons.jl")
include("ProtocolString.jl")

# Advanced features (optional modules)
include("Topologies.jl")
include("Faults.jl")
include("ConvergenceAnalysis.jl")
include("Tracing.jl")

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

# Advanced features
using .Topologies
using .Faults
using .ConvergenceAnalysis
using .Tracing

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

# Advanced features - Network Topologies
export Topology,
       CompleteGraph, Ring, Star, Grid,
       RandomGraph, KRegular, BipartiteGraph, CustomTopology,
       neighbors, can_communicate, diameter, visualize_topology

# Advanced features - Fault Models
export FaultModel,
       NoFaults, CrashFaults, ByzantineFaults,
       NetworkPartition, MessageCorruption, DelayFaults,
       TransientFaults, CompositeFaults,
       is_faulty, crashed_nodes

# Advanced features - Convergence Analysis
export convergence_rate, time_to_epsilon_consensus,
       stability_metric, lyapunov_function,
       mixing_time, diameter_bound_efficiency,
       tail_bound_analysis, phase_transition_detection,
       convergence_probability, expected_rounds_to_consensus,
       spectral_gap_estimate, contraction_factor,
       average_contraction, variance_reduction_rate

# Advanced features - Tracing and Debugging
export TraceLevel, NoTrace, BasicTrace, DetailedTrace, VerboseTrace,
       ExecutionTrace, RoundTrace, MessageTrace, StateChange,
       enable_tracing, disable_tracing, set_trace_level,
       trace_execution, message_flow_diagram,
       state_evolution_table, detect_anomalies,
       export_trace, filter_trace, trace_summary

end
