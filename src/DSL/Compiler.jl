module Compiler

using ..IR: ProtocolIR, UpdateIR, UpdatePhaseIR, IfReceivedDiffIR, SelfValue, MeetingPoint, ReceivedOtherValue, SimpleOpIR, ExprIR, InboxPredicateIR, ReceivedAny, ReceivedDiffIR, ReceivedAll, ReceivedAtLeast, ReceivedMajority, IsLeaderPredicate, ConditionalIR, ConditionalElseIR, AssignIR, VarIR, IndexedVarIR, LiteralIR, BinOpIR, AggregateIR, ComparisonIR, LogicalOpIR
using ...Core: NodeId, Inbox, Message
using ...Protocols: Protocol, ProtocolInstance
using ...Channels: BernoulliChannel, ChannelModel
import ...Core: apply_protocol

# Compiled protocol placeholder; all behavior is driven via params/phases.
struct CompiledProtocol <: Protocol
end

"""
Compile a declarative `ProtocolIR` into an executable `ExperimentSpec`.
"""
function compile(ir::ProtocolIR; p::Float64, rounds::Int)
    root = parentmodule(parentmodule(@__MODULE__))
    Experiments = getfield(root, :Experiments)
    ExperimentSpec = getfield(Experiments, :ExperimentSpec)
    protocol = CompiledProtocol()
    params = Dict{Symbol,Any}(
        :num_nodes => ir.num_processes,
        :phases => ir.phases,
        :params => ir.params,
        :leader_id => get(ir.params, :leader_id, nothing),
        :guarantee => get(ir.params, :channel_guarantee, :none),
    )
    init_state = function (i::NodeId)
        if ir.init_values !== nothing
            vals = ir.init_values::Vector{Float64}
            return Dict{Symbol,Any}(:id => i, :x => vals[i])
        else
            return Dict{Symbol,Any}(:id => i, :x => Float64(ir.init_rule(i)))
        end
    end
    protocol_instance = ProtocolInstance(protocol, params)
    channel = BernoulliChannel(p)
    return ExperimentSpec(ir.num_processes, rounds, channel, protocol_instance, init_state, ir.delivery_models)
end

# -------------------------------------------------------------------------
# Protocol execution logic for the compiled protocol. This leverages the core
# engine (apply_protocol dispatch + ExperimentSpec).

function apply_protocol(state::Dict{Symbol,Any}, inbox::Inbox, params::Dict{Symbol,Any})
    haskey(state, :x) || error("Compiled protocol expects state[:x]")
    haskey(state, :id) || error("Compiled protocol expects state[:id]")
    node_id = Int(state[:id])
    x_self = Float64(state[:x])

    phases = params[:phases]
    # Merge user parameters (e.g. y) with engine-provided context (state_snapshot, round).
    protocol_params = Dict{Symbol,Any}(get(params, :params, Dict{Symbol,Any}()))
    for (k, v) in params
        protocol_params[k] = v
    end
    leader_id = get(params, :leader_id, nothing)
    current_round = get(params, :current_round, 1)
    consensus_flag = get(params, :consensus_flag, false)
    num_nodes = get(params, :num_nodes, 0)

    inbox_values, diff_values = collect_inbox_values(inbox, x_self)
    diff_flag = !isempty(diff_values)

    new_x = x_self
    for phase in phases
        phase.phase == :end && continue
        is_active = phase_active(phase, current_round, consensus_flag)
        is_active || continue
        new_x = evaluate_update(phase.rule, new_x, diff_flag, diff_values, inbox_values, protocol_params, leader_id, num_nodes, node_id)
    end

    num_nodes = get(params, :num_nodes, 0)
    outbound = Message[]
    for target in 1:num_nodes
        target == node_id && continue
        push!(outbound, Message(node_id, target, new_x))
    end

    return Dict{Symbol,Any}(:id => node_id, :x => new_x), outbound
end

function phase_active(phase::UpdatePhaseIR, round_idx::Int, consensus_flag::Bool)
    phase.phase == :each_round && return true
    phase.phase == :first_round && return round_idx == 1
    phase.phase == :after_rounds && return round_idx > (phase.param === nothing ? 0 : phase.param)
    phase.phase == :until && return !consensus_flag
    return false
end

function collect_inbox_values(inbox::Inbox, x_self::Float64)
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

function evaluate_update(ir::IfReceivedDiffIR, x_self::Float64, diff_flag::Bool, diff_values::Vector{Float64}, inbox_values::Vector{Float64}, params::Dict{Symbol,Any}, leader_id, num_nodes, node_id)
    if diff_flag
        return evaluate_expr(ir.then_expr, x_self, diff_values, inbox_values, params, leader_id, num_nodes, node_id)
    else
        return evaluate_expr(ir.else_expr, x_self, diff_values, inbox_values, params, leader_id, num_nodes, node_id)
    end
