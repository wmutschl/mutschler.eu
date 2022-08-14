---
title: 4 methods to compute the steady state of a DSGE model in Dynare
#linktitle: 4 ways to compute the steady state of a DSGE model in Dynare
summary: In this tutorial we will discuss four different ways to compute the steady-state of a DSGE model in Dynare. We will cover (1) the steady_state_model block if your steady-state is available in closed-form, (2) the steady_state_model block with a helper function if some variables are not available in closed-form, (3) writing a steadystate MATLAB function, and (4) the initval block.
toc: true
type: book
#date: "2021-08-19"
draft: false
weight: 1
---
***Please feel free to raise any comments or issues on the [website's Github repository](https://github.com/wmutschl/mutschler.eu). Pull requests are very much appreciated.***

{{< youtube Ei_z0HSfYNo >}}

## Description
In this tutorial we will discuss four different ways to compute the steady-state of a DSGE model in Dynare. We will cover (1) the steady_state_model block if your steady-state is available in closed-form, (2) the steady_state_model block with a helper function if some variables are not available in closed-form, (3) writing a steadystate MATLAB function, and (4) the initval block. As our example model we use a variant of the [RBC model with leisure](../../models/rbc) with a CES or log utility function. That is, when we consider the log-utility case, the steady state is given analytically, whereas in the CES utility case we cannot solve for labor in closed-form.

## Method 1: steady_state_model
Let's consider the log-utility case, i.e. we have a recipe to compute the steady state in closed-form analytically. This can be easily written down in a `steady_state_model` block in your mod file:
```matlab
# rbc_logutil.mod
var Y C K L A R W I;
varexo eps_A;
parameters alph betta delt gam pssi rhoA;

alph = 0.35; betta = 0.99; delt = 0.025; gam = 1; pssi = 1.6; rhoA = 0.9;

model;
    #UC  = gam*C^(-1);
    #UCp = gam*C(+1)^(-1);
    #UL  = -pssi*(1-L)^(-1);
    UC = betta*UCp*(1-delt+R);
    W = -UL/UC;
    K = (1-delt)*K(-1)+I;
    Y = I+C;
    Y = A*K(-1)^alph*L^(1-alph);
    W = (1-alph)*Y/L;
    R = alph*Y/K(-1);
    log(A) = rhoA*log(A(-1))+eps_A;
end;

steady_state_model;
    A = 1;
    R = 1/betta+delt-1;
    K_L = ((alph*A)/R)^(1/(1-alph));
    W = (1-alph)*A*K_L^alph;
    I_L = delt*K_L;
    Y_L = A*K_L^alph;
    C_L = Y_L-I_L;

    % closed-form expression for labor when using log utility    
    L = gam/pssi*C_L^(-1)*W/(1+gam/pssi*C_L^(-1)*W);

    C = C_L*L;
    I = I_L*L;
    K = K_L*L;
    Y = Y_L*L;
end;

steady;
resid;
```
This is the preferred method to specify your steady state in your mod file, but it takes much time, effort, and practice to derive the closed-form solutions.

## Method 2: steady_state_model with helper function
Often you can derive closed-form expressions for some variables in steady state, but not for a few others. An example of this is the RBC model with CES utility, where we cannot solve for labor analytically, but once we have a value for labor, all other variables can be computed in closed-form. Such cases can be coped with by using a helper function in your `steady_state_model` block. Consider the following mod file first:
```matlab
# rbc_ces1.mod
var Y C K L A R W I;
varexo eps_A;
parameters alph betta delt gam pssi rhoA etaC etaL;

alph = 0.35; betta = 0.99; delt = 0.025; gam = 1; pssi = 1.6; rhoA = 0.9;
etaC  = 2;   etaL  = 1.5;

model;
    #UC  = gam*C^(-etaC);
    #UCp = gam*C(+1)^(-etaC);
    #UL  = -pssi*(1-L)^(-etaL);
    UC = betta*UCp*(1-delt+R);
    W = -UL/UC;
    K = (1-delt)*K(-1)+I;
    Y = I+C;
    Y = A*K(-1)^alph*L^(1-alph);
    W = (1-alph)*Y/L;
    R = alph*Y/K(-1);
    log(A) = rhoA*log(A(-1))+eps_A;
end;

steady_state_model;
    A = 1;
    R = 1/betta+delt-1;
    K_L = ((alph*A)/R)^(1/(1-alph));
    W = (1-alph)*A*K_L^alph;
    I_L = delt*K_L;
    Y_L = A*K_L^alph;
    C_L = Y_L-I_L;

    % closed-form expression for labor is not possible, so we need a helper function
    L0 = 1/3;
    L = rbc_ces1_steadystate_helper(L0,pssi,etaL,etaC,gam,C_L,W);

    C = C_L*L;
    I = I_L*L;
    K = K_L*L;
    Y = Y_L*L;
end;

steady;
resid;
```
Note that in the `steady_state_model` block we are calling the helper function `rbc_ces1_steadystate_helper.m`, which uses MATLAB to compute L given a start value L0 and previously computed steady state values. You need to create this file (and call it whatever you want it to be called) in the same folder as your mod file, but use the `.m` extension. I called it `rbc_ces1_steadystate_helper.m`:
```matlab
function L = rbc_ces1_steadystate_helper(L0,pssi,etaL,etaC,gam,C_L,W)
    if etaC == 1 && etaL == 1
        L = gam/pssi*C_L^(-1)*W/(1+gam/pssi*C_L^(-1)*W);
    else
        options = optimset('Display','Final','TolX',1e-10,'TolFun',1e-10);
        L = fsolve(@(L) pssi*(1-L)^(-etaL)*L^etaC - gam*C_L^(-etaC)*W, L0,options);
    end
end
```
Note that I use `fsolve` to compute the labor value in steady state and set up some options using `optimset`. You can and should, of course, use other optimizers that work better in your model. Also, note that I catch the special case of log-utility as there is a closed-form solution.

## Method 3: steadystate file
If you want full control of the steady state computations, you need to create your own `YOURMODFILENAME_steadystate.m`. So let's create another mod file
```matlab
# rbc_ces2.mod
var Y C K L A R W I;
varexo eps_A;
parameters alph betta delt gam pssi rhoA etaC etaL;

alph = 0.35; betta = 0.99; delt = 0.025; gam = 1; pssi = 1.6; rhoA = 0.9;
etaC  = 2;   etaL  = 1.5;

model;
    #UC  = gam*C^(-etaC);
    #UCp = gam*C(+1)^(-etaC);
    #UL  = -pssi*(1-L)^(-etaL);
    UC = betta*UCp*(1-delt+R);
    W = -UL/UC;
    K = (1-delt)*K(-1)+I;
    Y = I+C;
    Y = A*K(-1)^alph*L^(1-alph);
    W = (1-alph)*Y/L;
    R = alph*Y/K(-1);
    log(A) = rhoA*log(A(-1))+eps_A;
end;

steady;
resid;
```
Note that there is no `steady_state_model` or `initval` block, but the sole command steady which instructs Dynare to compute the steady state. Now let's create another MATLAB file, called `rbc_ces2_steadystate.m`, which actually computes the steady state:
```matlab
function [ys,params,check] = rbc_ces2_steadystate(ys,exo,M_,options_)
% Inputs: 
%   - ys        [vector] vector of initial values for the steady state of the endogenous variables
%   - exo       [vector] vector of values for the exogenous variables
%   - M_        [structure] Dynare model structure
%   - options   [structure] Dynare options structure
%
% Output: 
%   - ys        [vector] vector of steady state values for the the endogenous variables
%   - params    [vector] vector of parameter values
%   - check     [scalar] 0 if steady state computation worked and to
%                        1 of not (allows to impose restrictions on parameters)

%% Step 0: initialize indicator and set options for numerical solver
check = 0;
options = optimset('Display','Final','TolX',1e-10,'TolFun',1e-10);

%% Step 1: read out parameters to access them with their name
for ii = 1:M_.param_nbr
  eval([ M_.param_names{ii} ' = M_.params(' int2str(ii) ');']);
end

%% Step 2: Check parameter restrictions
if etaC*etaL<1 % parameter violates restriction (here it is artifical)
    check=1; %set failure indicator
    return;  %return without updating steady states
end

%% Step 3: Enter model equations here
A = 1;
R = 1/betta+delt-1;
K_L = ((alph*A)/R)^(1/(1-alph));
if K_L <= 0
    check = 1; % set failure indicator
    return;    % return without updating steady states
end

W = (1-alph)*A*K_L^alph;
I_L = delt*K_L;
Y_L = A*K_L^alph;
C_L = Y_L-I_L;

if C_L <= 0
    check = 1; % set failure indicator
    return;    % return without updating steady states
end

% The labor level
if etaC == 1 && etaL == 1
    % Closed-form solution for labor
    L = gam/pssi*C_L^(-1)*W/(1+gam/pssi*C_L^(-1)*W);
else
    % No closed-form solution use a fixed-point algorithm
    L0 = 1/3;
    [L,~,exitflag] = fsolve(@(L) pssi*(1-L)^(-etaL)*L^etaC - gam*C_L^(-etaC)*W, L0,options);
    if exitflag <= 0
        check = 1; % set failure indicator
        return     % return without updating steady states
    end
end

C = C_L*L; % consumption level
I = I_L*L; % investment level
K = K_L*L; % capital level
Y = Y_L*L; % output level

%% Step 4: Update parameters and variables
params=NaN(M_.param_nbr,1);
for iter = 1:M_.param_nbr %update parameters set in the file
  eval([ 'params(' num2str(iter) ') = ' M_.param_names{iter} ';' ])
end

for ii = 1:M_.orig_endo_nbr %auxiliary variables are set automatically
  eval(['ys(' int2str(ii) ') = ' M_.endo_names{ii} ';']);
end
```
Some remarks are in order:
1. We usually do not recommend to write you own file to compute the steady state as this is error-prone. But a definite advantage is that you have full control of the computations.
2. Your `_steadystate.m` file needs to have the same first part of the name as your mod file.
3. Step 1 and Step 4 are always the same and very important to include in your steadystate file.
4. Note that previous to Dynare 4.6 `M_` and `options_` were called globally, but not anymore. Thus, we need to use these variables as inputs. This is a new feature as previously people used the global variables in a wrong fashion, e.g. falsely updated them in an estimation exercise. So if you have older mod files, you need to adapt this accordingly.
5. Before I actually call the numerical optimizer, I included examples on how to check parameter and variable restrictions. If they are not fulfilled, the function returns a flag that the steady state could not be computed. This is good practice as the numerical solver could be time-consuming or would lead unfeasible results.
6. Lastly, you need to specify values for all your declared variables and output both parameters and variables. Dynare then updates the auxiliary variables internally.

## Method 4: initval
If you have no clue at all on how to compute the steady state of your model, you can always rely on numerical methods. Dynare has several in-built optimization algorithms you can choose and fine-tune (see the [manual](https://www.dynare.org/manual/the-model-file.html?highlight=steady#steady) on all available options). You need to specify an `initval` block with the initial values for the endogenous variables:
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
    UC = betta*UCp*(1-delt+R);
    W = -UL/UC;
    K = (1-delt)*K(-1)+I;
    Y = I+C;
    Y = A*K(-1)^alph*L^(1-alph);
    W = (1-alph)*Y/L;
    R = alph*Y/K(-1);
    log(A) = rhoA*log(A(-1))+eps_A;
end;

initval;
Y = 1.2; 
C = 0.9;
K = 12;
L = 0.35;
A = 1;
R = 0.03;
W = 2.24;
I = 0.3;
end;
steady;
resid;
```
Note that if you don't specify a variable explicitly, Dynare uses 0 as initial value. Typically, you would take initial values from a simpler model and use these in a more elaborate model. In this case, we take the log-utility values for our ces-utility model. This concept is closely related to a more elaborate way on finding the steady state called "*homotopy*" (a divide-and-conquer technique to solve for the steady state), which I will cover in another tutorial.