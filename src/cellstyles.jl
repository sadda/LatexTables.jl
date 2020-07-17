ordered_keys = [:format, :prefix, :suffix, :size, :color]


function apply(M::CellMatrix)
    rows = map(enumerate(eachrow(M))) do (i, row)
        string(join(apply.(row), " & "), " \\\\ \n")
    end
    return reduce(string, rows)
end

apply(c::Cell) = apply(c.style, c.val)

function apply(styles::Dict{Symbol, LatexStyle}, x)
    val = x
    for key in ordered_keys
        haskey(styles, key) || continue
        val = apply(styles[key], val)
    end
    return val
end

# Color
struct Color <: LatexStyle
    val::Symbol
end

apply(s::Color, x) = string("\\color{", s.val,"}{", x, "}")


# Text size
struct Size <: LatexStyle
    val::Symbol
end

apply(s::Size, x) = string("\\", s.val, "{", x, "}")


# Rounding
struct Format <: LatexStyle
    val::NamedTuple
end

Format(; kwargs...) = Format(values(kwargs))

apply(s::Format, x) = x
apply(s::Format, x::Real) = format(x; s.val...)


# Prefix
struct Prefix <: LatexStyle
    val::String
end

apply(s::Prefix, x) = string(s.val, " ", x)


# Suffix
struct Suffix <: LatexStyle
    val::String
end

apply(s::Suffix, x) = string(x, " ", s.val)
