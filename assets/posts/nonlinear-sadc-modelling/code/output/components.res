12-element Vector{Symbolics.Equation}:
 connect(setpoint_sca.output, feedback_ϕ.input1)
 connect(feedback_ϕ.output, ctrl_ϕ.err_input)
 connect(ctrl_ϕ.ctr_output, sc.Mx)
 connect(sc.phi_x, feedback_ϕ.input2)
 connect(setpoint_sca.output, feedback_θ.input1)
 connect(feedback_θ.output, ctrl_θ.err_input)
 connect(ctrl_θ.ctr_output, sc.My)
 connect(sc.phi_y, feedback_θ.input2)
 connect(setpoint_sca.output, feedback_ψ.input1)
 connect(feedback_ψ.output, ctrl_ψ.err_input)
 connect(ctrl_ψ.ctr_output, sc.Mz)
 connect(sc.phi_z, feedback_ψ.input2)