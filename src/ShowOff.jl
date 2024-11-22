module ShowOff

export Bracketed, Limit

abstract type CharIterator end
print_chars(::M, c::C) where {M <: MIME, C <: CharIterator} = c
Base.IteratorSize(::Type{T}) where {T <: CharIterator} = Base.HasLength()
Base.eltype(::Type{T}) where {T <: CharIterator} = Char

check(::Type{T}) where {T} = eltype(T) == Char ? T : throw(ArgumentError("Iterator must iterate `Char`s."))

#-----------------------------------------------------------------------------# Bracketed
struct Bracketed{T} <: CharIterator
    x::T
    left::Char
    right::Char
    Bracketed(x::T, left::Char, right::Char) where {T} = new{check(T)}(x, left, right)
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


#-----------------------------------------------------------------------------# Limit
struct Limit{T} <: CharIterator
    x::T
    n::Int
    Limit(x::T, n::Int) where {T} = new{check(T)}(x, n)
end
Base.length(o::Limit) = min(length(o.x), o.n)

Base.@propagate_inbounds function Base.iterate(lim::Limit, state=nothing)
    i = isnothing(state) ? length(lim) : state[1]
    i == 0 && return nothing
    next = isnothing(state) ? iterate(lim.x) : iterate(lim.x, state[2])
    isnothing(next) && return nothing
    return next[1], (i - 1, next[2])
end

#-----------------------------------------------------------------------------# Join
struct Join{T <: Tuple} <: CharIterator
    items::T
    function Join(x::T) where {T}
        foreach(check, T.parameters)
        new{T}(x)
    end
end
Join(x, y...) = Join((x, y...))
Base.length(o::Join) = sum(length, o.items)

Base.@propagate_inbounds function Base.iterate(o::Join, i::Int=1)
    i > length(o.items) && return nothing
    next = iterate(o.items[i])
    isnothing(next) && return iterate(o, i + 1)
    return next[1], (i, next[2])
end
Base.@propagate_inbounds function Base.iterate(o::Join, state)
    i = state[1]
    next = iterate(o.items[i], state[2])
    isnothing(next) && return iterate(o, i + 1)
    return next[1], (i, next[2])
end



#-----------------------------------------------------------------------------# print_chars
print_chars(::MIME"text/plain", x::AbstractString) = Bracketed(x, '"', '"')


#-----------------------------------------------------------------------------# show
show(x) = show(stdout, x)

show(io::IO, x) = show(io, MIME"text/plain"(), x)

function show(io::IO, ::M, x) where {M <: MIME}
    for c in print_chars(M(), x)
        print(io, c)
    end
end




end  # end module
