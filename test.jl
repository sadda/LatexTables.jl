using Revise
using LatexTables

body = rand(4,5)
body[1,1] = maximum(body[1,:])

print(table_to_tex(body;
    #col_format=["", "1e", "", "", "2f"],
    #row_format=["1p", "", "", ""],
    max_row=true,
    min_row=true,
    caption="Wow"
    ));
