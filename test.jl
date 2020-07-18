using Revise
using LatexTables

body        = rand(4,5)
body[:,3]   = 0.3*rand(4)
body[:,end] = 0.7.+0.3*rand(4)

print(table_to_tex(body;
    #col_format=["", "1e", "", "", "2f"],
    #row_format=["1p", "", "", ""],
    max_row=true,
    min_row=true,
    caption="And the winner is ... swan. Sorry penguin",
    leading_col=["We", "all", "like", "swans"],
    header=["Header", "Header2", "Penguin", "Header4", "Swan"],
    #header=repeat(reshape(["Header", "Header2", "Penguin", "Header4", "Swan"], 1,:), 2),
    alignment="l"
    ));