module Experiments

using ..Channels: ChannelModel, BernoulliChannel
using ..Protocols: Protocol, ProtocolInstance
using ..Core: NodeId, Message, Inbox
using ..Metrics: discrepancy_from_locals, consensus_from_locals, RunSummary, DEFAULT_CONSENSUS_EPS
using ..DSL.IR: UpdatePhaseIR, UpdateIR, IfReceivedDiffIR, SimpleOpIR, SelfValue, MeetingPoint, ReceivedOtherValue, ConditionalIR, ConditionalElseIR, ExprIR, AssignIR, VarIR, IndexedVarIR, DeliveryModelSpec
using ..DSL: Compiler
using ..DeliveryModels: DeliveryModel, StandardModel, GuaranteedModel, BroadcastModel, apply_delivery_model, satisfies_guarantees, count_total_deliveries
import ..Core: apply_protocol

# Simple deterministic RNG (LCG) to avoid external dependencies while allowing
# reproducible Monte Carlo sweeps.
mutable struct SimpleRNG
    state::UInt64
end

function SimpleRNG(seed::Int)
    s = UInt64(seed == 0 ? 1 : seed)
    return SimpleRNG(s)
end

# Returns a Float64 in (0,1).
function rand_unit!(rng::SimpleRNG)::Float64
    rng.state = muladd(6364136223846793005, rng.state, 1)
    return Float64(rng.state) / 18446744073709551615.0
end

# Motor sincrónico sencillo para experimentar con protocolos distribuidos.

"""
Describe la configuración mínima de un experimento sobre un protocolo y canal dados.
"""
struct ExperimentSpec
    num_nodes::Int
    num_rounds::Int
    channel::ChannelModel
    protocol::ProtocolInstance
    init_state::Function
    delivery_models::Vector{DeliveryModelSpec}  # Communication models configuration
end

"""
Execute a synchronous experiment, tracking discrepancy at each round.
Returns a `RunSummary` with final values and per-round trace.
"""
function run_experiment(spec::ExperimentSpec; rng_seed::Int=1, consensus_eps::Float64=DEFAULT_CONSENSUS_EPS, trace::Bool=false, trace_limit::Int=1)
    rng = SimpleRNG(rng_seed)
    local_states = Dict{NodeId,Any}()
    for node_id in 1:spec.num_nodes
        local_states[node_id] = spec.init_state(node_id)
    end

    # Prepare inboxes and an outbound queue. We model a round as:
    # (i) deliver queued messages -> inboxes
    # (ii) apply rule with state_before + inbox -> provisional state + next outbound
    # (iii) commit all provisional states simultaneously.
    inboxes = Dict{NodeId,Inbox}()
    for node_id in 1:spec.num_nodes
        inboxes[node_id] = Message[]
    end
    # Initial broadcast based on current state so round 1 has messages.
    outbound_queue = initial_broadcast(local_states)

    # Track discrepancy starting from round 0.
    discrepancies = Float64[]
    push!(discrepancies, discrepancy_from_locals(local_states))

    # Track messages delivered per round (for guaranteed model filtering)
    messages_per_round = Int[]
    total_messages_delivered = 0

    for round_idx in 1:spec.num_rounds
        # Deliver queued messages for this round.
        inboxes, msgs_delivered = deliver_messages(outbound_queue, spec.num_nodes, spec.channel, rng, spec.protocol.params, spec.delivery_models)
        push!(messages_per_round, msgs_delivered)
        total_messages_delivered += msgs_delivered

        snapshot_vec = snapshot_values(local_states)
        state_before = snapshot_vec
        provisional_states = Dict{NodeId,Any}()
        outbound_messages = Message[]
        consensus_now = consensus_from_locals(local_states; eps=consensus_eps)

        # Each node processes its inbox and produces state and messages.
        diff_flags = Dict{NodeId,Bool}()
        for node_id in 1:spec.num_nodes
            state = local_states[node_id]
            inbox = inboxes[node_id]
            params_with_round = merge(spec.protocol.params, Dict(:current_round => round_idx, :consensus_flag => consensus_now, :state_snapshot => Dict(:x => snapshot_vec), :channel_p => spec.channel isa BernoulliChannel ? spec.channel.p : 1.0))
            next_state, outbound = apply_protocol(state, inbox, params_with_round)
            provisional_states[node_id] = next_state
            append!(outbound_messages, outbound)
            inbox_vals, diff_vals = Compiler.collect_inbox_values(inbox, Float64(state[:x]))
            diff_flags[node_id] = !isempty(diff_vals)
        end

        # Commit all provisional states simultaneously.
        local_states = provisional_states
        outbound_queue = outbound_messages
        discrepancy_now = discrepancy_from_locals(local_states)
        consensus_now = consensus_from_locals(local_states; eps=consensus_eps)
        push!(discrepancies, discrepancy_now)

        if trace # trace only when requested for this repetition
            log_trace_round(round_idx, state_before, inboxes, provisional_states, local_states, discrepancy_now, consensus_now, diff_flags)
        end
    end

    # Apply END phases once using the inbox from the last round, if any.
    if has_end_phase(spec.protocol.params)
        local_states = apply_end_phases(local_states, inboxes, spec.protocol.params, consensus_eps)
        push!(discrepancies, discrepancy_from_locals(local_states))
    end

    discrepancy_final = discrepancies[end]
    consensus_final = consensus_from_locals(local_states; eps=consensus_eps)
    return RunSummary(discrepancy_final, consensus_final, discrepancies, total_messages_delivered, messages_per_round)
