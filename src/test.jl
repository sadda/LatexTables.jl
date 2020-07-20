using Revise
using LatexTables

include("utilities.jl")

body        = rand(4,5)
body[:,3]   = 0.3*rand(4)
body[:,end] = 0.7.+0.3*rand(4)

s1 = table_to_tex(body;
    max_row=true,
    min_row=true,
    caption="And the winner is ... swan. Sorry penguin",
    leading_col=["We", "all", "like", "swans"],
    header=["Header", "Header2", "Penguin", "Header4", "Swan"],
    )
print(s1)


n    = 5
x1   = rand(n)
x2   = 1 .+ rand(n)
body = hcat(collect(1:n), x1, x2, x1./x2, [x./y >= 0.6 ? "Yes" : "No" for (x,y) in zip(x1,x2)])

s2 = table_to_tex(body;
    col_format=["d", "", "", "1p", ""],
    header=["Employee ID", "Result", "Target", "Performance", "Satisfaction"],
    alignment="lrrrr",
    )
print(s2)

make_tex_file("output", "test1.tex", s1)
make_tex_file("output", "test2.tex", s2)







a = 1
