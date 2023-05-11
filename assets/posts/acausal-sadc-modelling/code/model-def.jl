# This file was generated, do not modify it. # hide
@component function LinearSpacecraftAttitude(
    ; name, Jx=100.0, Jy=100.0, Jz=100.0, u0=zeros(3), ω0=zeros(3), ω̇0=zeros(3)
)

    @named Ix = Rot.Inertia(
        J=Jx, phi_start=u0[1], w_start=ω0[1], a_start=ω̇0[1]
    )
    @named Iy = Rot.Inertia(
        J=Jy, phi_start=u0[2], w_start=ω0[2], a_start=ω̇0[2]
    )
    @named Iz = Rot.Inertia(
        J=Jz, phi_start=u0[3], w_start=ω0[3], a_start=ω̇0[3]
    )

    @named x_flange_a = Rot.Flange()
    @named y_flange_a = Rot.Flange()
    @named z_flange_a = Rot.Flange()

    @named x_flange_b = Rot.Flange()
    @named y_flange_b = Rot.Flange()
    @named z_flange_b = Rot.Flange()

    @named ϕ_sensor = Rot.AngleSensor()
    @named θ_sensor = Rot.AngleSensor()
    @named ψ_sensor = Rot.AngleSensor()

    ps = @parameters Jx=Jx Jy=Jy Jz=Jz u0=u0 ω0=ω0 ω̇0=ω̇0

    eqs = [
        connect(x_flange_a, Ix.flange_a),
        connect(y_flange_a, Iy.flange_a),
        connect(z_flange_a, Iz.flange_a),

        connect(Ix.flange_b, x_flange_b),
        connect(Iy.flange_b, y_flange_b),
        connect(Iz.flange_b, z_flange_b),

        connect(x_flange_b, ϕ_sensor.flange),
        connect(y_flange_b, θ_sensor.flange),
        connect(z_flange_b, ψ_sensor.flange),
    ]

    compose(
        ODESystem(eqs, t, [], ps; name = name),
        Ix, Iy, Iz,
        x_flange_a, y_flange_a, z_flange_a,
        x_flange_b, y_flange_b, z_flange_b,
        ϕ_sensor, θ_sensor, ψ_sensor
    )
end