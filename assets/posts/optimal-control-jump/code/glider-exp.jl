# This file was generated, do not modify it. # hide
@NLexpressions(
    glider_model,
    begin
        C_D[j=1:n_glider], C_0 + k * C_L[j]^2

        X[j=1:n_glider], (x[j]/R - 2.5)^2

        u_a[j=1:n_glider], u_M*(1 - X[j])*exp(-X[j])

        V_y[j=1:n_glider], vy[j] - u_a[j]

        v_r[j=1:n_glider], sqrt(vx[j]^2 + V_y[j]^2)

        L[j=1:n_glider], 0.5*C_L[j]*ρ*S*v_r[j]^2

        D[j=1:n_glider], 0.5*C_D[j] * ρ * S * v_r[j]^2

        sin_η[j=1:n_glider], V_y[j]/v_r[j]

        cos_η[j=1:n_glider], vx[j]/v_r[j]
    end
)