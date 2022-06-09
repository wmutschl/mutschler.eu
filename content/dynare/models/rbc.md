---
title: Real Business Cycle (RBC) model
linktitle: RBC model
summary: This tutorial covers the theory and derivations of the Real-Business-Cycle (RBC) model with leisure. The Dynare implementation makes use of model local variables to distinguish between a log-utility function and a more general CES-utility function.
#date: "2021-08-18"
type: book
draft: false
toc: true
weight: 11
---

## Model description
Consider the basic Real Business Cycle (RBC) model with leisure. The representative household maximizes present as well as expected future utility
\begin{align*}
    \underset{\{C_{t},I_{t},L_t,K_{t}\}}{\max} E_t \sum_{j=0}^{\infty} \beta^{j} U_{t+j}
\end{align*}
with $\beta <1$ denoting the discount factor and $E_t$ is expectation given information at time $t$. We will consider two functional specifications for the contemporaneous utility function.
{{< math >}}
\begin{align*}
U_t &= \gamma \log(C_t) + \psi \log{(1-L_t)} & ~~[\text{log-utility}]
\\
U_t &= \gamma \frac{C_{t}^{1-\eta_C}-1}{1-\eta_C} +\psi \frac{(1-L_{t})^{1-\eta_L}-1}{1-\eta_L} &~~[\text{CES}]
\end{align*}
{{< /math >}}
Note that due to L'Hopital's rule $\eta_C=\eta_L=1$ implies the log-utility specification. In both cases, contemporenous utility is additively separable and has two arguments: consumption $C_t$ and labor $L_t$. The marginal utility of consumption is positive, whereas more labor reduces utility. Accordingly, $\gamma$ is the consumption utility parameter and $\psi$ the labor disutility parameter. In each period the household takes the real wage $W_t$ as given and supplies perfectly elastic labor service to the representative firm. In return, she receives real labor income in the amount of $W_t L_t$ and, additionally, profits $\Pi_t$ from the firm as well as revenue from lending capital $K_t$ at interest rate $R_t$ to the firms, as it is assumed that the firm and capital stock are owned by the household. Income and wealth are used to finance consumption $C_t$ and investment $I_t$. In total, this defines the (real) budget constraint of the household:
\begin{align*}
C_t + I_t = W_t L_t + R_t K_t + \Pi_t
\end{align*}
	
The law of motion for capital $K_{t-1}$ at the end of period $t$ is given by
\begin{align*}
K_{t} = (1-\delta)K_{t-1} + I_t
\end{align*}
and $\delta$ is controlling depreciations. Assume that the transversality condition[^1] is full-filled.

[^1]: The transversality condition for an infinite horizon dynamic optimization problem is the boundary condition determining a solution to the problem's first-order conditions together with the initial condition. The transversality condition requires the present value of the state variables (here $K_{t-1}$ and $A_t$) to converge to zero as the planning horizon recedes towards infinity. The first-order and transversality conditions are sufficient to identify an optimum in a concave optimization problem. Given an optimal path, the necessity of the transversality condition reflects the impossibility of finding an alternative feasible path for which each state variable deviates from the optimum at each time and increases discounted utility.
	
Productivity $A_t$ is the driving force of the economy and evolves according to
\begin{align*}
    \log{A_{t}} &= \rho_A \log{A_{t-1}}  + \varepsilon_t^A
\end{align*}
where $\rho_A$ denotes the persistence parameter and $\varepsilon_t^A$ is assumed to be normally distributed with mean zero and variance $\sigma_A^2$.
	
Real profits $\Pi_t$ of the representative firm are revenues from selling output $Y_t$ minus costs from labor $W_t L_t$ and renting capital $R_t K_{t-1}$:
\begin{align*}
\Pi_t = Y_{t} - W_{t} L_{t} - R_{t} K_{t-1}
\end{align*}	
The representative firm maximizes expected profits
\begin{align*}
    \underset{\{L_{t},K_{t-1}\}}{\max} E_t \sum_{j=0}^{\infty} \beta^j Q_{t+j}\Pi_{t+j}
\end{align*}
subject to a Cobb-Douglas production function
\begin{align*}
f(K_{t-1}, L_t) = Y_t = A_t K_{t-1}^\alpha L_t^{1-\alpha}
\end{align*}
The discount factor takes into account that firms are owned by the household, i.e. $\beta^j Q_{t+j}$ is the present value of a unit of consumption in period $t+j$ or, respectively, the marginal utility of an additional unit of profit; therefore $Q_{t+j}=\frac{\partial U_{t+j}/\partial C_{t+j}}{\partial U_{t}/\partial C_{t}}$.
	