end

"""
Configuration for repeating an experiment multiple times with a fixed seed.
"""
struct MonteCarloSpec
    experiment::ExperimentSpec
    repetitions::Int
    seed::Int
end

"""
Aggregated statistics over multiple runs for a given channel probability.
"""
struct MonteCarloResult
    p::Float64
    repetitions::Int
    mean_discrepancy::Float64
    var_discrepancy::Float64
    consensus_probability::Float64
    mean_discrepancy_by_round::Vector{Float64}
end

"""
Run many repetitions of an experiment, returning aggregate statistics for D and consensus.
For guaranteed models, only counts repetitions that satisfy the delivery guarantees.
"""
function run_many(mc::MonteCarloSpec; consensus_eps::Float64=DEFAULT_CONSENSUS_EPS, trace::Bool=false, trace_limit::Int=1)::MonteCarloResult
    disc_final = Float64[]
    consensus_flags = Bool[]
    extra_end = has_end_phase(mc.experiment.protocol.params) ? 1 : 0
    mean_by_round = zeros(Float64, mc.experiment.num_rounds + 1 + extra_end)

    # Check if we have guaranteed models
    model_map, _ = build_delivery_model_map(mc.experiment.delivery_models, mc.experiment.num_nodes)
    has_guaranteed = any(m isa GuaranteedModel for m in values(model_map))

    # Find guaranteed model specs for validation
    guaranteed_models = [m for m in values(model_map) if m isa GuaranteedModel]

    valid_reps = 0
    attempt = 0
    max_attempts = has_guaranteed ? mc.repetitions * 100 : mc.repetitions  # Allow up to 100x attempts for guaranteed

    while valid_reps < mc.repetitions && attempt < max_attempts
        attempt += 1
        do_trace = trace && valid_reps < trace_limit
        run = run_experiment(mc.experiment; rng_seed=mc.seed + attempt - 1, consensus_eps=consensus_eps, trace=do_trace, trace_limit=trace_limit)

        # Check if this run satisfies guaranteed model requirements
        run_valid = true
        if has_guaranteed
            for model in guaranteed_models
                if model.scope == :per_round
                    # Check each round
                    for msgs in run.messages_per_round
                        if msgs < model.min_messages
                            run_valid = false
                            break
                        end
                    end
                else  # :total
                    # Check total messages
                    if run.total_messages_delivered < model.min_messages
                        run_valid = false
                    end
                end
                run_valid || break
            end
        end

        # Only count valid runs
        if run_valid
            push!(disc_final, run.discrepancy_final)
            push!(consensus_flags, run.discrepancy_final <= consensus_eps)
            @assert length(run.discrepancy_by_round) == length(mean_by_round)
            mean_by_round .+= run.discrepancy_by_round
            valid_reps += 1
        end
    end

    if valid_reps < mc.repetitions
        @warn "Only found $valid_reps valid runs out of $mc.repetitions requested (after $attempt attempts). Guaranteed model constraints may be too strict for p=$(mc.experiment.channel.p)"
    end

    n = valid_reps
    mean_d = n > 0 ? sum(disc_final) / n : 0.0
    var_d = n > 1 ? sum((disc_final .- mean_d) .^ 2) / (n - 1) : 0.0
    consensus_prob = n > 0 ? sum(consensus_flags) / n : 0.0
    mean_by_round = n > 0 ? mean_by_round ./ n : mean_by_round

    p_value = mc.experiment.channel isa BernoulliChannel ? mc.experiment.channel.p :
              error("MonteCarloResult requires a BernoulliChannel to extract p")

    return MonteCarloResult(p_value, n, mean_d, var_d, consensus_prob, mean_by_round)
