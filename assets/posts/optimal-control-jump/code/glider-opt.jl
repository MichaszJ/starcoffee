# This file was generated, do not modify it. # hide
@objective(glider_model, Max, x[n_glider])

optimize!(glider_model)
solution_summary(glider_model)