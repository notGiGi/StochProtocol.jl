module Core

# Núcleo semántico: definiciones mínimas de tipos y contratos para el motor.
# No se implementa lógica avanzada aquí para mantener el espacio acotado.

"""
Identificador estable para un nodo participante.
"""
const NodeId = Int

"""
Número de ronda lógica.
"""
const Round = Int

"""
Mensaje que viaja entre nodos.
"""
struct Message
    sender::NodeId
    receiver::NodeId
    payload::Any
end

"""
Bandeja de entrada de mensajes entregados a un nodo.
"""
const Inbox = Vector{Message}

"""
Marca abstracta para el estado local de un nodo. Para este MVP se asume que el
estado se representa como `Dict{Symbol,Any}` con un valor numérico en `:x`.
"""
abstract type LocalState end

"""
Estado global agregado por ronda.
"""
struct GlobalState
    round::Round
    local_states::Dict{NodeId,Any}
end

"""
Contrato que debe implementar cualquier protocolo: cómo procesa un estado e
inbox para producir `(next_state, outbound_messages)`. Solo se declara la firma.
"""
function apply_protocol end

"""
Extract the numeric value of a node's local state following the convention that
state is a dictionary holding a `:x` entry. Raises a clear error if absent.
"""
function node_value(local_state)::Float64
    if local_state isa AbstractDict
        haskey(local_state, :x) || error("Local state is missing required key :x")
        return Float64(local_state[:x])
    else
        error("Unsupported local state type for node_value; expected a Dict with :x")
    end
end

"""
Convenience accessor for a node value within a global state snapshot.
"""
function node_value(global_state::GlobalState, node::NodeId)::Float64
    haskey(global_state.local_states, node) || error("Node $(node) not found in global state")
    return node_value(global_state.local_states[node])
end

end