end

"""
Decide delivery for a Bernoulli channel using the local RNG.
"""
function message_delivered!(rng::SimpleRNG, channel::BernoulliChannel)::Bool
    return rand_unit!(rng) < channel.p
end

# Fallback for other channel models (not yet implemented).
function message_delivered!(rng::SimpleRNG, channel::ChannelModel)::Bool
    return message_delivered!(rng, BernoulliChannel(1.0))
end

"""
Enforce declarative guarantees after stochastic delivery by forcing minimal
deliveries from the remaining messages.
"""
function enforce_guarantee!(params::Dict{Symbol,Any}, inboxes::Dict{NodeId,Inbox}, undelivered::Vector{Message}, num_nodes::Int, rng::SimpleRNG)
    guarantee = get(params, :guarantee, :none)
    guarantee == :none && return
    if guarantee == :at_least_one
        for node in keys(inboxes)
            if isempty(inboxes[node])
                msg = findfirst(m -> m.receiver == node, undelivered)
                msg === nothing || begin
                    push!(inboxes[node], undelivered[msg])
                    deleteat!(undelivered, msg)
                end
            end
        end
    elseif guarantee == :majority
        need = floor(Int, num_nodes / 2) + 1
        for node in keys(inboxes)
            while length(inboxes[node]) < need
                msg_idx = findfirst(m -> m.receiver == node, undelivered)
                msg_idx === nothing && break
                push!(inboxes[node], undelivered[msg_idx])
                deleteat!(undelivered, msg_idx)
            end
        end
    else
        error("Unknown channel guarantee")
    end
end

"""
Convert a DeliveryModelSpec to an actual DeliveryModel instance.
"""
function build_delivery_model(spec::DeliveryModelSpec)::DeliveryModel
    if spec.model_type == :standard
        return StandardModel()
    elseif spec.model_type == :guaranteed
        min_msg = get(spec.params, :min_messages, 1)
        scope = get(spec.params, :scope, :per_round)
        return GuaranteedModel(min_msg, scope)
    elseif spec.model_type == :broadcast
        prob = get(spec.params, :probability, :per_source)
        return BroadcastModel(prob)
    else
        error("Unknown delivery model type: $(spec.model_type)")
    end
end

"""
Build a per-process delivery model map from delivery model specs.
Returns a Dict mapping process_id => DeliveryModel, with a default global model.
"""
function build_delivery_model_map(specs::Vector{DeliveryModelSpec}, num_nodes::Int)
    # Find global model (process_id == nothing)
    global_spec = findfirst(s -> s.process_id === nothing, specs)
    global_model = if global_spec !== nothing
        build_delivery_model(specs[global_spec])
    else
        StandardModel()  # Default if no global specified
    end

    # Build per-process map
    model_map = Dict{Int,DeliveryModel}()
    for i in 1:num_nodes
        # Check if there's a specific model for this process
        specific = findfirst(s -> s.process_id == i, specs)
        if specific !== nothing
            model_map[i] = build_delivery_model(specs[specific])
        else
            model_map[i] = global_model
        end
    end

    return model_map, global_model
end

