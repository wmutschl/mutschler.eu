---
title: 'RBC model: deriving model equations and introduction to Dynare''s preprocessor'
#linktitle: 'RBC model: deriving model equations and introduction to Dynare''s preprocessor'
summary: In this video we derive the baseline Real Business Cycle (RBC) model with leisure and its implementation in Dynare. It also overviews and introduces basic features of Dynare's preprocessor like workspace variables, global structures, dynamic vs. static model equations, Latex capabilities and model local variables.
#date: "2021-08-18"
type: book
draft: false
toc: true
weight: 10
---

***Please feel free to raise any comments or issues on the [website's Github repository](https://github.com/wmutschl/mutschler.eu). Pull requests are very much appreciated.***

{{< youtube ZfsKGzR84hQ >}}

## Description
This video is part of a series of videos on the baseline Real Business Cycle model and its implementation in Dynare. It also overviews and introduces basic features of Dynare's preprocessor like workspace variables, global structures, dynamic vs. static model equations, Latex capabilities and model local variables.

## Timestamps

*Theory Part 1: Model Structure*
- 0:01:01 - Overview
- 0:03:48 - Representative Household
- 0:07:10 - Capital Accumulation
- 0:08:29 - Representative Firm
- 0:10:48 - Stochastic Processes
- 0:11:29 - Closing Conditions: Non-Negativity, Market Clearing, Transversality Condition

*Theory Part 2: Optimality Conditions of Household*
- 0:15:37 - Lagrangian
- 0:18:02 - Derivation of First-Order Conditions (Pen&Paper)
- 0:22:32 - Interpretation of First-Order Conditions

*Theory Part 3: Optimality Conditions of Firm*
- 0:24:38 - Lagrangian
- 0:26:09 - Derivation of First-Order Conditions
- 0:28:23 - Interpretation of First-Order Conditions

*Theory Part 4: Nonlinear Model Equations*
- 0:29:32 - Summary of model

*Dynare Part 1: Implementation and Tips*
- 0:30:24 - Creating and Working with MOD files
- 0:32:07 - Declaring variables and parameters, difference between Dynare code blocks and MATLAB code
- 0:36:03 - Entering model equations in model block
- 0:37:54 - running Dynare, addpath, dealing with preprocessor error message

*Dynare Part 2: Preprocessor*
- 0:40:14 - Overview preprocessor, workspace, global structures, files, folders, driver.m
- 0:44:28 - Preprocessor dynamic vs. static model files
- 0:46:37 - Latex features
- 0:51:50 - Preprocessor conditional if statements, savemacro

*Outro & References*
- 1:00:32 - Outro
- 1:01:36 - References


## Slides and notes
- [Presentation](/files/intro-dsge-dynare/rbc_model_equations_presentation.pdf)
- [Notes](/files/intro-dsge-dynare/rbc_model_equations_notes.pdf)

## Codes

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
  @#if LOGUTILITY == 0
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

% intertemporal optimality (Euler)
uc = BETA*ucp*(1-DELTA+r(+1));
% labor supply
w = -ul/uc;
% capital accumulation
k = (1-DELTA)*k(-1) + iv;
% market clearing
y = c + iv;
% production function
y = a*k(-1)^ALPHA*l^(1-ALPHA);
% marginal costs
mc = 1;
% labor demand
w = mc*fl;
% capital demand
r = mc*fk;
% total factor productivity
log(a) = RHOA*log(a(-1)) + epsa;
end;


write_latex_definitions;
write_latex_parameter_table;
write_latex_original_model;
write_latex_dynamic_model;
write_latex_static_model;
collect_latex_files;

if system(['pdflatex -halt-on-error -interaction=batchmode ' M_.fname '_TeX_binder.tex'])
    warning('TeX-File did not compile; you need to compile it manually')
end
```