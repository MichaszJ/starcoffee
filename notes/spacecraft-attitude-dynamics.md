@def title = "Spacecraft Attitude Dynamics and Control"
@def tags = ["Note", "Modelling", "Control Systems"]

# Spacecraft Attitude Dynamics and Control - Notes

\tableofcontents

## Attitude Representation

### Euler Angles

Angular velocity:

$$
\vec \omega = S \dot{\vec \theta}
$$

If $\textbf C = \textbf R_x(\theta_3) \textbf R_y(\theta_2) \textbf R_z(\theta_1),$

$$
\vec \omega = S \dot{\vec \theta} = \begin{bmatrix} \dot \theta_3 \\ 0 \\ 0 \end{bmatrix} + \textbf R_x(\theta_3) \begin{bmatrix}0 \\ \dot \theta_2 \\ 0 \end{bmatrix} + \textbf R_x(\theta_3) \textbf R_y(\theta_2) \begin{bmatrix} 0 \\ 0 \\ \dot \theta_1 \end{bmatrix}
$$

### Angle-Axis

DCM from parameters:

$$
\textbf C_{BA} = \cos \phi + (1 - \cos \phi) a a^\intercal - \sin (\phi) a^\times
$$

Parameters from DCM:

$$
\cos \phi = \frac{1}{2} \left( C_{11} + C_{22} + C_{33} -1 \right) = \frac{1}{2}(\sigma - 1)
$$