# Deliver a batch of outbound messages into per-node inboxes using delivery models.
function deliver_messages(outbound::Vector{Message}, num_nodes::Int, channel::ChannelModel, rng::SimpleRNG, params::Dict{Symbol,Any}, delivery_specs::Vector{DeliveryModelSpec})
    next_inboxes = Dict{NodeId,Inbox}()
    for node_id in 1:num_nodes
        next_inboxes[node_id] = Message[]
    end

    # Build delivery model map
    model_map, _ = build_delivery_model_map(delivery_specs, num_nodes)

    # Check if we're using a global standard model (can use old fast path)
    all_standard = all(m isa StandardModel for m in values(model_map))

    if all_standard
        # Fast path: use original Bernoulli delivery
        undelivered = Message[]
        for message in outbound
            if message_delivered!(rng, channel)
                push!(next_inboxes[message.receiver], message)
            else
                push!(undelivered, message)
            end
        end
        enforce_guarantee!(params, next_inboxes, undelivered, num_nodes, rng)
        return next_inboxes
    end

    # New path: use delivery models
    # Group messages by sender
    messages_by_sender = Dict{Int,Vector{Message}}()
    for i in 1:num_nodes
        messages_by_sender[i] = Message[]
    end
    for msg in outbound
        push!(messages_by_sender[msg.sender], msg)
    end

    # Apply delivery model for each sender
    p = channel isa BernoulliChannel ? channel.p : 1.0
    for sender in 1:num_nodes
        sender_messages = messages_by_sender[sender]
        isempty(sender_messages) && continue

        model = model_map[sender]

        if model isa BroadcastModel
            # All-or-nothing for this sender
            deliver_all = rand_unit!(rng) < p
            if deliver_all
                for msg in sender_messages
                    push!(next_inboxes[msg.receiver], msg)
                end
            end
        elseif model isa StandardModel
            # Independent delivery for each message
            for msg in sender_messages
                if rand_unit!(rng) < p
                    push!(next_inboxes[msg.receiver], msg)
                end
            end
        elseif model isa GuaranteedModel
            # Standard delivery, guarantees enforced later
            for msg in sender_messages
                if rand_unit!(rng) < p
                    push!(next_inboxes[msg.receiver], msg)
                end
            end
        end
    end

    # Note: Guaranteed model validation happens at the experiment loop level
    # Legacy guarantee enforcement for backward compatibility
    undelivered = Message[]
    enforce_guarantee!(params, next_inboxes, undelivered, num_nodes, rng)

    # Count total messages delivered
    total_delivered = sum(length(inbox) for inbox in values(next_inboxes))

    return next_inboxes, total_delivered
end

# Backward compatibility: version without delivery_specs uses standard model
# Returns just inboxes for backward compatibility
function deliver_messages(outbound::Vector{Message}, num_nodes::Int, channel::ChannelModel, rng::SimpleRNG, params::Dict{Symbol,Any})
    default_spec = [DeliveryModelSpec(:standard, Dict{Symbol,Any}(), nothing)]
    inboxes, _ = deliver_messages(outbound, num_nodes, channel, rng, params, default_spec)
    return inboxes
end

# Construct an initial broadcast so round 1 has messages.
function initial_broadcast(local_states::Dict{NodeId,Any})
    outbound = Message[]
    for (node_id, state) in local_states
        x = state[:x]
        for target in keys(local_states)
            target == node_id && continue
            push!(outbound, Message(node_id, target, x))
        end
    end
    return outbound
end

# Snapshot vector of x values ordered by node id.
function snapshot_values(local_states::Dict{NodeId,Any})
    return [Float64(local_states[i][:x]) for i in sort!(collect(keys(local_states)))]
end

# Trace helper.
function log_trace_round(round_idx::Int, state_before, inboxes, provisional_states, committed_states, discrepancy_now, consensus_now, diff_flags)
    println("Round $(round_idx) trace")
    println("  state_before: ", state_before)
    for node_id in sort!(collect(keys(inboxes)))
        inbox_list = [(m.sender, m.payload) for m in inboxes[node_id]]
        println("  node $(node_id) inbox: ", inbox_list, " received_diff=", get(diff_flags, node_id, false))
    end
    println("  provisional_state: ", [Float64(provisional_states[i][:x]) for i in sort!(collect(keys(provisional_states)))])
    println("  committed_state:   ", [Float64(committed_states[i][:x]) for i in sort!(collect(keys(committed_states)))])
    println("  discrepancy: $(discrepancy_now) consensus: $(consensus_now)")
end

"""
Specification for sweeping different Bernoulli delivery probabilities.
"""
struct SweepPSpec
    base_experiment::ExperimentSpec
    p_values::Vector{Float64}
    repetitions::Int
    seed::Int