end

function evaluate_update(ir::SimpleOpIR, x_self::Float64, diff_flag::Bool, diff_values::Vector{Float64}, inbox_values::Vector{Float64}, params::Dict{Symbol,Any}, leader_id, num_nodes, node_id)
    # Simple aggregation; uses inbox numeric values plus self.
    values = [x_self; inbox_values]
    isempty(values) && error("Compiled protocol cannot update with empty value set")
    if ir.op == :average
        return sum(values) / length(values)
    elseif ir.op == :min
        return minimum(values)
    elseif ir.op == :max
        return maximum(values)
    elseif ir.op == :midpoint
        return (minimum(values) + maximum(values)) / 2
    else
        error("Unsupported update operator '$(ir.op)'")
    end
end

function evaluate_update(ir::ConditionalIR, x_self::Float64, diff_flag::Bool, diff_values::Vector{Float64}, inbox_values::Vector{Float64}, params::Dict{Symbol,Any}, leader_id, num_nodes, node_id)
    pred = evaluate_predicate(ir.predicate, inbox_values, diff_values, num_nodes, leader_id, node_id, params, x_self)
    if pred
        return evaluate_update(ir.rule, x_self, diff_flag, diff_values, inbox_values, params, leader_id, num_nodes, node_id)
    else
        return x_self
    end
end

function evaluate_update(ir::ConditionalElseIR, x_self::Float64, diff_flag::Bool, diff_values::Vector{Float64}, inbox_values::Vector{Float64}, params::Dict{Symbol,Any}, leader_id, num_nodes, node_id)
    pred = evaluate_predicate(ir.predicate, inbox_values, diff_values, num_nodes, leader_id, node_id, params, x_self)
    if pred
        return evaluate_update(ir.then_rule, x_self, diff_flag, diff_values, inbox_values, params, leader_id, num_nodes, node_id)
    else
        return evaluate_update(ir.else_rule, x_self, diff_flag, diff_values, inbox_values, params, leader_id, num_nodes, node_id)
    end
end

function evaluate_update(ir::AssignIR, x_self::Float64, diff_flag::Bool, diff_values::Vector{Float64}, inbox_values::Vector{Float64}, params::Dict{Symbol,Any}, leader_id, num_nodes, node_id)
    val = evaluate_expr(ir.expr, x_self, diff_values, inbox_values, params, leader_id, num_nodes, node_id)
    if ir.target isa VarIR || ir.target isa IndexedVarIR
        # Only support writing to x/self.
        return val
    else
        error("Assignment target is not supported")
    end
end

function evaluate_expr(expr::SelfValue, x_self::Float64, diff_values::Vector{Float64}, inbox_values::Vector{Float64}, params::Dict{Symbol,Any}, leader_id, num_nodes, node_id)
    return x_self
end

function evaluate_expr(expr::VarIR, x_self::Float64, diff_values::Vector{Float64}, inbox_values::Vector{Float64}, params::Dict{Symbol,Any}, leader_id, num_nodes, node_id)
    expr.name == :x || error("Variable $(expr.name) is not supported in this MVP")
    return x_self
end

function evaluate_expr(expr::IndexedVarIR, x_self::Float64, diff_values::Vector{Float64}, inbox_values::Vector{Float64}, params::Dict{Symbol,Any}, leader_id, num_nodes, node_id)
    expr.name == :x || error("Variable $(expr.name) is not supported in this MVP")
    expr.index == :self || error("Only self index is supported")
    return x_self
end

function evaluate_expr(expr::MeetingPoint, x_self::Float64, diff_values::Vector{Float64}, inbox_values::Vector{Float64}, params::Dict{Symbol,Any}, leader_id, num_nodes, node_id)
    haskey(params, expr.name) || error("Parameter $(expr.name) not provided; declare it in PARAMETERS")
    return Float64(params[expr.name])
end

function evaluate_expr(expr::ReceivedOtherValue, x_self::Float64, diff_values::Vector{Float64}, inbox_values::Vector{Float64}, params::Dict{Symbol,Any}, leader_id, num_nodes, node_id)
    isempty(diff_values) && error("FV requires a different received value but none was found in inbox")
    uniques = unique(diff_values)
    length(uniques) == 1 || error("FV received multiple distinct values in one round; use a different protocol if non-binary values are expected")
    return uniques[1]
end

