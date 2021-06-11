---
title: RBC Baseline Model in Dynare - Deterministic vs Stochastic Simulations
linktitle: RBC Video Simulations
toc: true
type: book
date: "2021-06-10T00:00:00+01:00"
draft: false
math: true

# Prev/next pager order (if `docs_section_pager` enabled in `params.toml`)
weight: 4
---

```md
{{< youtube KHTEZiw9ukU >}}
```
This page contains the material I used in the video.

***Please feel free to raise any comments or issues on the [website's Github repository](https://github.com/wmutschl/website-academic). Pull requests are very much appreciated.***

## Slides
[Presentation](/files/rbc_videos/rbc_simulation_presentation.pdf)

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

## Did you find this page helpful? Consider sharing it 🙌
