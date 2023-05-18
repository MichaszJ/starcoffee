# This file was generated, do not modify it. # hide
# enforcing boundary conditions
fix(x_proj[1], 0; force=true)
fix(x_proj[n], xt; force=true)

fix(y_proj[1], 0; force=true)
fix(y_proj[n], yt; force=true)

# initial guess for initial velocity
set_start_value(vx_proj[1], 20)
set_start_value(vy_proj[1], 20)