module Errors

"""
Friendly error type for notebook-facing APIs. Keeps stacktraces hidden unless
`debug=true` is used.
"""
struct ExploreError <: Exception
    message::String
end

Base.showerror(io::IO, e::ExploreError) = print(io, e.message)

"""
Wrap a computation and convert unexpected exceptions into `ExploreError`.
Use `debug=true` to rethrow the original exception for debugging.
"""
function explore_try(f; debug::Bool=false)
    try
        return f()
    catch err
        debug && rethrow(err)
        msg = err isa ExploreError ? err.message : (err isa ErrorException ? err.msg : sprint(showerror, err))
        throw(ExploreError(msg))
    end
end

end
