"""
Communication delivery models for StochProtocol.

Provides different models for message delivery:
- Standard: Classic probabilistic delivery
- Guaranteed: Ensures minimum k messages delivered per round/execution
- Broadcast: All-or-nothing delivery per source process
"""
module DeliveryModels

export DeliveryModel, StandardModel, GuaranteedModel, BroadcastModel
export apply_delivery_model, satisfies_guarantees

"""
Abstract base type for all delivery models.
"""
abstract type DeliveryModel end

"""
Standard model: each message delivered independently with probability p.
This is the classic stochastic communication model.
"""
struct StandardModel <: DeliveryModel
end

"""
Guaranteed model: ensures at least k messages are delivered.

# Fields
- `min_messages::Int`: Minimum number of messages that must be delivered
- `scope::Symbol`: `:per_round` or `:total` - whether guarantee applies per round or total execution
"""
struct GuaranteedModel <: DeliveryModel
    min_messages::Int
    scope::Symbol  # :per_round or :total

    function GuaranteedModel(min_messages::Int, scope::Symbol=:per_round)
        if scope ∉ [:per_round, :total]
            error("scope must be :per_round or :total, got :$scope")
        end
        new(min_messages, scope)
    end
end

"""
Broadcast model: all-or-nothing delivery per source process.
If any message from process i is delivered, all messages from i are delivered.
If no message from process i is delivered, none are.

# Fields
- `probability::Symbol`: `:per_source` or `:uniform`
  - `:per_source`: each source has independent probability p
  - `:uniform`: use global probability p for all sources
"""
struct BroadcastModel <: DeliveryModel
    probability::Symbol  # :per_source or :uniform

    function BroadcastModel(probability::Symbol=:per_source)
        if probability ∉ [:per_source, :uniform]
            error("probability must be :per_source or :uniform, got :$probability")
        end
        new(probability)
    end
end

"""
    apply_delivery_model(model::StandardModel, p::Float64, n_processes::Int, rng)

Standard delivery: each message delivered independently with probability p.
Returns a vector of booleans indicating which messages were delivered.
"""
function apply_delivery_model(model::StandardModel, p::Float64, n_processes::Int, rng)
    # For n processes, there are n*(n-1) directed messages (i->j for all i≠j)
    n_messages = n_processes * (n_processes - 1)
    return [rand(rng) < p for _ in 1:n_messages]
end

"""
    apply_delivery_model(model::GuaranteedModel, p::Float64, n_processes::Int, rng)

Guaranteed delivery: same as standard, but checks will be done at higher level.
"""
function apply_delivery_model(model::GuaranteedModel, p::Float64, n_processes::Int, rng)
    # Generate standard delivery pattern
    # The guarantee checking happens in the experiment loop
    n_messages = n_processes * (n_processes - 1)
    return [rand(rng) < p for _ in 1:n_messages]
end

"""
    apply_delivery_model(model::BroadcastModel, p::Float64, n_processes::Int, rng)

Broadcast delivery: all-or-nothing per source process.
"""
function apply_delivery_model(model::BroadcastModel, p::Float64, n_processes::Int, rng)
    deliveries = Bool[]

    for sender in 1:n_processes
        # Decide if this sender's messages are delivered
        delivered = rand(rng) < p

        # Apply to all messages from this sender
        for receiver in 1:n_processes
            if sender != receiver
                push!(deliveries, delivered)
            end
        end
    end

    return deliveries
end

"""
    satisfies_guarantees(model::GuaranteedModel, deliveries::Vector{Bool}, round::Int)

Check if delivery pattern satisfies the guaranteed model's requirements for a single round.
"""
function satisfies_guarantees(model::GuaranteedModel, deliveries::Vector{Bool}, round::Int=1)
    if model.scope == :per_round
        return count(deliveries) >= model.min_messages
    else
        # For :total scope, we need to track across rounds - handled at experiment level
        return true  # Individual round always passes, checked at end
    end
end

satisfies_guarantees(model::StandardModel, deliveries::Vector{Bool}, round::Int=1) = true
satisfies_guarantees(model::BroadcastModel, deliveries::Vector{Bool}, round::Int=1) = true

"""
    count_total_deliveries(deliveries_history::Vector{Vector{Bool}})

Count total messages delivered across all rounds.
"""
function count_total_deliveries(deliveries_history::Vector{Vector{Bool}})
    return sum(sum(d) for d in deliveries_history)
end

end # module
