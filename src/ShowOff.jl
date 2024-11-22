module ShowOff

export Bracketed

#-----------------------------------------------------------------------------# Bracketed
struct Bracketed{T}
    x::T
    left::Char
    right::Char
    function Bracketed(x::T, left::Char, right::Char) where {T}
        eltype(T) == Char || throw(ArgumentError("Bracketed must wrap something that iterates `Char`s."))
        new{T}(x, left, right)
    end
end
Base.IteratorSize(::Type{Bracketed{T}}) where {T} = Base.IteratorSize(T)
Base.length(b::Bracketed) = length(b.x) + 2
Base.eltype(::Type{Bracketed{T}}) where {T} = Char

Base.@propagate_inbounds function Base.iterate(b::Bracketed, state='L')
    state == 'L' && return (b.left, 'x')
    state == 'R' && return (b.right, nothing)
    isnothing(state) && return nothing
    state == 'x' && return iterate(b.x)
    n = iterate(b.x, state)
    isnothing(n) && return iterate(b, 'R')
    return n[1], n[2]
end

#-----------------------------------------------------------------------------# characters
characters(::MIME"text/plain", x) = string(x)
characters(::MIME"text/plain", x::AbstractString) = Bracketed(x, '"', '"')

#-----------------------------------------------------------------------------# show
show(x) = show(stdout, x)
show(io::IO, x) = show(io, MIME"text/plain"(), x)
show(io::IO, mime::M, x) where {M <: MIME} = foreach(x -> print(io, x), characters(mime, x))



end  # end module
