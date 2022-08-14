---
title: 'RBC model: steady-state derivations and implementation in Dynare (with preprocessing tips)'
#linktitle: 'RBC model: steady-state derivations and implementation in Dynare (with preprocessing tips)'
summary: In this video we focus on computing the steady-state of the RBC model both analytically and numerically. First, we derive the steady-state using pen and paper and then implement this using either an *initval* or *steady_state_model* block in Dynare. We also cover "helper functions" that introduce numerical optimization in an otherwise analytical *steady_state_model* block, in order to compute the steady-state for variables for which we cannot derive closed-form expressions by hand.
#date: "2021-08-18"
type: book
draft: false
toc: true
weight: 20
---
***Please feel free to raise any comments or issues on the [website's Github repository](https://github.com/wmutschl/mutschler.eu. Pull requests are very much appreciated.***

{{< youtube 4xeoLh3edpo >}}

## Description
This video is part of a series of videos on the baseline Real Business Cycle model and its implementation in Dynare. We focus on computing the steady-state both analytically and numerically. First, we derive the steady-state using pen and paper and then implement this using either an *initval* or *steady_state_model* block in Dynare. We also cover "helper functions" that introduce numerical optimization in an otherwise analytical *steady_state_model* block, in order to compute the steady-state for variables for which we cannot derive closed-form expressions by hand.


## Timestamps
*Theory*
- 01:44 - What is a steady-state?
- 02:54 - Derivation of steady-state expressions using pen and paper
- 10:21 - Summary of steady-state recipe

*Dynare Implementation*
- 11:06 - Getting ready
- 13:37 - *Initval* block
- 16:20 - *steady* command
- 18:00 - Create macro variable for either *initval* or *steady_state_model* block
- 19:06 - *steady_state_model* block if you have closed-form expressions for all variables (log utility case)
- 20:22 - steady-state computation error for CES utility
- 21:04 - *steady_state_model* block if you have closed-form expressions for some but not all variables (CES utility case), using a helper function

*Dynare Preprocessor*
- 23:18 - Name tags for model equations
- 24:58 - *write_latex_steady_state_model*

*Outro & References*
- 25:54 - Outro
- 27:02 - References


## Slides and notes
- [Presentation](/files/intro-dsge-dynare/rbc_steady_state_presentation.pdf)
- [Notes](/files/intro-dsge-dynare/rbc_steady_state_notes.pdf)

## Codes

### rbc_steady_state_helper.m
```MATLAB
function l = rbc_steady_state_helper(L0, w,C_L,ETAC,ETAL,PSI,GAMMA)
    options = optimset('Display','off','TolX',1e-10,'TolFun',1e-10);
    l = fsolve(@(l) w*C_L^(-ETAC) - PSI/GAMMA*(1-l)^(-ETAL)*l^ETAC , L0,options);
end
```

### rbc_nonlinear.mod
```MATLAB
@#define LOGUTILITY = 1

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
@#define AnalyticalSteadyState = 1

@#if AnalyticalSteadyState == 1

steady_state_model;

a = 1;
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

@#else

initval;
 a = 1;
 mc = 1;
 r = 0.03;
 l = 1/3;
 y = 1.2;
 c = 0.9;
 iv = 0.35;
 k = 12;
 w = 2.25;
end;
@#endif


steady;




write_latex_definitions;
write_latex_parameter_table;
write_latex_original_model;
%write_latex_dynamic_model;
write_latex_static_model;
write_latex_steady_state_model;
collect_latex_files;

if system(['/Library/TeX/texbin/pdflatex -halt-on-error -interaction=batchmode ' M_.fname '_TeX_binder.tex'])
    warning('TeX-File did not compile; you need to compile it manually')
end
```