function evaluate_expr(expr::LiteralIR, x_self::Float64, diff_values::Vector{Float64}, inbox_values::Vector{Float64}, params::Dict{Symbol,Any}, leader_id, num_nodes, node_id)
    return expr.value
end

function evaluate_expr(expr::BinOpIR, x_self::Float64, diff_values::Vector{Float64}, inbox_values::Vector{Float64}, params::Dict{Symbol,Any}, leader_id, num_nodes, node_id)
    left = evaluate_expr(expr.left, x_self, diff_values, inbox_values, params, leader_id, num_nodes, node_id)
    right = evaluate_expr(expr.right, x_self, diff_values, inbox_values, params, leader_id, num_nodes, node_id)

    if expr.op == :add
        return left + right
    elseif expr.op == :sub
        return left - right
    elseif expr.op == :mul
        return left * right
    elseif expr.op == :div
        right == 0.0 && error("Division by zero in expression")
        return left / right
    else
        error("Unknown binary operator: $(expr.op)")
    end
end

function evaluate_expr(expr::AggregateIR, x_self::Float64, diff_values::Vector{Float64}, inbox_values::Vector{Float64}, params::Dict{Symbol,Any}, leader_id, num_nodes, node_id)
    # Determine which values to aggregate
    values = if expr.source == :inbox
        inbox_values
    elseif expr.source == :inbox_with_self
        [x_self; inbox_values]
    else
        error("Unknown aggregation source: $(expr.source)")
    end

    isempty(values) && error("Cannot aggregate over empty set")

    if expr.op == :sum
        return sum(values)
    elseif expr.op == :avg
        return sum(values) / length(values)
    elseif expr.op == :min
        return minimum(values)
    elseif expr.op == :max
        return maximum(values)
    elseif expr.op == :count
        return Float64(length(values))
    else
        error("Unknown aggregation operator: $(expr.op)")
    end
end

function evaluate_predicate(pred::InboxPredicateIR, inbox_values::Vector{Float64}, diff_values::Vector{Float64}, num_nodes::Int, leader_id, node_id::Int, params::Dict{Symbol,Any}, x_self::Float64)
    if pred isa ReceivedAny
        return !isempty(inbox_values)
    elseif pred isa ReceivedDiffIR
        # Use snapshot if provided; otherwise fallback to current x_self.
        snapshot = get(params, :state_snapshot, nothing)
        base = x_self
        if snapshot !== nothing && haskey(snapshot, :x)
            xs = snapshot[:x]
            node_id <= length(xs) && (base = xs[node_id])
        end
        for v in inbox_values
            if v != base
                return true
            end
        end
        return false
    elseif pred isa ReceivedAll
        return length(inbox_values) >= max(num_nodes - 1, 0)
    elseif pred isa ReceivedAtLeast
        return length(inbox_values) >= pred.k
    elseif pred isa ReceivedMajority
        return length(inbox_values) > num_nodes / 2
    elseif pred isa IsLeaderPredicate
        leader_id === nothing && error("Leader predicate used but no leader defined")
        return node_id == leader_id
    elseif pred isa ComparisonIR
        left = evaluate_expr(pred.left, x_self, diff_values, inbox_values, params, leader_id, num_nodes, node_id)
        right = evaluate_expr(pred.right, x_self, diff_values, inbox_values, params, leader_id, num_nodes, node_id)

        if pred.op == :gt
            return left > right
        elseif pred.op == :lt
            return left < right
        elseif pred.op == :gte
            return left >= right
        elseif pred.op == :lte
            return left <= right
        elseif pred.op == :eq
            return left == right
        elseif pred.op == :neq
            return left != right
        else
            error("Unknown comparison operator: $(pred.op)")
        end
    elseif pred isa LogicalOpIR
        if pred.op == :not
            length(pred.operands) == 1 || error("NOT operator requires exactly one operand")
            return !evaluate_predicate(pred.operands[1], inbox_values, diff_values, num_nodes, leader_id, node_id, params, x_self)
        elseif pred.op == :and
            for operand in pred.operands
                if !evaluate_predicate(operand, inbox_values, diff_values, num_nodes, leader_id, node_id, params, x_self)
                    return false
                end
            end
            return true
        elseif pred.op == :or
            for operand in pred.operands
                if evaluate_predicate(operand, inbox_values, diff_values, num_nodes, leader_id, node_id, params, x_self)
                    return true
                end
            end
            return false
        else
            error("Unknown logical operator: $(pred.op)")
        end
    else
        error("Invalid inbox predicate")
    end
end

# NOTE: The previous overload for ReceivedDiffIR with different signature was removed
# because it conflicted with the generic evaluate_predicate dispatch.
# All calls now go through the InboxPredicateIR method.

end
