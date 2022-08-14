---
title: 'RBC model: deterministic vs stochastic simulations'
#linkttitle: 'RBC model: deterministic vs stochastic simulations'
summary: 'In this video I focus on simulations and discuss the difference between the deterministic and stochastic model framework of Dynare. I provide intuition how Dynare "solves" or "simulates" these different model frameworks and guidance on when to run either deterministic or stochastic simulations. Then I show how to simulate various scenarios in the baseline RBC model. In the **deterministic** case (i.e. under perfect foresight), this videos covers (i) unexpected or pre-announced temporary shocks, (ii) unexpected or pre-announced permanent shocks, (iii) return to equilibrium
by using Dynare''s *perfect_foresight_setup* and *perfect_foresight_solver* (i.e. the old *simul*) commands and the *shocks*, *initval*, *endval* and *histval* blocks. I show what happens in MATLAB''s workspace and to Dynare''s output structure *oo_*. In the **stochastic** case, this videos covers (i) impulse-response-functions (irf), (ii) variance decompositions, (iii) theoretical vs. simulated moments, (iv) data simulation by using Dynare''s *stoch_simul* command and the *shocks* block. I show what happens in MATLAB''s workspace and to Dynare''s output structures *oo_* and *oo_.dr*. Lastly, the difference between Dynare''s *declaration* and *DR* (decision-rule) ordering of variables is covered.'
#date: "2021-08-18"
type: book
draft: false
toc: true
weight: 40
---
***Please feel free to raise any comments or issues on the [website's Github repository](https://github.com/wmutschl/mutschler.eu). Pull requests are very much appreciated.***

{{< youtube KHTEZiw9ukU >}}

## Description
This video is part of a series of videos on the baseline Real Business Cycle model and its implementation in Dynare. In this video I focus on simulations and discuss the difference between the deterministic and stochastic model framework of Dynare. I provide intuition how Dynare "solves" or "simulates" these different model frameworks and guidance on when to run either deterministic or stochastic simulations. Then I show how to simulate various scenarios in the baseline RBC model. 

In the **deterministic** case (i.e. under perfect foresight), this videos covers
- unexpected or pre-announced temporary shocks
- unexpected or pre-announced permanent shocks
- return to equilibrium
by using Dynare's *perfect_foresight_setup* and *perfect_foresight_solver* (i.e. the old *simul*) commands and the *shocks*, *initval*, *endval* and *histval* blocks. I show what happens in MATLAB's workspace and to Dynare's output structure *oo_*.

In the **stochastic** case, this videos covers
- impulse-response-functions (irf)
- variance decompositions
- theoretical vs. simulated moments
- data simulation
by using Dynare's *stoch_simul* command and the *shocks* block. I show what happens in MATLAB's workspace and to Dynare's output structures *oo_* and *oo_.dr*. Lastly, the difference between Dynare's *declaration* and *DR* (decision-rule) ordering of variables is covered.


## Timestamps

*Theory*
- 01:06 - Deterministic vs. stochastic model framework
- 08:01 - When to use which framework?

*Deterministic Simulation in Dynare*
- 11:47 - Overview of Dynare commands for deterministic simulations
- 13:58 - Getting ready in Dynare
- 15:00 - Scenario 1: Unexpected temporary TFP shock
- 15:25 - What does *perfect_foresight_setup* do?
- 17:39 - What does *perfect_foresight_solver* do?
- 19:12 - What happens in MATLAB's workspace?
- 19:54 - What happens in Dynare's output structure *oo_*?
- 21:43 - *Simulated_time_series* is a *dseries* object
- 22:51 - Scenario 2: Sequence of temporary pre-announced shocks
- 24:56 - Why *simul* is a depreciated syntax; better use *perfect_foresight_setup* and *perfect_foresight_solver*!
- 26:20 - *dsample* command
- 27:14 - Scenario 3: Unexpected permanent shock
- 28:47 - Values of 0 can cause errors as log(0) is inf; double check your *initval* and *endval* blocks!
- 30:45 - Don't forget to adjust steady-state computations to be dependent on value of exogenous variables (if they are different than 0)
- 32:27 - Scenario 4: Pre-announced permanent shock
- 34:07 - Scenario 5: Return to Equilibrium

*Stochastic Simulation in Dynare*
- 36:26 - Overview of Dynare commands for stochastic simulations
- 38:28 - Impulse-Response-Function (IRF) of TFP shock
- 39:39 - Adding a preference shock to the model
- 41:38 - Impulse-Response-Function (IRF) of preference shock
- 42:08 - What happens in MATLAB's console?
- 42:35 - Theoretical moments with *periods=0* option
- 43:06 - What happens in Dynare's *oo_* structure 
- 43:51 - What happens in Dynare's *oo_.dr* structure
- 44:53 - Difference between declaration and DR (decision rule) order
- 46:07 - Simulate data and simulated moments with *periods* option

*Outro & References*
- 47:01 - Outro
- 47:52 - References

## Slides
[Presentation](/files/intro-dsge-dynare/rbc_simulation_presentation.pdf)

## Codes

### rbc_steady_state_helper.m
```MATLAB
function l = rbc_steady_state_helper(L0, w,C_L,ETAC,ETAL,PSI,GAMMA)
    options = optimset('Display','off','TolX',1e-10,'TolFun',1e-10);
    l = fsolve(@(l) w*C_L^(-ETAC) - PSI/GAMMA*(1-l)^(-ETAL)*l^ETAC , L0,options);
end
```

### rbc_nonlinear_common.inc
```MATLAB
@#define LOGUTILITY = 0

var
  y     ${Y}$        (long_name='output')
  c     ${C}$        (long_name='consumption')
  k     ${K}$        (long_name='capital')
  l     ${L}$        (long_name='labor')
  a     ${A}$        (long_name='productivity')
  r     ${R}$        (long_name='interest Rate')
  w     ${W}$        (long_name='wage')
  iv    ${I}$        (long_name='investment')
  mc    ${MC}$       (long_name='marginal Costs')
;

model_local_variable
  uc    ${U_t^C}$
  ucp   ${E_t U_{t+1}^C}$
  ul    ${U_t^L}$
  fk    ${f_t^K}$
  fl    ${f_t^L}$
;

varexo
  epsa  ${\varepsilon^A}$   (long_name='Productivity Shock')
;

parameters
  BETA  ${\beta}$  (long_name='Discount Factor')
  DELTA ${\delta}$ (long_name='Depreciation Rate')
  GAMMA ${\gamma}$ (long_name='Consumption Utility Weight')
  PSI   ${\psi}$   (long_name='Labor Disutility Weight')
  @#if LOGUTILITY != 1
  ETAC  ${\eta^C}$ (long_name='Risk Aversion')
  ETAL  ${\eta^L}$ (long_name='Inverse Frisch Elasticity')
  @#endif
  ALPHA ${\alpha}$ (long_name='Output Elasticity of Capital')
  RHOA  ${\rho^A}$ (long_name='Discount Factor')
;



% Parameter calibration
ALPHA = 0.35;
BETA  = 0.99;
DELTA = 0.025;
GAMMA = 1;
PSI   = 1.6;
RHOA  = 0.9;
@#if LOGUTILITY == 0
ETAC  = 2;
ETAL  = 1;
@#endif



model;
%marginal utility of consumption and labor
@#if LOGUTILITY == 1
  #uc  = GAMMA*c^(-1);
  #ucp  = GAMMA*c(+1)^(-1);
  #ul = -PSI*(1-l)^(-1);
@#else
  #uc  = GAMMA*c^(-ETAC);
  #ucp  = GAMMA*c(+1)^(-ETAC);
  #ul = -PSI*(1-l)^(-ETAL);
@#endif

%marginal products of production
#fk = ALPHA*y/k(-1);
#fl = (1-ALPHA)*y/l;

[name='intertemporal optimality (Euler)']
uc = BETA*ucp*(1-DELTA+r(+1));
[name='labor supply']
w = -ul/uc;
[name='capital accumulation']
k = (1-DELTA)*k(-1) + iv;
[name='market clearing']
y = c + iv;
[name='production function']
y = a*k(-1)^ALPHA*l^(1-ALPHA);
[name='marginal costs']
mc = 1;
[name='labor demand']
w = mc*fl;
[name='capital demand']
r = mc*fk;
[name='total factor productivity']
log(a) = RHOA*log(a(-1)) + epsa;
end;


% ------------------------ %
% Steady State Computation %
% ------------------------ %
steady_state_model;

a = exp(epsa/(1-RHOA));
mc = 1;
r = 1/BETA + DELTA -1;
K_L = (mc*ALPHA*a/r)^(1/(1-ALPHA));
w = mc*(1-ALPHA)*a*K_L^ALPHA;
IV_L = DELTA*K_L;
Y_L = a*(K_L)^ALPHA;
C_L = Y_L - IV_L;
@#if LOGUTILITY==1
  l = GAMMA/PSI*C_L^(-1)*w/(1+GAMMA/PSI*C_L^(-1)*w);
@#else
  L0 = 1/3;
  l = rbc_steady_state_helper(L0, w,C_L,ETAC,ETAL,PSI,GAMMA);
@#endif
c  = C_L*l;
y  = Y_L*l;
iv = IV_L*l;
k  = K_L*l;

end;
```


### rbc_nonlinear_common1.inc

```MATLAB
@#define LOGUTILITY = 0

var
  y     ${Y}$        (long_name='output')
  c     ${C}$        (long_name='consumption')
  k     ${K}$        (long_name='capital')
  l     ${L}$        (long_name='labor')
  a     ${A}$        (long_name='productivity')
  r     ${R}$        (long_name='interest Rate')
  w     ${W}$        (long_name='wage')
  iv    ${I}$        (long_name='investment')
  mc    ${MC}$       (long_name='marginal Costs')
  z
;

model_local_variable
  uc    ${U_t^C}$
  ucp   ${E_t U_{t+1}^C}$
  ul    ${U_t^L}$
  fk    ${f_t^K}$
  fl    ${f_t^L}$
;

varexo
  epsa  ${\varepsilon^A}$   (long_name='Productivity Shock')
  epsz
;

parameters
  BETA  ${\beta}$  (long_name='Discount Factor')
  DELTA ${\delta}$ (long_name='Depreciation Rate')
  GAMMA ${\gamma}$ (long_name='Consumption Utility Weight')
  PSI   ${\psi}$   (long_name='Labor Disutility Weight')
  @#if LOGUTILITY != 1
  ETAC  ${\eta^C}$ (long_name='Risk Aversion')
  ETAL  ${\eta^L}$ (long_name='Inverse Frisch Elasticity')
  @#endif
  ALPHA ${\alpha}$ (long_name='Output Elasticity of Capital')
  RHOA  ${\rho^A}$ (long_name='Discount Factor')
  RHOZ
;



% Parameter calibration
ALPHA = 0.35;
BETA  = 0.99;
DELTA = 0.025;
GAMMA = 1;
PSI   = 1.6;
RHOA  = 0.9;
@#if LOGUTILITY == 0
ETAC  = 2;
ETAL  = 1;
@#endif
RHOZ=0.5;


model;
%marginal utility of consumption and labor
@#if LOGUTILITY == 1
  #uc  = z*GAMMA*c^(-1);
  #ucp  = z(+1)*GAMMA*c(+1)^(-1);
  #ul = -z*PSI*(1-l)^(-1);
@#else
  #uc  = z*GAMMA*c^(-ETAC);
  #ucp  = z(+1)*GAMMA*c(+1)^(-ETAC);
  #ul = -z*PSI*(1-l)^(-ETAL);
@#endif

%marginal products of production
#fk = ALPHA*y/k(-1);
#fl = (1-ALPHA)*y/l;

[name='intertemporal optimality (Euler)']
uc = BETA*ucp*(1-DELTA+r(+1));
[name='labor supply']
w = -ul/uc;
[name='capital accumulation']
k = (1-DELTA)*k(-1) + iv;
[name='market clearing']
y = c + iv;
[name='production function']
y = a*k(-1)^ALPHA*l^(1-ALPHA);
[name='marginal costs']
mc = 1;
[name='labor demand']
w = mc*fl;
[name='capital demand']
r = mc*fk;
[name='total factor productivity']
log(a) = RHOA*log(a(-1)) + epsa;
log(z) = RHOZ*log(z(-1)) + epsz;
end;


% ------------------------ %
% Steady State Computation %
% ------------------------ %
steady_state_model;
z=1;
a = exp(epsa/(1-RHOA));
mc = 1;
r = 1/BETA + DELTA -1;
K_L = (mc*ALPHA*a/r)^(1/(1-ALPHA));
w = mc*(1-ALPHA)*a*K_L^ALPHA;
IV_L = DELTA*K_L;
Y_L = a*(K_L)^ALPHA;
C_L = Y_L - IV_L;
@#if LOGUTILITY==1
  l = GAMMA/PSI*C_L^(-1)*w/(1+GAMMA/PSI*C_L^(-1)*w);
@#else
  L0 = 1/3;
  l = rbc_steady_state_helper(L0, w,C_L,ETAC,ETAL,PSI,GAMMA);
@#endif
c  = C_L*l;
y  = Y_L*l;
iv = IV_L*l;
k  = K_L*l;

end;
```


### rbc_nonlinear_det1.mod
```MATLAB
@#include "rbc_nonlinear_common.inc"
steady;

% -------------------- %
% Unexpected TFP shock %
% -------------------- %

shocks;
var epsa; periods 1; values -0.1;
end;

% % make sure everything is set up correctly!
% perfect_foresight_setup(periods=4);
% oo_.exo_simul
% oo_.endo_simul

perfect_foresight_setup(periods=300);
perfect_foresight_solver;

rplot c iv y;
rplot l w;
rplot r;
rplot k;
rplot a;
```

### rbc_nonlinear_det2.mod
```MATLAB
@#include "rbc_nonlinear_common.inc"
steady;

% ----------------------- %
% Pre-announced TFP shock %
% ----------------------- %
shocks;
var epsa; 
periods    4,  5:8; 
values  0.04, 0.01;
end;

% % make sure everything is set up correctly!
% perfect_foresight_setup(periods=8);
% oo_.exo_simul
% oo_.endo_simul

perfect_foresight_setup(periods=300);
perfect_foresight_solver;

dsample 100;
rplot c iv y;
rplot l w;
rplot r;
rplot k;
rplot a;
```

### rbc_nonlinear_det3.mod
```MATLAB
@#include "rbc_nonlinear_common.inc"

% ------------------------------------------------ %
% Permanent shock: TFP increases permanently by 5% %
% ------------------------------------------------ %
initval;
epsa=0;
end;
steady;

endval;
epsa = (1-RHOA)*log(1.05);
end;
steady;


% make sure everything is set up correctly!
% perfect_foresight_setup(periods=8);
% oo_.exo_simul
% oo_.endo_simul

perfect_foresight_setup(periods=300);
perfect_foresight_solver;
dsample 100;
rplot c iv y;
rplot l w;
rplot r;
rplot k;
rplot a;
```


### rbc_nonlinear_det4.mod
```MATLAB
@#include "rbc_nonlinear_common.inc"

% -------------------------------------------------------------- %
% Pre-announced permanent shock: TFP increases permanently by 5% %
% -------------------------------------------------------------- %
initval;
epsa=0;
end;
steady;

endval;
epsa = (1-RHOA)*log(1.05);
end;
steady;

shocks;
var epsa; periods 1:5; values 0;
end;


% make sure everything is set up correctly!
% perfect_foresight_setup(periods=8);
% oo_.exo_simul
% oo_.endo_simul

perfect_foresight_setup(periods=300);
perfect_foresight_solver;
dsample 100;
rplot c iv y;
rplot l w;
rplot r;
rplot k;
rplot a;
```

### rbc_nonlinear_det5.mod
```MATLAB
@#include "rbc_nonlinear_common.inc"
steady;
% ---------------------- %
% Return to Equilibrium %
% ---------------------- %
histval;
k(0)=10;
a(0)=1;
end;

% make sure everything is set up correctly!
% perfect_foresight_setup(periods=4);
% oo_.exo_simul
% oo_.endo_simul

perfect_foresight_setup(periods=300);
perfect_foresight_solver;
dsample 100;
rplot c iv y;
rplot l w;
rplot r;
rplot k;
rplot a;
```

### rbc_nonlinear_stoch1.mod
```MATLAB
@#include "rbc_nonlinear_common.inc"
steady;

% -------------------- %
% Unexpected TFP shock %
% -------------------- %

shocks;
var epsa = 0.04^2;
end;

stoch_simul(order=1,irf=30,periods=0) y c iv a;
```

### rbc_nonlinear_stoch2.mod
```MATLAB
@#include "rbc_nonlinear_common1.inc"
steady;

% -------------------------------- %
% Unexpected TFP shock             %
% Unexpected discount factor shock %
% -------------------------------- %

shocks;
var epsa = 0.04^2;
var epsz = 0.01^2;
end;

stoch_simul(order=1,irf=0,periods=300) y c iv a z;
```