end

"""
Run a sweep over p values, returning MonteCarlo results for each probability.
"""
function run_sweep_p(spec::SweepPSpec; consensus_eps::Float64=DEFAULT_CONSENSUS_EPS)::Vector{MonteCarloResult}
    results = MonteCarloResult[]
    for (idx, p) in enumerate(spec.p_values)
        channel = BernoulliChannel(p)
        exp_base = spec.base_experiment
        experiment = ExperimentSpec(
            exp_base.num_nodes,
            exp_base.num_rounds,
            channel,
            exp_base.protocol,
            exp_base.init_state
        )
        mc_spec = MonteCarloSpec(experiment, spec.repetitions, spec.seed + idx)
        push!(results, run_many(mc_spec; consensus_eps=consensus_eps))
    end
    return results
end

# ----------------------------------------------------------------------
# Verificación interna: protocolo de juguete que copia el primer valor recibido
# y lo reenvía a los demás nodos. No se exporta; sirve solo para probar el motor.

struct CopyFirstProtocol <: Protocol
end

function apply_protocol(state::Dict{Symbol,Float64}, inbox::Inbox, params::Dict{Symbol,Any})
    haskey(state, :x) || error("CopyFirstProtocol expects state[:x]")
    haskey(state, :id) || error("CopyFirstProtocol expects state[:id]")
    node_id = Int(state[:id])
    x_current = state[:x]
    new_value = isempty(inbox) ? x_current : Float64(inbox[1].payload)
    num_nodes = get(params, :num_nodes, 0)
    outbound = Message[]
    for target in 1:num_nodes
        target == node_id && continue
        push!(outbound, Message(node_id, target, new_value))
    end
    return Dict{Symbol,Float64}(:id => node_id, :x => new_value), outbound
end

function _toy_experiment_spec()
    protocol = CopyFirstProtocol()
    params = Dict{Symbol,Any}(:num_nodes => 3)
    protocol_instance = ProtocolInstance(protocol, params)
    channel = BernoulliChannel(1.0)
    init_state(node_id::NodeId) = Dict{Symbol,Float64}(:id => node_id, :x => Float64(node_id))
    return ExperimentSpec(3, 5, channel, protocol_instance, init_state)
end

function _run_toy_experiment()
    # Simple standalone toy run for internal sanity checking.
    return run_experiment(_toy_experiment_spec(); rng_seed=1)
end

function has_end_phase(params::Dict{Symbol,Any})
    phases = get(params, :phases, UpdatePhaseIR[])
    any(p -> p.phase == :end, phases)
end

function apply_end_phases(local_states::Dict{NodeId,Any}, inboxes::Dict{NodeId,Inbox}, params::Dict{Symbol,Any}, consensus_eps::Float64)
    phases = get(params, :phases, UpdatePhaseIR[])
    end_phases = filter(p -> p.phase == :end, phases)
    isempty(end_phases) && return local_states
    # Apply end phases sequentially; outbound messages are ignored at END.
    new_states = Dict{NodeId,Any}()
    leader_id = get(params, :leader_id, nothing)
    num_nodes = length(local_states)
    snapshot_vec = snapshot_values(local_states)
    params_with_snapshot = Dict{Symbol,Any}(get(params, :params, Dict{Symbol,Any}()))
    for (k, v) in params
        params_with_snapshot[k] = v
    end
    params_with_snapshot[:state_snapshot] = Dict(:x => snapshot_vec)
    for (node_id, state) in local_states
        inbox = get(inboxes, node_id, Message[])
        x_self = Float64(state[:x])
        inbox_values, diff_values = collect_inbox_values_end(inbox, x_self)
        diff_flag = !isempty(diff_values)
        x_new = x_self
        for phase in end_phases
            x_new = evaluate_update_end(phase.rule, x_new, diff_flag, diff_values, inbox_values, params_with_snapshot, leader_id, num_nodes, node_id)
        end
        new_states[node_id] = Dict{Symbol,Any}(:id => node_id, :x => x_new)
    end
    return new_states
end

function collect_inbox_values_end(inbox::Inbox, x_self::Float64)
    inbox_values = Float64[]
    diff_values = Float64[]
    for m in inbox
        if m.payload isa Number
            v = Float64(m.payload)
            push!(inbox_values, v)
            v != x_self && push!(diff_values, v)
        end
    end
    return inbox_values, diff_values