Finally, we have the non-negativity constraints	$K_t \geq0$, $C_t \geq 0$ and $0\leq L_t \leq 1$ and clearing of the labor as well as goods market in equilibrium, i.e.:
\begin{align*}
Y_t = C_t + I_t
\end{align*}

## First-order conditions of the representative household
Due to our assumptions, we will not have corner solutions and can neglect the non-negativity constraints. Due to the transversality condition and the concave optimization problem, we only need to focus on the first-order conditions. Therefore, we will now show that the first-order conditions of the representative household are given by
\begin{align*}
U_t^C &= \beta E_t\left[U_{t+1}^C\left(1-\delta + R_{t+1}\right)\right] \\\\\\
W_t &= -\frac{U_t^L}{U_t^C}
\end{align*}
where $U_t^C=\frac{\partial U_t}{\partial C_t}$ and $U_t^L = \frac{\partial U_t}{\partial L_t}$. In case of log-utility, we have the following functional specifications:
\begin{align*}
U_t^C &= \gamma C_t^{-1}\\\\\\
U_t^L &= - \psi (1-L_t)^{-1}
\end{align*}
whereas for CES utility we have:
\begin{align*}
U_t^C &= \gamma C_t^{-\eta_C}\\\\\\
U_t^L &= - \psi (1-L_t)^{-\eta_L}
\end{align*}

The Lagrangian for the household problem is:
\begin{align*}
L = E_t\sum_{j=0}^{\infty}&\beta^j U_{t+j}\left(C_{t+j},L_{t+j}\right) \\\\\\
&+\beta^j\lambda_{t+j}\left[W_{t+j} L_{t+j} + R_{t+j} K_{t-1+j} - C_{t+j} - I_{t+j}\right] \\\\\\
&+\beta^j \mu_{t+j} \left[(1-\delta)K_{t-1+j} + I_{t+j} - K_{t+j}\right]
\end{align*}
Note that the problem is not to choose $[C_t,I_t,L_t,K_{t}]_{t=0}^\infty$ all at once in an open-loop policy, but to choose these variables sequentially given the information at time $t$ in a closed-loop policy, i.e. at period $t$ decision rules for $\{C_t,I_t,L_t,K_{t}\}$ given the information set at period $t$; at period $t+1$ decision rules for $[C_{t+1},I_{t+1},L_{t+1},K_{t+1}]$ given the information set at period $t+1$. The first-order condition w.r.t. $C_t$ is given by
\begin{align*}
\frac{\partial L}{\partial C_{t}} &= E_t \left(U_t^{C}-\lambda_{t}\right) = 0 \\\\\\
\Leftrightarrow \lambda_{t} &= U_t^{C} & (I)
\end{align*}
The first-order condition w.r.t. $L_t$ is given by
\begin{align*}
\frac{\partial L}{\partial L_{t}} &= E_t \left(U_t^{L} + \lambda_{t} W_{t}\right) = 0 \\\\\\
\Leftrightarrow \lambda_{t} W_{t} &= - U_t^{L} &(II)
\end{align*}
The first-order condition w.r.t. $I_{t}$ is given by
\begin{align*}
\frac{\partial L}{\partial I_{t}} &= E_t \beta^j \left(-\lambda_{t} + \mu_{t}\right) = 0 \\\\\\
\Leftrightarrow \lambda_{t} &= \mu_{t} & (III)
\end{align*}
The first-order condition w.r.t. $K_{t}$ is given by
\begin{align*}
\frac{\partial L}{\partial K_{t}} &= E_t (-\mu_{t}) + E_t \beta \left(\lambda_{t+1}R_{t+1}+\mu_{t+1}(1-\delta)\right) = 0 \\\\\\
\Leftrightarrow \mu_{t} &= E_t \beta(\mu_{t+1}(1-\delta)+\lambda_{t+1}R_{t+1}) & (IV)
\end{align*}
		
