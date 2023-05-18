# This file was generated, do not modify it. # hide
@NLexpressions(
    model,
    begin
        ax[j=1:n], -(g/vt)*vx_proj[j]
        ay[j=1:n], -g -(g/vt)*vy_proj[j]
    end
)