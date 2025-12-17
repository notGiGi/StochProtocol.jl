module ProtocolMacro

"""
String macro entry point for notebooks. Executes the protocol immediately with
notebook-friendly defaults and returns the run result. We resolve the root
module dynamically to avoid name-resolution issues when the macro is expanded
from other modules or notebooks.
"""
macro protocol_str(s)
    explore_mod = parentmodule(@__MODULE__) # StochProtocol.Explore
    return :($explore_mod.Run.run($s))
end

export @protocol_str

"Alias macro for convenience (`proto\"\"\"...\"\"\"`)."
macro proto_str(s)
    explore_mod = parentmodule(@__MODULE__) # StochProtocol.Explore
    return :($explore_mod.Run.run($s))
end

export @proto_str

end