(I) and (III) in (IV) yields
\begin{align*}
U_t^c &= \beta E_t U_{t+1}^c\left(1-\delta + R_{t+1}\right)
\end{align*}
This is the Euler equation of intertemporal optimality. It reflects the trade-off between consumption and savings. If the household saves a (marginal) unit of consumption, she can consume the gross rate of return on capital, i.e. $(1-\delta+R_{t+1})$ units, in the following period. The marginal utility of consuming today is equal to $U_t^c$, whereas consuming tomorrow has expected utility $E_t(U_{t+1}^c)$. Discounting expected marginal utility with $\beta$ the household must be indifferent between both choices in the optimum.
		
(I) in (II) yields:
\begin{align*}
W_t = - \frac{U_t^L}{U_t^c}
\end{align*}
This equation reflects intratemporal optimality, particularly, the optimal choice for labor supply: the real wage must be equal to the marginal rate of substitution between labor and consumption.



## First-order conditions of the representative firm
First, we note that even though firms maximize expected profits here we actually have a simple static problem. That is, the objective is to maximize profits
\begin{align*}
\Pi_t = A_t K_{t-1}^\alpha L_t^{1-\alpha} - W_t L_t - R_t K_{t-1}
\end{align*}
We will now show that the first-order conditions are given by:
\begin{align*}
W_t &= f_L\\\\\\
R_t &= f_K
\end{align*}
where $f_L = (1-\alpha) A_t \left(\frac{K_{t-1}}{L_t}\right)^\alpha$ and $f_K = \alpha A_t \left(\frac{K_{t-1}}{L_t}\right)^{1-\alpha}$.

Let's start with the first-order condition w.r.t. $L_{t}$ which is given by
\begin{align*}
\frac{\partial \Pi_t}{\partial L_{t}} &= (1-\alpha) A_t K_{t-1}^\alpha L_t^{-\alpha} - W_t = 0 \\\\\\
\Leftrightarrow W_t &= (1-\alpha) A_t K_{t-1}^\alpha L_t^{-\alpha} = f_L = (1-\alpha) \frac{Y_t}{L_t}
\end{align*}
Intuitively, the real wage must be equal to the marginal product of labor. Due to the Cobb-Douglas production function it is a constant proportion $(1-\alpha)$ of the ratio of total output and labor. This is the labor demand function.
		
Second, the first-order condition w.r.t. $K_{t-1}$ is given by
\begin{align*}
\frac{\partial \Pi_t}{\partial K_{t-1}} &= \alpha A_t K_{t-1}^{\alpha-1} L_t^{1-\alpha} - R_t = 0 \\\\\\
\Leftrightarrow R_t &= \alpha A_t K_{t-1}^{\alpha-1} L_t^{1-\alpha} = f_K = \alpha \frac{Y_t}{K_{t-1}}
\end{align*}
Intuitively, the real interest rate must be equal to the marginal product of capital. Due to the Cobb-Douglas production function it is a constant proportion $\alpha$ of the ratio of total output and capital. This is the capital demand function.
		
## Steady state
The steady state of this model is a fixed point, in the sense that there is a set of values for the endogenous variables that in equilibrium and in the absence of shocks remain constant over time. Usually, we want to provide a **recipe** how to compute these values sequentially.

First, consider the steady state value of technology: 
\begin{align*}
\log\bar{A}=\rho_A \log\bar{A} + 0 \Leftrightarrow \log\bar{A} = 0 \Leftrightarrow \bar{A} = 1
\end{align*} 
The Euler equation in steady state becomes:
\begin{align*}
\bar{U}^C &= \beta \bar{U}^C(1-\delta+\bar{R})\\\\\\
\Leftrightarrow \bar{R} &= \frac{1}{\beta} + \delta - 1
\end{align*}
		
Now the trick is to provide closed-form expressions for all variables recursively, but in relation to steady state labor.
- The firms demand for capital in steady state becomes
\begin{align*}
\bar{R} &= \alpha \bar{A} \bar{K}^{\alpha-1}\bar{L}^{1-\alpha}\\\\\\
\Leftrightarrow \frac{\bar{K}}{\bar{L}} &= \left(\frac{\alpha \bar{A}}{\bar{R}}\right)^{\frac{1}{1-\alpha}}
\end{align*}
- The firms demand for labor in steady state becomes:
\begin{align*}
W =(1-\alpha) \bar{A}\bar{K}^\alpha \bar{L}^{-\alpha} = (1-\alpha)\bar{A} \left(\frac{\bar{K}}{\bar{L}}\right)^\alpha
\end{align*}
- The law of motion for capital in steady state implies
\begin{align*}
\frac{\bar{I}}{\bar{L}} &= \delta\frac{\bar{K}}{\bar{L}}
\end{align*}
- The production function in steady state becomes
		\begin{align*}
			\frac{\bar{Y}}{\bar{L}} = \bar{A} \left(\frac{\bar{K}}{\bar{L}}\right)^\alpha
		\end{align*}