end

function evaluate_update_end(ir::UpdateIR, x_self::Float64, diff_flag::Bool, diff_values::Vector{Float64}, inbox_values::Vector{Float64}, params::Dict{Symbol,Any}, leader_id, num_nodes, node_id::Int)
    if ir isa IfReceivedDiffIR
        ir2 = ir::IfReceivedDiffIR
        if diff_flag
            return evaluate_expr_end(ir2.then_expr, x_self, diff_values, inbox_values, params, leader_id, num_nodes, node_id)
        else
            return evaluate_expr_end(ir2.else_expr, x_self, diff_values, inbox_values, params, leader_id, num_nodes, node_id)
        end
    elseif ir isa SimpleOpIR
        ir2 = ir::SimpleOpIR
        values = [x_self; inbox_values]
        isempty(values) && error("Compiled protocol cannot update with empty value set")
        if ir2.op == :average
            return sum(values) / length(values)
        elseif ir2.op == :min
            return minimum(values)
        elseif ir2.op == :max
            return maximum(values)
        elseif ir2.op == :midpoint
            return (minimum(values) + maximum(values)) / 2
        else
            error("Unsupported update operator '$(ir2.op)'")
        end
    elseif ir isa ConditionalIR
        ir2 = ir::ConditionalIR
        pred = Compiler.evaluate_predicate(ir2.predicate, inbox_values, diff_values, num_nodes, leader_id, node_id, params, x_self)
        if pred
            return evaluate_update_end(ir2.rule, x_self, diff_flag, diff_values, inbox_values, params, leader_id, num_nodes, node_id)
        else
            return x_self
        end
    elseif ir isa ConditionalElseIR
        ir2 = ir::ConditionalElseIR
        pred = Compiler.evaluate_predicate(ir2.predicate, inbox_values, diff_values, num_nodes, leader_id, node_id, params, x_self)
        if pred
            return evaluate_update_end(ir2.then_rule, x_self, diff_flag, diff_values, inbox_values, params, leader_id, num_nodes, node_id)
        else
            return evaluate_update_end(ir2.else_rule, x_self, diff_flag, diff_values, inbox_values, params, leader_id, num_nodes, node_id)
        end
    elseif ir isa AssignIR
        ir2 = ir::AssignIR
        return evaluate_expr_end(ir2.expr, x_self, diff_values, inbox_values, params, leader_id, num_nodes, node_id)
    else
        error("Unsupported update rule in END phase")
    end
end

function evaluate_expr_end(expr::ExprIR, x_self::Float64, diff_values::Vector{Float64}, inbox_values::Vector{Float64}, params::Dict{Symbol,Any}, leader_id, num_nodes, node_id::Int)
    if expr isa SelfValue
        return x_self
    elseif expr isa VarIR
        expr.name == :x || error("Variable $(expr.name) is not supported in this MVP")
        # Prefer snapshot if provided.
        if haskey(params, :state_snapshot)
            snap = params[:state_snapshot]
            if snap isa Dict && haskey(snap, :x) && node_id <= length(snap[:x])
                return Float64(snap[:x][node_id])
            end
        end
        return x_self
    elseif expr isa IndexedVarIR
        expr.name == :x || error("Variable $(expr.name) is not supported in this MVP")
        expr.index == :self || error("Only self index is supported")
        if haskey(params, :state_snapshot)
            snap = params[:state_snapshot]
            if snap isa Dict && haskey(snap, :x) && node_id <= length(snap[:x])
                return Float64(snap[:x][node_id])
            end
        end
        return x_self
    elseif expr isa MeetingPoint
        mp = expr::MeetingPoint
        haskey(params, mp.name) || error("Parameter $(mp.name) not provided; declare it in PARAMETERS")
        return Float64(params[mp.name])
    elseif expr isa ReceivedOtherValue
        isempty(diff_values) && error("FV requires a different received value but none was found in inbox")
        uniques = unique(diff_values)
        length(uniques) == 1 || error("FV received multiple distinct values in one round; use a different protocol if non-binary values are expected")
        return uniques[1]
    else
        error("Unsupported expression in END phase")
    end
end

end
