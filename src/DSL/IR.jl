module IR

# Intermediate representation of a protocol as declared in the DSL. This is a
# purely mathematical description: no engine logic or randomness lives here.

abstract type UpdateIR end
abstract type ExprIR end
abstract type InboxPredicateIR end

"Non-indexed variable reference."
struct VarIR <: ExprIR
    name::Symbol
end

"Indexed variable like xᵢ (index=:self for current node)."
struct IndexedVarIR <: ExprIR
    name::Symbol
    index::Symbol
end
"""
Use the node's own value.
"""
struct SelfValue <: ExprIR
end

"""
Use a meeting point parameter (e.g., `y`).
"""
struct MeetingPoint <: ExprIR
    name::Symbol
end

"""
Use a received value different from the local one (for FV).
"""
struct ReceivedOtherValue <: ExprIR
end

"""
Literal numeric value.
"""
struct LiteralIR <: ExprIR
    value::Float64
end

"""
Binary arithmetic operation: +, -, *, /
"""
struct BinOpIR <: ExprIR
    op::Symbol  # :add, :sub, :mul, :div
    left::ExprIR
    right::ExprIR
end

"""
Aggregation operation on inbox or all values: sum, avg, min, max, count
"""
struct AggregateIR <: ExprIR
    op::Symbol  # :sum, :avg, :min, :max, :count
    source::Symbol  # :inbox, :inbox_with_self
end

"""
Conditional update: if inbox contains a value different from self, use `then_expr`,
otherwise use `else_expr`.
"""
struct IfReceivedDiffIR <: UpdateIR
    then_expr::ExprIR
    else_expr::ExprIR
end

"""
Simple aggregation operator (kept for backward compatibility).
"""
struct SimpleOpIR <: UpdateIR
    op::Symbol
end

"""
One phase of execution: applies either each round or only at the end.
`recursive=true` signals that the rule should be treated as part of a recursive
scheme (conceptual flag for documentation).
"""
struct UpdatePhaseIR
    phase::Symbol      # :each_round, :end, :first_round, :after_rounds, :until
    recursive::Bool
    rule::UpdateIR
    param::Union{Nothing,Int,Symbol}
end

# Inbox predicates for limited conditionals.
struct ReceivedAny <: InboxPredicateIR end
struct ReceivedAll <: InboxPredicateIR end
struct ReceivedAtLeast <: InboxPredicateIR
    k::Int
end
struct ReceivedMajority <: InboxPredicateIR end
struct ReceivedDiffIR <: InboxPredicateIR
    var::Symbol
end
struct IsLeaderPredicate <: InboxPredicateIR end

"""
Comparison predicate: >, <, >=, <=, ==, !=
"""
struct ComparisonIR <: InboxPredicateIR
    op::Symbol  # :gt, :lt, :gte, :lte, :eq, :neq
    left::ExprIR
    right::ExprIR
end

"""
Logical operation: and, or, not
"""
struct LogicalOpIR <: InboxPredicateIR
    op::Symbol  # :and, :or, :not
    operands::Vector{InboxPredicateIR}
end

# Conditional rule guarded by an inbox predicate.
struct ConditionalIR <: UpdateIR
    predicate::InboxPredicateIR
    rule::UpdateIR
end

"Conditional with explicit else branch."
struct ConditionalElseIR <: UpdateIR
    predicate::InboxPredicateIR
    then_rule::UpdateIR
    else_rule::UpdateIR
end

"Direct assignment to an expression (e.g., xᵢ ← y or xᵢ ← self)."
struct AssignIR <: UpdateIR
    target::ExprIR
    expr::ExprIR
end

"""
ProtocolIR captures the declarative intent of a protocol as read from the DSL.
"""
struct ProtocolIR
    name::String
    num_processes::Int
    init_rule::Function
    init_values::Union{Nothing,Vector{Float64}}
    phases::Vector{UpdatePhaseIR}
    metrics::Vector{Symbol}
    params::Dict{Symbol,Any}
end

end
