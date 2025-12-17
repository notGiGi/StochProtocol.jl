module Protocols

# Espacio para describir protocolos distribuidos. No se definen reglas concretas
# todavía; solo las formas que deben tomar.

"""
Marca de tipo para cualquier protocolo distribuido.
"""
abstract type Protocol end

"""
Instancia de un protocolo parametrizado.
"""
struct ProtocolInstance
    protocol::Protocol
    params::Dict{Symbol,Any}
end

"""
Convenience constructor that widens parameter dictionaries to `Dict{Symbol,Any}`.
"""
ProtocolInstance(protocol::Protocol, params::Dict) = ProtocolInstance(protocol, Dict{Symbol,Any}(params))

end