- The clearing of the goods market in steady state implies 
		\begin{align*}
		\frac{\bar{C}}{\bar{L}} = \frac{\bar{Y}}{\bar{L}} - \frac{\bar{I}}{\bar{L}}
		\end{align*}

Now, we need to derive steady state labor from the equilibrium on the labor market. 

### Log-utility
Due to the log-utility, we can derive a closed-form expression:
\begin{align*}
\psi \frac{1}{1-\bar{L}} &= \gamma \bar{C}^{-1} W \\\\\\
\Leftrightarrow \psi \frac{\bar{L}}{1-\bar{L}} &= \gamma \left(\frac{\bar{C}}{\bar{L}}\right)^{-1} W \\\\\\
\Leftrightarrow \bar{L} &= (1-\bar{L})\frac{\gamma}{\psi} \left(\frac{\bar{C}}{\bar{L}}\right)^{-1} W \\\\\\
\Leftrightarrow \bar{L} &= \frac{\frac{\gamma}{\psi} \left(\frac{\bar{C}}{\bar{L}}\right)^{-1} W}{1+\frac{\gamma}{\psi} \left(\frac{\bar{C}}{\bar{L}}\right)^{-1} W}
\end{align*}

Then, it is straigforward to compute the remaining steady state values, i.e.
\begin{align*}
\bar{C} = \frac{\bar{C}}{\bar{L}}\bar{L},\qquad
\bar{I} = \frac{\bar{I}}{\bar{L}}\bar{L},\qquad
\bar{K} = \frac{\bar{K}}{\bar{L}}\bar{L},	\qquad	
\bar{Y} = \frac{\bar{Y}}{\bar{L}}\bar{L}
\end{align*}

### CES-utility
The steady state for labor changes to
\begin{align*}
W \gamma C^{-\eta_C} &= \psi(1-L)^{-\eta_L}\\\\\\
W  \left(\frac{C}{L}\right)^{-\eta_C} &= \frac{\psi}{\gamma}(1-L)^{-\eta_L}L^{\eta_C}
\end{align*}
This cannot be solved for $L$ in closed-form. Rather, we need to condition on the values of the parameters and use an numerical optimizer to solve for $L$.

## Dynare implementation
Note that I define local variables for marginal utility of current consumption `#UC`, marginal utility of future consumption `#UCp` and marginal utility of current labor `#UL`. These are text-substituted by the macro preprocessor in the equations of the model block only.
### Log-utility
```matlab
var Y C K L A R W I;
varexo eps_A;
parameters alph betta delt gam pssi rhoA;

alph = 0.35; betta = 0.99; delt = 0.025; gam = 1; pssi = 1.6; rhoA = 0.9;

model;
    #UC  = gam*C^(-1);
    #UCp = gam*C(+1)^(-1);
    #UL  = -pssi*(1-L)^(-1);
    UC = betta*UCp*(1-delt+R(+1));
    W = -UL/UC;
    K = (1-delt)*K(-1)+I;
    Y = I+C;
    Y = A*K(-1)^alph*L^(1-alph);
    W = (1-alph)*Y/L;
    R = alph*Y/K(-1);
    log(A) = rhoA*log(A(-1))+eps_A;
end;
```

### CES-utility
```matlab
var Y C K L A R W I;
varexo eps_A;
parameters alph betta delt gam pssi rhoA etaC etaL;

alph = 0.35; betta = 0.99; delt = 0.025; gam = 1; pssi = 1.6; rhoA = 0.9;
etaC  = 2;   etaL  = 1.5;

model;
    #UC  = gam*C^(-etaC);
    #UCp = gam*C(+1)^(-etaC);
    #UL  = -pssi*(1-L)^(-etaL);
    UC = betta*UCp*(1-delt+R(+1));
    W = -UL/UC;
    K = (1-delt)*K(-1)+I;
    Y = I+C;
    Y = A*K(-1)^alph*L^(1-alph);
    W = (1-alph)*Y/L;
    R = alph*Y/K(-1);
    log(A) = rhoA*log(A(-1))+eps_A;
end;
```
