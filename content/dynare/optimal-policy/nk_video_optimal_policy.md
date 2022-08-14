---
title: Optimal policy in the New Keynesian Baseline model with Dynare
#linktitle: Optimal policy in the New Keynesian Baseline model with Dynare
summary: In this video I focus on Optimal Policy in the baseline New Keynesian model and discuss concepts like the Divine Coincidence, Indeterminacy, Taylor Principle, Optimal Policy under Commitment, Optimal Policy under Discretion, Simple Implementable Rules and how to compare different policy regimes. Even though this video provides some insight on the theory behind these concepts, I try to not get caught up in the details, but focus mainly on the implementation aspects in Dynare.
toc: true
type: book
#date: "2021-08-19"
draft: false
weight: 10
---

***Please feel free to raise any comments or issues on the [website's Github repository](https://github.com/wmutschl/mutschler.eu). Pull requests are very much appreciated.***

{{< youtube SH7J74-zsRY >}}

## Description
In this video I focus on Optimal Policy in the baseline New Keynesian model and discuss concepts like the Divine Coincidence, Indeterminacy, Taylor Principle, Optimal Policy under Commitment, Optimal Policy under Discretion, Simple Implementable Rules and how to compare different policy regimes. Even though this video provides some insight on the theory behind these concepts, I try to not get caught up in the details, but focus mainly on the implementation aspects in Dynare.

## Timestamps

*Optimal Policy in Baseline New Keynesian Model*
- 01:42 - Why are DSGE models useful to think about optimal policy?
- 02:43 - Two sources of distortions in canonical New Keynesian Model
- 05:05 - Definitions: Efficient vs natural output
- 05:59 - Characterization of Optimal Policy
- 08:16 - Divine Coincidence

*Implementing Optimal Policy in Baseline New Keynesian Model with simple rules*
- 09:36 - Exogenous one-for-one rule yields indeterminacy
- 10:30 - Dynare Implementation: Setting up optimal rules
- 12:46 - Dynare Implementation: One-For-One rule with indeterminacy
- 13:52 - Optimal rule with feedback to target variables
- 14:20 - Taylor Principle
- 15:05 - Dynare Implementation: Optimal simple rule with feedback to target variables
- 17:37 Dynare Implementation: Visualizing Taylor principle determinacy region using dynare_sensitivity
- 22:15 - Summary Optimal Simple Rules and Divine Coincidence

*Policy Trade-Offs and Breaking Divine Coincidence*
- 22:46 - Policy Trade-Offs, Commitment vs Discretion
- 24:55 - Farewell Divine Coincidence: combining real frictions with nominal rigidities
- 25:48 - Adding cost-push shock to Basic New Keynesian Model
- 28:18 - Ramsey Optimal Policy

*Optimal Policy Under Commitment*
- 30:12 - Theory
- 31:11 - Dynare Commands
- 34:59 - Dynare Implementation: Adding cost-push shock to baseline New Keynesian Model
- 37:46 - Dynare Implementation: Prepare optimal Policy under Commitment
- 38:01 - Dynare Implementation: Response to transitory cost-push shock
- 38:27 - Dynare Implementation: planner_objective
- 38:55 - Dynare Implementation: update Parameters of objective function in steady_state model
- 39:36 - Dynare Implementation: ramsey_model
- 39:59 - Dynare Implementation: evaluate_planner_objective
- 40:33 - Dynare Implementation: Response to persistent cost-push shock under commitment

*Optimal Policy Under Discretion*
- 41:04 - Theory
- 42:34 - Dynare Commands
- 42:48 - Linear-Quadratic Problem
- 43:26 - Dynare Implementation: Response to transitory cost-push shock under discretion
- 43:46 - Dynare Implementation: planner_objective
- 43:51 - Dynare Implementation: discretionary_policy
- 44:23 - Dynare Implementation: Response to persistent cost-push shock under discretion

*Comparison of Optimal Policy*
- 44:37 - Comparing responses to cost-push shock under Commitment and Discretion

*Simple Implementable Rules*
- 47:57 - How to communicate optimal rules or optimal policy?
- 49:03 - Simple Implementable Rules
- 49:58 - Comparing Policy Regimes: Conditional Welfare, Unconditional Welfare Mean, Loss function
- 51:28 - Steady-State Consumption Equivalent

*Optimal Simple Implementable Rules*
- 52:51 - Theory
- 53:34 - Dynare Command osr
- 55:04 - Dynare Implementation: computing optimal simple rules that minimize variance of inflation and output gap

*Outro & References*
- 56:51 - Outro
- 56:56 - References



## Slides
[Presentation](/files/optimal-policy/nk_optimal_policy_presentation.pdf)

## Codes

### NK_linear_common.inc
```MATLAB
/*
 * Copyright (C) 2016-2021 Johannes Pfeifer
 * Copyright (C) 2021 Willi Mutschler
 *
 * This is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * It is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * For a copy of the GNU General Public License,
 * see <http://www.gnu.org/licenses/>.
 */

var
  a           ${a}$                   (long_name='technology shock process (log dev ss)')
  z           ${z}$                   (long_name='preference shock process (log dev ss)')
  c           ${c}$                   (long_name='consumption (log dev ss)')
  y           ${y}$                   (long_name='output (log dev ss)')
  y_nat       ${y^{nat}}$             (long_name='natural output (log dev ss)')
  y_gap       ${\tilde y}$            (long_name='output gap (log dev ss)')
  r_nat       ${r^{nat}}$             (long_name='natural interest rate (log dev ss)')
  r_real      ${r}$                   (long_name='real interest rate (log dev ss)')     
  ii          ${i}$                   (long_name='nominal interest rate (log dev ss)')  
  pie         ${\pi}$                 (long_name='inflation (log dev ss)')
  n           ${n}$                   (long_name='hours worked (log dev ss)')
  w           ${w}$                   (long_name='real wage (log dev ss)')
;     


varexo  
  eps_a       ${\varepsilon_a}$       (long_name='technology shock')
  eps_z       ${\varepsilon_z}$       (long_name='preference shock')
;

parameters 
  ALPHA      ${\alpha}$              (long_name='one minus labor share in production')
  BETA       ${\beta}$               (long_name='discount factor')
  RHOA       ${\rho_a}$              (long_name='autocorrelation technology process')
  RHOZ       ${\rho_{z}}$            (long_name='autocorrelation preference process')
  SIGMA      ${\sigma}$              (long_name='inverse EIS')
  VARPHI     ${\varphi}$             (long_name='inverse Frisch elasticity')
  EPSILON    ${\epsilon}$            (long_name='Dixit-Stiglitz demand elasticity')
  THETA      ${\theta}$              (long_name='Calvo probability')
  @#if MONPOL != 1
  PHI_PIE    ${\phi_{\pi}}$          (long_name='inflation feedback Taylor Rule')
  PHI_Y      ${\phi_{y}}$            (long_name='output feedback Taylor Rule')
  @#endif
;

model(linear); 
//Composite parameters
#OMEGA=(1-ALPHA)/(1-ALPHA+ALPHA*EPSILON);
#PSI_YA=(1+VARPHI)/(SIGMA*(1-ALPHA)+VARPHI+ALPHA);
#LAMBDA=(1-THETA)*(1-BETA*THETA)/THETA*OMEGA;
#KAPPA=LAMBDA*(SIGMA+(VARPHI+ALPHA)/(1-ALPHA));

[name='New Keynesian Phillips Curve']
pie=BETA*pie(+1)+KAPPA*y_gap;

[name='Dynamic IS Curve']
y_gap=-1/SIGMA*(ii-pie(+1)-r_nat)+y_gap(+1);

[name='Production function']
y=a+(1-ALPHA)*n;

[name='labor demand']
w = SIGMA*c+VARPHI*n;

[name='resource constraint']
y=c;

[name='TFP process']
a=RHOA*a(-1)+eps_a;

[name='Preference shifter']
z = RHOZ*z(-1) + eps_z;

[name='Definition natural rate of interest']
r_nat=-SIGMA*PSI_YA*(1-RHOA)*a+(1-RHOZ)*z;

[name='Definition real interest rate']
r_real=ii-pie(+1);

[name='Definition natural output']
y_nat=PSI_YA*a;

[name='Definition output gap']
y_gap=y-y_nat;

@#if MONPOL == 1
[name='Interest Rate Rule: Exogenous One-To-One']
ii = r_nat;
@#elseif MONPOL == 2
ii = r_nat + PHI_PIE*pie+PHI_Y*y_gap;
@#else
ii = PHI_PIE*pie+PHI_Y*y;
@#endif

end;

shocks;
    var eps_z  = 1;
    var eps_a  = 1;
end;
```

### NK_linear_optimal_rule1.mod
```MATLAB
% -------------------------- %
% Exogenous one-for-one rule %
% -------------------------- %
@#define MONPOL = 1
@#include "NK_linear_common.inc"

SIGMA   = 1;
VARPHI  = 5;
THETA   = 3/4;
RHOZ    = 0.5;
RHOA    = 0.9;
BETA    = 0.99;
ALPHA   = 1/4;
EPSILON = 9;

steady;
check;

%stoch_simul(order = 1,irf=30);
```

### NK_linear_optimal_rule2.mod
```MATLAB
% ---------------------------------------------- %
% optimal rule with feedback to target variables %
% ---------------------------------------------- %
@#define MONPOL = 2
@#include "NK_linear_common.inc"

SIGMA   = 1;
VARPHI  = 5;
THETA   = 3/4;
RHOZ    = 0.5;
RHOA    = 0.9;
BETA    = 0.99;
ALPHA   = 1/4;
EPSILON = 9;

PHI_PIE = 1.5;
PHI_Y   = 0.125;

steady;
check;

stoch_simul(order=1,irf=30);

estimated_params;
PHI_PIE, 1.5, 0, 2;
PHI_Y, 0.125, 0, 2;
end;

varobs a  z  c  y  y_nat  y_gap  r_nat  r_real  ii  pie  n  w; % dynare_sensitivity requires varobs block
                                                               % alternative and quick way to assume all variables are observbable:
                                                               % options_.varobs = M_.endo_names; 
dynare_sensitivity;
```

### NK_linear_costpush_common.inc
```MATLAB
/*
 * Copyright (C) 2016-2021 Johannes Pfeifer
 * Copyright (C) 2021 Willi Mutschler
 *
 * This is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * It is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * For a copy of the GNU General Public License,
 * see <http://www.gnu.org/licenses/>.
 */

var
  a           ${a}$                   (long_name='technology shock process (log dev ss)')
  z           ${z}$                   (long_name='preference shock process (log dev ss)')
  c           ${c}$                   (long_name='consumption (log dev ss)')
  y           ${y}$                   (long_name='output (log dev ss)')
  y_nat       ${y^{nat}}$             (long_name='natural output (log dev ss)')
  y_gap       ${\tilde y}$            (long_name='output gap (log dev ss)')
  y_e         ${y^{e}}$               (long_name='efficient output (log dev steady state)') 
  x           ${x}$                   (long_name='welfare-relevant output gap (log dev steady state)')
  r_e         ${r^{e}}$               (long_name='efficient interest rate (log dev ss)')
  r_real      ${r}$                   (long_name='real interest rate (log dev ss)')     
  ii          ${i}$                   (long_name='nominal interest rate (log dev ss)')  
  pie         ${\pi}$                 (long_name='inflation (log dev ss)')
  n           ${n}$                   (long_name='hours worked (log dev ss)')
  w           ${w}$                   (long_name='real wage (log dev ss)')
  u           ${u}$                   (long_name='cost push process (log dev steady state)')
;     

varexo  
  eps_a       ${\varepsilon_a}$       (long_name='technology shock')
  eps_z       ${\varepsilon_z}$       (long_name='preference shock')
  eps_u       ${\varepsilon_u}$       (long_name='cost-push shock')
;

parameters 
  ALPHA      ${\alpha}$              (long_name='one minus labor share in production')
  BETA       ${\beta}$               (long_name='discount factor')
  RHOA       ${\rho_a}$              (long_name='autocorrelation technology process')
  RHOZ       ${\rho_{z}}$            (long_name='autocorrelation preference process')
  RHOU       ${\rho_{u}}$            (long_name='autocorrelation cost-push process')
  SIGMA      ${\sigma}$              (long_name='inverse EIS')
  VARPHI     ${\varphi}$             (long_name='inverse Frisch elasticity')
  EPSILON    ${\epsilon}$            (long_name='Dixit-Stiglitz demand elasticity')
  THETA      ${\theta}$              (long_name='Calvo probability')  
  KAPPA      ${\kappa}$              (long_name='Composite parameter Phillips curve')
  VARTHETA   ${\vartheta}$           (long_name='weight of x in loss function')
;

model(linear); 
//Composite parameters
#PSI_YA=(1+VARPHI)/(SIGMA*(1-ALPHA)+VARPHI+ALPHA);

[name='New Keynesian Phillips Curve']
pie=BETA*pie(+1)+KAPPA*x + u;

[name='Dynamic IS Curve']
x = x(+1) - 1/SIGMA*(ii-pie(+1)-r_e);

[name='Production function']
y=a+(1-ALPHA)*n;

[name='labor demand']
w = SIGMA*c+VARPHI*n;

[name='resource constraint']
y=c;

[name='TFP process']
a=RHOA*a(-1)+eps_a;

[name='Preference shifter']
z = RHOZ*z(-1) + eps_z;

[name='Definition efficient interest rate']
r_e=SIGMA*(y_e(+1)-y_e)+(1-RHOZ)*z;

[name='Definition real interest rate']
r_real=ii-pie(+1);

[name='Definition efficient output']
y_e=PSI_YA*a;

[name='Definition output gap']
y_gap=y-y_nat;

[name='Definition linking various output gaps']
y_gap=x+(y_e-y_nat);

[name='Implicit definition of natural output, following from definition of u']
u = KAPPA*(y_e-y_nat);

[name='cost push process']
u=RHOU*u(-1)+eps_u;

end;

steady_state_model;
% We need these parameters to evaluate loss function!
KAPPA=(1-THETA)*(1-BETA*THETA)/THETA*(1-ALPHA)/(1-ALPHA+ALPHA*EPSILON)*(SIGMA+(VARPHI+ALPHA)/(1-ALPHA));
VARTHETA=KAPPA/EPSILON;
% All other variables are zero in steady state
pie=0;y_gap=0;y_nat=0;y=0;y_e=0;x=0;ii=0;r_e=0;r_real=0;c=0;n=0;u=0;a=0;z=0;w=0;
end;
```

### NK_linear_costpush_commitment.mod
```MATLAB
@#include "NK_linear_costpush_common.inc"

shocks;
var eps_a = 0; %shut off
var eps_u = 1;
var eps_z = 0; %shut off
end;

SIGMA = 1;
VARPHI=5;
THETA=3/4;
RHOZ  = 0.5;
RHOA  = 0.9;
BETA  = 0.99;
ALPHA = 1/4;
EPSILON= 9;

@#ifndef VALUERHOU
  RHOU=0;   % Response to transitory cost-push shock under commitment
  %RHOU=0.8; % Response to persistent cost-push shock under commitment
@#else
  RHOU = @{VALUERHOU};
@#endif

planner_objective pie^2 +VARTHETA*x^2;
ramsey_model(instruments=(ii),planner_discount=BETA);
stoch_simul(order=1,irf=30) x pie u;
evaluate_planner_objective;
```

### NK_linear_costpush_discretion.mod
```MATLAB
@#include "NK_linear_costpush_common.inc"

shocks;
var eps_a = 0; %shut off
var eps_u = 1;
var eps_z = 0; %shut off
end;

SIGMA = 1;
VARPHI=5;
THETA=3/4;
RHOZ  = 0.5;
RHOA  = 0.9;
BETA  = 0.99;
ALPHA = 1/4;
EPSILON= 9;

@#ifndef VALUERHOU
  RHOU=0;   % Response to transitory cost-push shock under commitment
  %RHOU=0.8; % Response to persistent cost-push shock under commitment
@#else
  RHOU = @{VALUERHOU};
@#endif

planner_objective pie^2 +VARTHETA*x^2;
discretionary_policy(instruments=(ii),irf=30,planner_discount=BETA,discretionary_tol=1e-12) x pie u;
```

### NK_linear_costpush_osr.mod
```MATLAB
/*
 * Copyright (C) 2016-2021 Johannes Pfeifer
 * Copyright (C) 2021 Willi Mutschler
 *
 * This is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * It is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * For a copy of the GNU General Public License,
 * see <http://www.gnu.org/licenses/>.
 */
 
var
  a           ${a}$                   (long_name='technology shock process (log dev ss)')
  z           ${z}$                   (long_name='preference shock process (log dev ss)')
  c           ${c}$                   (long_name='consumption (log dev ss)')
  y           ${y}$                   (long_name='output (log dev ss)')
  y_nat       ${y^{nat}}$             (long_name='natural output (log dev ss)')
  y_gap       ${\tilde y}$            (long_name='output gap (log dev ss)')
  y_e         ${y^{e}}$               (long_name='efficient output (log dev steady state)') 
  x           ${x}$                   (long_name='welfare-relevant output gap (log dev steady state)')
  r_e         ${r^{e}}$               (long_name='efficient interest rate (log dev ss)')
  r_real      ${r}$                   (long_name='real interest rate (log dev ss)')     
  ii          ${i}$                   (long_name='nominal interest rate (log dev ss)')  
  pie         ${\pi}$                 (long_name='inflation (log dev ss)')
  n           ${n}$                   (long_name='hours worked (log dev ss)')
  w           ${w}$                   (long_name='real wage (log dev ss)')
  u           ${u}$                   (long_name='cost push process (log dev steady state)')
;     

varexo  
  eps_a       ${\varepsilon_a}$       (long_name='technology shock')
  eps_z       ${\varepsilon_z}$       (long_name='preference shock')
  eps_u       ${\varepsilon_u}$       (long_name='cost-push shock')
;

parameters 
  ALPHA      ${\alpha}$              (long_name='one minus labor share in production')
  BETA       ${\beta}$               (long_name='discount factor')
  RHOA       ${\rho_a}$              (long_name='autocorrelation technology process')
  RHOZ       ${\rho_{z}}$            (long_name='autocorrelation preference process')
  RHOU       ${\rho_{u}}$            (long_name='autocorrelation cost-push process')
  SIGMA      ${\sigma}$              (long_name='inverse EIS')
  VARPHI     ${\varphi}$             (long_name='inverse Frisch elasticity')
  EPSILON    ${\epsilon}$            (long_name='Dixit-Stiglitz demand elasticity')
  THETA      ${\theta}$              (long_name='Calvo probability')  
  PHI_PIE    ${\phi_{\pi}}$          (long_name='inflation feedback Taylor Rule')
  PHI_Y      ${\phi_{y}}$            (long_name='output feedback Taylor Rule')
;

model(linear); 
//Composite parameters
#PSI_YA=(1+VARPHI)/(SIGMA*(1-ALPHA)+VARPHI+ALPHA);
#KAPPA=(1-THETA)*(1-BETA*THETA)/THETA*(1-ALPHA)/(1-ALPHA+ALPHA*EPSILON)*(SIGMA+(VARPHI+ALPHA)/(1-ALPHA));

[name='New Keynesian Phillips Curve']
pie=BETA*pie(+1)+KAPPA*x + u;

[name='Dynamic IS Curve']
x = x(+1) - 1/SIGMA*(ii-pie(+1)-r_e);

[name='Production function']
y=a+(1-ALPHA)*n;

[name='labor demand']
w = SIGMA*c+VARPHI*n;

[name='resource constraint']
y=c;

[name='TFP process']
a=RHOA*a(-1)+eps_a;

[name='Preference shifter']
z = RHOZ*z(-1) + eps_z;

[name='Definition efficient interest rate']
r_e=SIGMA*(y_e(+1)-y_e)+(1-RHOZ)*z;

[name='Definition real interest rate']
r_real=ii-pie(+1);

[name='Definition efficient output']
y_e=PSI_YA*a;

[name='Definition output gap']
y_gap=y-y_nat;

[name='Definition linking various output gaps']
y_gap=x+(y_e-y_nat);

[name='Implicit definition of natural output, following from definition of u']
u = KAPPA*(y_e-y_nat);

[name='cost push process']
u=RHOU*u(-1)+eps_u;

[name='Interest Rate Rule']
ii = PHI_PIE*pie+PHI_Y*y;
end;

steady_state_model;
% All other variables are zero in steady state
pie=0;y_gap=0;y_nat=0;y=0;y_e=0;x=0;ii=0;r_e=0;r_real=0;c=0;n=0;u=0;a=0;z=0;w=0;
end;

shocks;
var eps_a = 0;
var eps_u = 1;
var eps_z = 0;
end;

SIGMA = 1;
VARPHI=5;
THETA=3/4;
RHOZ  = 0.5;
RHOA  = 0.9;
RHOU  = 0.5;
BETA  = 0.99;
ALPHA = 1/4;
EPSILON= 9;
PHI_PIE = 1.5;
PHI_Y = 0.125;


optim_weights;
pie 1;
y 1;
end;

osr_params PHI_PIE PHI_Y;

osr_params_bounds;
PHI_PIE, 0, 2;
PHI_Y, 0, 2;
end;

osr(opt_algo=9,irf=30) u y y_nat y_e y_gap x pie;
oo_.osr.optim_params
```

### ComparePermanentAndTransitory.m
```MATLAB
clear all; close all; clc;

dynare NK_linear_costpush_discretion -DVALUERHOU=0
irfs_discretion_transitory = oo_.irfs;

dynare NK_linear_costpush_discretion -DVALUERHOU=0.8
irfs_discretion_persistent = oo_.irfs;

dynare NK_linear_costpush_commitment -DVALUERHOU=0
irfs_commitment_transitory = oo_.irfs;

dynare NK_linear_costpush_commitment -DVALUERHOU=0.8
irfs_commitment_persistent = oo_.irfs;

close all;
 
irf_horizon = 15;

figure
subplot(2,3,1)
plot(0:irf_horizon-1,irfs_discretion_transitory.x_eps_u(1:irf_horizon),'-o')
hold on
plot(0:irf_horizon-1,irfs_commitment_transitory.x_eps_u(1:irf_horizon),'-x')
axis tight
title('Output gap (transitory shock)')
legend({'Discretion' 'Commitment'},'Location','SouthEast')

subplot(2,3,2)
plot(0:irf_horizon-1,irfs_discretion_transitory.pie_eps_u(1:irf_horizon),'-o')
hold on
plot(0:irf_horizon-1,irfs_commitment_transitory.pie_eps_u(1:irf_horizon),'-x')
axis tight
title('Inflation (transitory shock)')
legend({'Discretion' 'Commitment'},'Location','SouthEast')
 
subplot(2,3,3)
plot(0:irf_horizon-1,irfs_discretion_transitory.u_eps_u(1:irf_horizon),'-o')
hold on
plot(0:irf_horizon-1,irfs_commitment_transitory.u_eps_u(1:irf_horizon),'-x')
axis tight
title('Cost-Push process (transitory)')
legend({'Discretion' 'Commitment'},'Location','SouthEast')

subplot(2,3,4)
plot(0:irf_horizon-1,irfs_discretion_persistent.x_eps_u(1:irf_horizon),'-o')
hold on
plot(0:irf_horizon-1,irfs_commitment_transitory.x_eps_u(1:irf_horizon),'-x')
axis tight
title('Output gap (persistent shock)')
legend({'Discretion' 'Commitment'},'Location','SouthEast')

subplot(2,3,5)
plot(0:irf_horizon-1,irfs_discretion_persistent.pie_eps_u(1:irf_horizon),'-o')
hold on
plot(0:irf_horizon-1,irfs_commitment_persistent.pie_eps_u(1:irf_horizon),'-x')
axis tight
title('Inflation (persistent shock)')
legend({'Discretion' 'Commitment'},'Location','SouthEast')
 
subplot(2,3,6)
plot(0:irf_horizon-1,irfs_discretion_persistent.u_eps_u(1:irf_horizon),'-o')
hold on
plot(0:irf_horizon-1,irfs_commitment_persistent.u_eps_u(1:irf_horizon),'-x')
axis tight
title('Cost-Push process (persistent)')
legend({'Discretion' 'Commitment'},'Location','SouthEast')
```
