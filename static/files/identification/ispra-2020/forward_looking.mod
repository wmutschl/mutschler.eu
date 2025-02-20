% =========================================================================
% Declare endogenous variables
% =========================================================================
var
  r  ${r}$    (long_name='interest rate')
  x  ${x}$    (long_name='output-gap')
  p  ${\pi}$  (long_name='inflation')
;

% =========================================================================
% Declare exogenous variables
% =========================================================================
varexo
  e_M  ${\varepsilon^M}$  (long_name='monetary policy shock')
  e_D  ${\varepsilon^D}$  (long_name='demand shock')
  e_S  ${\varepsilon^S}$  (long_name='supply shock')
;

% =========================================================================
% Declare parameters
% =========================================================================
parameters
  PSI    ${\psi}$    (long_name='inflation elasticity Taylor rule')
  TAU    ${\tau}$    (long_name='intertemporal elasticity of subsitution')
  BETA   ${\beta}$   (long_name='discount factor')
  KAPPA  ${\kappa}$  (long_name='slope Phillips curve')
;

% =========================================================================
% Calibration
% =========================================================================
PSI=1.1;
TAU=2;
BETA=0.9;
KAPPA=0.6;

% =========================================================================
% Model equations
% =========================================================================
model;
[name='Taylor rule']
r = PSI*p + e_M;

[name='New Keynesian IS curve']
x = x(+1) - 1/TAU*(r-p(+1)) + e_D;

[name='New Keynesian Phillips curve']
p = BETA*p(+1) + KAPPA*x + e_S;
end;

% =========================================================================
% Declare shock covariance matrix
% =========================================================================
shocks;
  var e_M = 1;
  var e_D = 1;
  var e_S = 1;
end;

% =========================================================================
% Specify ML inital value 
% =========================================================================
estimated_params;
  PSI,   1.1; %need to fix if only observing x
  TAU,   2;
  BETA,  0.9;
  KAPPA, 0.6;
end;

% =========================================================================
% Computations
% =========================================================================
steady;
check;

varobs r x p;
%varobs x;
identification;

% =========================================================================
% Latex
% =========================================================================
% collect_latex_files;
% if system(['pdflatex -halt-on-error -interaction=batchmode ' M_.fname '_TeX_binder.tex'])
%     error('TeX-File did not compile.')
% end
