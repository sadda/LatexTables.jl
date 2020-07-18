ordered_keys = [:format, :color]


function apply(row::CellArray)

    string(join(apply.(row), " & "), " \\\\ \n")
end

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
mutable struct Color <: LatexStyle
    val::Symbol
end

apply(s::Color, x) = string("\\color{", s.val,"}{", x, "}")


# Rounding
mutable struct Format <: LatexStyle
    type::Char
    precision::Int
end

Format(type::Char) = Format(type, 0)


# TODO needs to be "2f" or similar
Format(s::String) = Format(s[2], parse(Int, s[1]))


string_dig(x, digits::Int) = format(x, precision=digits)

apply(s::Format, x) = x

function apply(s::Format, x::Real)

    prec = s.precision
    type = s.type
    if type == 'f'
        r = string_dig(x, prec)
    elseif type == 'p'
        r = string_dig(100*x, prec) * "\\%"
    elseif type == 'd'
        r = string_dig(x, 0)
    elseif type == 'e'
        if x == 0
            r = "0"
        else
            order_of_mag = floor(log10(abs(x)))
            value_print  = x*10^(-order_of_mag)
            r = string_dig(value_print, prec) * "\\cdot 10^{" * string_dig(order_of_mag, 0) * "}"
        end
    else
        error("Type not defined.")
    end

    return "\$" * r * "\$"
end
