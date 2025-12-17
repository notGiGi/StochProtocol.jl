module Channels

# Abstracción de canales estocásticos. Las implementaciones concretas decidirán
# cómo se entregan o pierden los mensajes.

"""
Declarative guarantee for delivery; interpreted by the simulation engine.
"""
struct ChannelGuarantee
    type::Symbol  # :none, :at_least_one, :majority
end

"""
Modelo abstracto de canal.
"""
abstract type ChannelModel end

"""
Canal Bernoulli que entrega cada mensaje con probabilidad `p`.
"""
struct BernoulliChannel <: ChannelModel
    p::Float64
end

"""
Decide si un mensaje se entrega bajo el canal Bernoulli.
"""
function deliver(channel::BernoulliChannel)
    return rand() < channel.p
end

end
