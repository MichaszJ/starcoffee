# This file was generated, do not modify it. # hide
ground_condition(u, t, integrator) = u[3]
ground_affect!(integrator) = terminate!(integrator)
ground_cb = ContinuousCallback(ground_condition, ground_affect!)