$$
\vec a = \left\{ \begin{aligned} &\frac{1}{2 \sin \phi} \begin{bmatrix}
C_{23} - C_{32} \\ C_{31} - C_{13} \\ C_{12} - C_{21} \end{bmatrix} &\sigma \neq -1,3 \\ &\begin{bmatrix} \pm \sqrt{\frac{1 + C_{11}}{2}} \\ \pm \sqrt{\frac{1 + C_{22}}{2}} \\ \pm \sqrt{\frac{1 + C_{33}}{2}} \end{bmatrix} &\sigma = -1 \\ &\text{indeterminate} &\sigma=3 \end{aligned} \right.
$$

Angular velocity:

$$
\dot{\vec a} = \frac{1}{2} \left[ \vec a^\times - \cot \left(\frac{\phi}{2} \right) \vec a^\times \vec a^\times \right] \vec \omega
$$

$$
\dot \phi = \vec a^\intercal \vec \omega
$$

### Quaternions

DCM from parameters:

$$
\textbf C_{BA} = (\eta^2 - \vec \epsilon ^\intercal \vec \epsilon) + 2 \vec \epsilon \vec \epsilon^\intercal - 2 \eta \vec \epsilon^\times
$$

Parameters from axis-angle:

$$
\begin{aligned} \eta &= \cos \frac{\phi}{2} \\ \vec \epsilon &= \vec a \sin \frac{\phi}{2} \end{aligned}
$$

Parameters from DCM:

$$
\begin{aligned} \eta &= \pm \frac{1}{2} \sqrt{1 + C_{11} + C_{22} + C_{33}} \\ \vec \epsilon &= \frac{1}{4\eta} \begin{bmatrix} C_{23} - C_{32} \\ C_{31} - C_{13} \\ C_{12} - C_{22} \end{bmatrix} \end{aligned}
$$

Angular velocity:

$$
\begin{aligned} \dot{\vec \epsilon} &= \frac{1}{2}(\vec \epsilon^\times + \eta) \vec \omega \\ \dot \eta &= - \frac{1}{2} \vec \epsilon^\intercal \vec \omega \end{aligned}
$$

## Attitude Dynamics

Euler's equation is defined as:

$$
\vec M = \mathbf{J} \dot{\vec \omega} + \vec \omega^\times \mathbf{J} \vec \omega
$$

Assuming principal axis rotations, the equation can be expanded to:

$$
\begin{aligned} M_x &= J_x \dot \omega_x - (J_y - J_z) \omega_y \omega_z \\ M_y &= J_y \dot \omega_y - (J_z - J_x) \omega_x \omega_z \\ M_z &= J_z \dot \omega_z - (J_x - J_y) \omega_x \omega_y  \end{aligned}
$$

Linearized form plant model:
$$ G(s) = \frac{1}{Js^2} $$

#### Euler Angle Attitude Representation

Rate of change for 321 Euler angle rotation:

$$
 \begin{align*} \begin{bmatrix} \dot \phi \\ \dot \theta \\ \dot \psi \end{bmatrix}  &= \begin{bmatrix} 1 & \sin(\phi) \tan(\theta) & \cos(\phi) \tan(\theta) \\ 0 & \cos(\phi) & -\sin(\phi) \\ 0 & \sin(\phi) \sec(\theta) & \cos(\phi) \sec(\theta) \end{bmatrix} \begin{bmatrix} \omega_x \\ \omega_y \\ \omega_z \end{bmatrix} \\ &= \begin{bmatrix} \omega_x + \omega_z \tan(\theta) \cos(\phi) + \omega_y \tan(\theta) \sin(\phi) \\ \omega_y \cos(\phi) - \omega_z \sin(\phi) \\ \omega_z \sec(\theta) \cos(\phi) + \omega_y \sec(\theta) \sin(\phi)  \end{bmatrix} \end{align*}
$$

State vector:

$$
\displaystyle \vec u = \begin{bmatrix} \phi \\ \theta \\ \psi \\ \omega_x \\ \omega_y \\ \omega_z \end{bmatrix}  \; \; \; \dot{\vec u} = \begin{bmatrix} \dot \phi \\ \dot \theta \\ \dot \psi \\ \dot \omega_x \\ \dot \omega_y \\ \dot \omega_z \end{bmatrix} = \begin{bmatrix} \omega_x + \omega_z \tan(\theta) \cos(\phi) + \omega_y \tan(\theta) \sin(\phi) \\ \omega_y \cos(\phi) - \omega_z \sin(\phi) \\ \omega_z \sec(\theta) \cos(\phi) + \omega_y \sec(\theta) \sin(\phi) \\ \left[ M_x  + (J_y - J_z) \omega_y \omega_z\right]/J_x \\ \left[ M_y  + (J_z - J_x) \omega_x \omega_z \right]/J_y \\ \left[ M_z  + (J_x - J_y) \omega_x \omega_y \right]/J_z\end{bmatrix}
$$

#### Quaternion Attitude Representation

$$
\displaystyle \vec u = \begin{bmatrix} \vec q \\ \vec \omega \end{bmatrix} = \begin{bmatrix} q_0 \\ q_1 \\ q_2 \\ q_3 \\ \omega_x \\ \omega_y \\ \omega_z \end{bmatrix}
$$

$$
\displaystyle \dot{\vec u} = \begin{bmatrix} \frac{1}{2}(-q_1 \omega_x - q_2 \omega_y - q_3 \omega_z) \\ \frac{1}{2}(q_0 \omega_x + q_2 \omega_z - q_3 \omega_y) \\ \frac{1}{2}(q_0 \omega_y - q_1 \omega_z + q_3 \omega_x) \\ \frac{1}{2}(q_0 \omega_z + q_1 \omega_y - q_2 \omega_x) \\ \left[ M_x  + (J_y - J_z) \omega_y \omega_z\right]/J_x \\ \left[ M_y  + (J_z - J_x) \omega_x \omega_z \right]/J_y \\ \left[ M_z  + (J_x - J_y) \omega_x \omega_y \right]/J_z \end{bmatrix}
$$

## Attitude Control

### PD Control

Frequency domain definition:
$$ \begin{aligned} M_c &= (K_p + sK_d) \tilde{\Delta \theta} \\ H_C &= K_p + sK_d \end{aligned} $$

Time-domain definition:

$$
M_c = K_p \Delta \theta + K_d \Delta \dot \theta = K_p (\theta_\text{ref} - \theta) + K_d (\dot \theta_\text{ref} - \dot \theta)
$$

Defining gains in terms of natural frequency and damping ratio:

$$
K_p = J \omega_n^2
$$

$$
K_d = 2 J \omega_n \zeta
$$

### Quaternion Feedback Control

Control law:

$$
\vec u = - \mathbf K \vec q_{\text{err}, v} - \mathbf C \vec \omega_\text{err}
$$

Known formulations:

$$
\mathbf K = K \mathbf I, \; \mathbf C = \text{diag}(C_1, C_2, C_3), \; K, C_i > 0
$$

$$
\mathbf K = \frac{K}{q_{\text{err}, s}^3} \mathbf I, \; \mathbf C = \text{diag}(C_1, C_2, C_3)
$$

$$
\mathbf K = K \text{sign}(q_{\text{err}, s}) \mathbf I, \; \mathbf C = \text{diag}(C_1, C_2, C_3)
$$

$$
\mathbf K = \left[ \alpha \mathbf J + \beta \mathbf I \right]^{-1}, \; \mathbf K^{-1} \mathbf C \leq 0, \; \alpha, \beta \leq 0
$$

Eigen-axis rotations:

$$
\vec u = - \mathbf K \vec q_{\text{err}, v} - \mathbf C \vec \omega_\text{err} + \vec \omega^\times \mathbf J \vec \omega
$$
