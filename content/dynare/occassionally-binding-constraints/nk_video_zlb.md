---
title: Zero-Lower-Bound (ZLB) in the New Keynesian baseline model with Dynare
#linktitle: Zero-Lower-Bound (ZLB) in the New Keynesian baseline model with Dynare
summary: In this video I will show you how to incorporate the Zero Lower Bound on nominal interest rates in the canonical New Keynesian model with Dynare. We'll discuss why and how this has an adverse effect on welfare, and how optimal policy under discretion and commitment looks like. We'll compare both cases in Dynare.
toc: true
type: book
#date: "2021-08-19"
draft: false
weight: 10
---
***Please feel free to raise any comments or issues on the [website's Github repository](https://github.com/wmutschl/mutschler.eu). Pull requests are very much appreciated.***

{{< youtube 6vajPMksxJM >}}

## Description
In this video I will show you how to incorporate the Zero Lower Bound on nominal interest rates in the canonical New Keynesian model with Dynare. We'll discuss why and how this has an adverse effect on welfare, and how optimal policy under discretion and commitment looks like. We'll compare both cases in Dynare.


## Slides
[Presentation](/files/occasionally-binding-constraints/nk_zlb_presentation.pdf)

## Codes

### NK_ZLB_discretion.mod
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

% This implementation was originally written by Johannes Pfeifer.
% Some notes:
% - all model variables are expressed in deviations from steady state, except for the interest rates.
% - The dummy-variable ZLB_indicator is used to shut off the Taylor rule during the 
%   ZLB period and to switch it on again after the ZLB-period. This is necessary,
%   because without a Taylor rule to govern monetary policy after the ZLB period,
%   there is scope for multiple equilibria. Switching on the Taylor rule assures that
%   the solution pi=x=0 is selected. Otherwise, one would need to set the number of 
%   simulation periods to 6 so that the terminal condition of all variables being back
%   to steady state is imposed immediately after the end of the ZLB period.


var
  pie             ${\pi}$         (long_name='inflation')
  x               ${x}$           (long_name='welfare-relevant output gap')
  ii              ${i}$           (long_name='nominal interest rate')
  r_nat_ann       ${r^{nat,ann}}$ (long_name='annualized natural interest rate')
  pie_ann         ${\pi^{ann}}$   (long_name='annualized inflation rate')
  xi_2            ${\xi_2}$       (long_name='Langrange multiplier')
  ii_ann          ${i^{ann}}$     (long_name='annualized nominal interest rate')  
  ii_taylor       ${i^{Taylor}}$  (long_name='nominal interest rate Taylor rule')  
;     

varexo 
  r_nat           ${r^n}$         (long_name='natural rate of interest')
  ZLB_indicator   ${ZLB\_IND}$    (long_name='ZLB Indicator')
;

parameters
  ALPHA           ${\alpha}$      (long_name='One minus labor income share')
  BETA            ${\beta}$       (long_name='discount factor')
  SIGMA           ${\sigma}$      (long_name='risk aversion')
  VARPHI          ${\varphi}$     (long_name='inverse Frisch elasticity')
  EPSILON         ${\epsilon}$    (long_name='demand elasticity')
  THETA           ${\theta}$      (long_name='Calvo parameter')
  PHI_PIE         ${\phi_\pi}$    (long_name='Taylor rule inflation feedback')
;

%----------------------------------------------------------------
% Parametrization
%----------------------------------------------------------------
SIGMA   = 1;
VARPHI  = 5;
THETA   = 3/4;
BETA    = 0.99;
ALPHA   = 1/4;
EPSILON = 9;
PHI_PIE = 1.5;

model; 
#KAPPA=(1-THETA)*(1-BETA*THETA)/THETA*(1-ALPHA)/(1-ALPHA+ALPHA*EPSILON)*(SIGMA+(VARPHI+ALPHA)/(1-ALPHA));
#VARTHETA=KAPPA/EPSILON;
#ii_ = ZLB_indicator*ii + (1-ZLB_indicator)*ii_taylor;

[name='New Keynesian Phillips Curve']
pie = BETA*pie(+1) + KAPPA*x;

[name='Dynamic IS Curve']
x = x(+1) - 1/SIGMA*( ii_ - pie(+1) - r_nat);

[name='Taylor rule']
ii_taylor = 1 + PHI_PIE*pie;

[name='Combined FOC wrt pie and wrt x']
VARTHETA*x=-KAPPA*pie-xi_2;

[name='FOC wrt to ii',mcp='ii>0']
xi_2*1/SIGMA=0;

[name='Annualized natural interest rate']
r_nat_ann=4*r_nat;

[name='Annualized inflation']
pie_ann=4*pie;

[name='Annualized nominal interest rate']
ii_ann=4*max(ii_,0);
end;

%----------------------------------------------------------------------
% set initial and terminal condition to steady state of non-ZLB period;
% note that all variables have steady state of 0, except interest rates
%----------------------------------------------------------------------
initval;
  ZLB_indicator = 0;
  r_nat     = 1;
  ii        = 1;
  ii_taylor = 1;
  ii_ann    = 4*ii;
  r_nat_ann = 4*r_nat;  
end;
steady;

%-----------------------------------
% define negative natural rate shock
%-----------------------------------
shocks;
  var r_nat;         periods 1:6; values -1;
  var ZLB_indicator; periods 1:6; values 1;
end;

perfect_foresight_setup(periods=20);
perfect_foresight_solver(lmmcp);

%-----------------------------------
% Make figures
%-----------------------------------
figure
subplot(2,2,1)
plot(0:12,oo_.endo_simul(strmatch('x',M_.endo_names,'exact'),M_.maximum_lag+1:M_.maximum_lag+13),'-o')
axis([0 12 -15 5])
title 'Output gap'

subplot(2,2,2)
plot(0:12,oo_.endo_simul(strmatch('pie_ann',M_.endo_names,'exact'),M_.maximum_lag+1:M_.maximum_lag+13),'-o')
axis([0 12 -25 5])
title 'Annualized Inflation'

subplot(2,2,3)
plot(0:12,oo_.endo_simul(strmatch('ii_ann',M_.endo_names,'exact'),M_.maximum_lag+1:M_.maximum_lag+13),'-o')
axis([0 12 -2 6])
title 'Annualized Nominal Interest Rate'

subplot(2,2,4)
plot(0:12,oo_.endo_simul(strmatch('r_nat_ann',M_.endo_names,'exact'),M_.maximum_lag+1:M_.maximum_lag+13),'-')
axis([0 12 -6 6])
title 'Annualized Natural Interest Rate'
```

### NK_ZLB_commitment.mod
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

% This implementation was originally written by Johannes Pfeifer.
% Some notes:
% - all model variables are expressed in deviations from steady state, except for the interest rates.

var
  pie             ${\pi}$         (long_name='inflation')
  x               ${x}$           (long_name='welfare-relevant output gap')
  ii              ${i}$           (long_name='nominal interest rate')
  r_nat_ann       ${r^{nat,ann}}$ (long_name='annualized natural interest rate')
  pie_ann         ${\pi^{ann}}$   (long_name='annualized inflation rate')
  xi_1            ${\xi_1}$       (long_name='Langrange multiplier')
  xi_2            ${\xi_2}$       (long_name='Langrange multiplier')
  ii_ann          ${i^{ann}}$     (long_name='annualized nominal interest rate')  
; 

varexo
  r_nat           ${r^n}$         (long_name='natural rate of interest')
;

parameters
  ALPHA           ${\alpha}$      (long_name='One minus labor income share')
  BETA            ${\beta}$       (long_name='discount factor')
  SIGMA           ${\sigma}$      (long_name='risk aversion')
  VARPHI          ${\varphi}$     (long_name='inverse Frisch elasticity')
  EPSILON         ${\epsilon}$    (long_name='demand elasticity')
  THETA           ${\theta}$      (long_name='Calvo parameter')
;

%----------------------------------------------------------------
% Parametrization
%----------------------------------------------------------------
SIGMA   = 1;
VARPHI  = 5;
THETA   = 3/4;
BETA    = 0.99;
ALPHA   = 1/4;
EPSILON = 9;

model; 
#KAPPA=(1-THETA)*(1-BETA*THETA)/THETA*(1-ALPHA)/(1-ALPHA+ALPHA*EPSILON)*(SIGMA+(VARPHI+ALPHA)/(1-ALPHA));
#VARTHETA=KAPPA/EPSILON; 

[name='New Keynesian Phillips Curve']
pie = BETA*pie(+1) + KAPPA*x;

[name='Dynamic IS Curve']
x = x(+1) - 1/SIGMA*( ii - pie(+1) - r_nat);

[name='FOC wrt pie']
pie + xi_1 - xi_1(-1)-1/(BETA*SIGMA)*xi_2(-1)=0;

[name='FOC wrt x']
VARTHETA*x-KAPPA*xi_1+xi_2-1/BETA*xi_2(-1)=0;

[name='FOC wrt to ii',mcp='ii>0']
xi_2*1/SIGMA=0;

[name='Annualized natural interest rate']
r_nat_ann=4*r_nat;

[name='Annualized inflation']
pie_ann=4*pie;

[name='Annualized nominal interest rate']
ii_ann=4*max(ii,0);
end;

%----------------------------------------------------------------------
% set initial and terminal condition to steady state of non-ZLB period;
% note that all variables have steady state of 0, except interest rates
%----------------------------------------------------------------------
initval;
  r_nat     = 1;
  ii        = 1;
  ii_ann    = 4*ii;
  r_nat_ann = 4*r_nat;
end;
steady;

%-----------------------------------
% define negative natural rate shock
%-----------------------------------
shocks;
var r_nat; periods 1:6; values -1;
end;

perfect_foresight_setup(periods=50);
perfect_foresight_solver(lmmcp);

%-----------------------------------
% Make figures
%-----------------------------------
figure
subplot(2,2,1)
plot(0:12,oo_.endo_simul(strmatch('x',M_.endo_names,'exact'),M_.maximum_lag+1:M_.maximum_lag+13),'-x')
axis([0 12 -15 5])
title 'Output gap'

subplot(2,2,2)
plot(0:12,oo_.endo_simul(strmatch('pie_ann',M_.endo_names,'exact'),M_.maximum_lag+1:M_.maximum_lag+13),'-x')
axis([0 12 -25 5])
title 'Annualized Inflation'

subplot(2,2,3)
plot(0:12,oo_.endo_simul(strmatch('ii_ann',M_.endo_names,'exact'),M_.maximum_lag+1:M_.maximum_lag+13),'-x')
axis([0 12 -2 6])
title 'Annualized Nominal Interest Rate'

subplot(2,2,4)
plot(0:12,oo_.endo_simul(strmatch('r_nat_ann',M_.endo_names,'exact'),M_.maximum_lag+1:M_.maximum_lag+13),'-')
axis([0 12 -6 6])
title 'Annualized Natural Interest Rate'
```

### NK_ZLB_compare_plots.m
```MATLAB
close all; clear all;clc;
options_.nograph = true;

% Run discretion and save simulated variables
dynare NK_ZLB_discretion;
x_discretion = oo_.endo_simul(strmatch('x',M_.endo_names,'exact'),M_.maximum_lag+1:M_.maximum_lag+13);
pie_ann_discretion = oo_.endo_simul(strmatch('pie_ann',M_.endo_names,'exact'),M_.maximum_lag+1:M_.maximum_lag+13);
ii_ann_discretion = oo_.endo_simul(strmatch('ii_ann',M_.endo_names,'exact'),M_.maximum_lag+1:M_.maximum_lag+13);
r_nat_ann_discretion = oo_.endo_simul(strmatch('r_nat_ann',M_.endo_names,'exact'),M_.maximum_lag+1:M_.maximum_lag+13);

% Run commitment and save simulated variables
dynare NK_ZLB_commitment;
x_commitment = oo_.endo_simul(strmatch('x',M_.endo_names,'exact'),M_.maximum_lag+1:M_.maximum_lag+13);
pie_ann_commitment = oo_.endo_simul(strmatch('pie_ann',M_.endo_names,'exact'),M_.maximum_lag+1:M_.maximum_lag+13);
ii_ann_commitment = oo_.endo_simul(strmatch('ii_ann',M_.endo_names,'exact'),M_.maximum_lag+1:M_.maximum_lag+13);
r_nat_ann_commitment = oo_.endo_simul(strmatch('r_nat_ann',M_.endo_names,'exact'),M_.maximum_lag+1:M_.maximum_lag+13);

%-----------------------------------
% Make figures
%-----------------------------------
figure
subplot(2,2,1)
plot(0:12,x_discretion,'-o')
hold on
plot(0:12,x_commitment,'-x')
axis([0 12 -15 5])
title 'Output gap'
legend {'Discretion','Commitment'}

subplot(2,2,2)
plot(0:12,pie_ann_discretion,'-o')
hold on
plot(0:12,pie_ann_commitment,'-x')
axis([0 12 -25 5])
title 'Annualized Inflation'
legend {'Discretion','Commitment'}

subplot(2,2,3)
plot(0:12,ii_ann_discretion,'-o')
hold on
plot(0:12,ii_ann_commitment,'-x')
axis([0 12 -2 6])
title 'Annualized Nominal Interest Rate'
legend {'Discretion','Commitment'}

subplot(2,2,4)
plot(0:12,r_nat_ann_discretion,'-o')
hold on
plot(0:12,r_nat_ann_commitment,'-x')
axis([0 12 -6 6])
title 'Annualized Natural Interest Rate'
legend {'Discretion','Commitment'}
```
