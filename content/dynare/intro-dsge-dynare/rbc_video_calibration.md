---
title: 'RBC model: simple vs advanced calibration using modularization and changing types'
#linktitle: 'RBC model: simple vs advanced calibration using modularization and changing types'
summary: 'In this video I show how to calibrate the parameters of the RBC model in a sophisticated way using Dynare''s preprocessing capabilities. First, we cover some general ideas and tips how to calibrate the parameters of a DSGE model, focusing on the RBC model with leisure. Then I show how to accomplish this in Dynare either directly or, a more advanced way, by modularizing your mod file and changing the type of variables and parameters. Once you start working with large-scale models, this modularization technique will make your models much more tractable.'
#date: "2021-08-18"
type: book
draft: false
toc: true
weight: 30
---
***Please feel free to raise any comments or issues on the [website's Github repository](https://github.com/wmutschl/mutschler.eu). Pull requests are very much appreciated.***

{{< youtube HRpynlbZBzM >}}

## Description
This video is part of a series of videos on the baseline Real Business Cycle model and its implementation in Dynare. In this video I show how to calibrate the model parameters in a sophisticated way using Dynare's preprocessing capabilities. First, we cover some general ideas and tips how to calibrate the parameters of a DSGE model, focusing on the RBC model with leisure. Then I show how to accomplish this in Dynare either directly or, a more advanced way, by modularizing your mod file and changing the type of variables and parameters. Once you start working with large-scale models, this modularization technique will make your models much more tractable.

## Timestamps

*General ideas and tips*
- 02:31 - Calibration strategy
- 03:55 - Calibrating bias towards capital in production function
- 04:39 - Calibrating depreciation rate
- 05:37 - Calibrating discount factor
- 06:29 - Calibrating total factor productivity (TFP) parameters
- 07:51 - Calibrating CES utility elasticities
- 10:00 - Calibrating utility weights

*Simple (but not powerful) implementation in Dynare in parameters block*
- 10:56 - Getting ready
- 11:12 - Calibrating bias toward capital in production function
- 11:27 - Calibrating depreciation rate
- 12:26 - Calibrating total factor productivity (TFP) parameters
- 12:49 - Calibrating CES utility elasticities
- 13:11 - Calibrating utility weights
- 14:00 - Double checking calibrated values

*Advanced (and powerful) implementation in Dynare using modularization, change_type, save_params_and_steady_state*
- 14:40 - Getting ready
- 15:08 - Create separate files for symbolic declaration and model equations
- 16:43 - Create steady1 mod file which computes steady state of simplified model with some arbitrary calibration
- 20:26 - Create steady2 mod file to make ratios parameters
- 21:06 - change_type command
- 22:03 - Provide your target calibration for elasticities and ratios using set_param_value
- 22:48 - Note that load_params_and_steady_state provides initial values for numerical optimization (i.e. an implicit initval block)
- 23:28 - Create final mod file with desired calibration
- 24:21 - Recap: Modularization and change_type

*Outro & References*
- 26:26 - Outro
- 27:18 - References


## Slides
[Presentation](/files/intro-dsge-dynare/rbc_calibration_presentation.pdf)

## Codes

### rbc_nonlinear_symdecls.inc
```MATLAB
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
  @#if STEADY
  wl_y iv_y k_y
  @#endif
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
```

### rbc_nonlinear_modeqs.inc
```MATLAB
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

@#if STEADY
wl_y = w*l/y;
iv_y = iv/y;
k_y  = k(-1)/y;
@#endif    
end;
```

### rbc_nonlinear_steady1.mod
```MATLAB
@#define LOGUTILITY = 0
@#define STEADY = 1

@#include "rbc_nonlinear_symdecls.inc"
@#include "rbc_nonlinear_modeqs.inc"


% -------------------------- %
% Easiest Model: log utility %
% -------------------------- %
ALPHA = 0.33;
BETA  = 0.99;
DELTA = 0.025;
RHOA  = 0.9;
GAMMA = 1;
PSI   = 1;
ETAC  = 1;
ETAL  = 1;

steady_state_model;
a = 1;
mc = 1;
r = 1/BETA + DELTA -1;
K_L = (mc*ALPHA*a/r)^(1/(1-ALPHA));
w = mc*(1-ALPHA)*a*K_L^ALPHA;
IV_L = DELTA*K_L;
Y_L = a*(K_L)^ALPHA;
C_L = Y_L - IV_L;
l = GAMMA/PSI*C_L^(-1)*w/(1+GAMMA/PSI*C_L^(-1)*w);
c  = C_L*l;
y  = Y_L*l;
iv = IV_L*l;
k  = K_L*l;
wl_y = w*l/y;
iv_y = iv/y;
k_y = k/y;
end;

steady;
save_params_and_steady_state('rbc_nonlinear_steady1.txt');
```

### rbc_nonlinear_steady2.mod
```MATLAB
@#define LOGUTILITY = 0
@#define STEADY = 1

@#include "rbc_nonlinear_symdecls.inc"
change_type(parameters) l wl_y iv_y k_y;
change_type(var) PSI ALPHA DELTA BETA;

@#include "rbc_nonlinear_modeqs.inc"

load_params_and_steady_state('rbc_nonlinear_steady1.txt');

set_param_value('ETAC',2);
set_param_value('ETAL',1.5);

set_param_value('l',1/3);
set_param_value('wl_y',0.65);
set_param_value('iv_y',0.25);
set_param_value('k_y',10);

steady;
save_params_and_steady_state('rbc_nonlinear_steady2.txt');
```

### rbc_nonlinear_final.mod
```MATLAB
@#define LOGUTILITY = 0
@#define STEADY = 0

@#include "rbc_nonlinear_symdecls.inc"
@#include "rbc_nonlinear_modeqs.inc"

load_params_and_steady_state('rbc_nonlinear_steady2.txt');

steady;

shocks;
var epsa = 0.001;
end;

stoch_simul(order=1);
```
