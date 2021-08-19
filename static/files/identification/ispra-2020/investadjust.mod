% =========================================================================
% Declare endogenous variables
% =========================================================================
var
  y    ${Y}$        (long_name='output')
  yd   ${Y^d}$      (long_name='demand')
  c    ${C}$        (long_name='consumption')
  iv   ${I}$        (long_name='investment')
  rk   ${R^{K}}$    (long_name='rental rate of capital')
  k    ${K}$        (long_name='private capital stock')
  lam  ${\Lambda}$  (long_name='marginal utility, i.e. Lagrange multiplier budget')
  q    ${Q}$        (long_name='Tobins Q, i.e. Lagrange multiplier capital stock')
  a    ${A}$        (long_name='total factor productivity')
;


% =========================================================================
% Declare exogenous variables
% =========================================================================
varexo
  epsa  ${\varepsilon^A}$  (long_name='total factor productivity shock')
;


% =========================================================================
% Declare parameters
% =========================================================================
parameters
BETA   ${\beta}$     (long_name='discount factor')
ALPHA  ${\alpha}$    (long_name='bias towards capital in production')
RA     ${r_{A}}$     (long_name='annual steady-state real interest rate (defines discount factor)')
DELTA  ${\delta}$    (long_name='depreciation rate')
QBAR   ${\bar{Q}}$   (long_name='steady state Tobins Q')
ABAR   ${\bar{A}}$   (long_name='steady state technology')
RHOA   ${\rho_A}$    (long_name='persistence TFP')
SIGA   ${\sigma_A}$  (long_name='standard deviation TFP shock')
THETA  ${\theta}$    (long_name='multisectoral adjustment cost parameter')
KAPPA  ${\kappa}$    (long_name='investment adjustment cost parameter')
;


% =========================================================================
% Calibrate parameter values and compute implied steady state (denoted here with BARS)
% =========================================================================
% Relevant calibration for full model
IBAR_O_YBAR = 0.25;         % average investment output ratio I/Y
KBAR_O_YBAR = 10;           % average capital capital productivity K/Y
DELTA       = IBAR_O_YBAR/KBAR_O_YBAR;  % quarterly depreciation rate
RA          = 2;            % annual nominal interest rate
BETA        = 1/(1+RA/400); % discount factor
RHOA        = 0.5;          % technology persistence
SIGA        = 0.6;          % technology standard deviation
ABAR        = 1;            % normalize steady state technology level
QBAR        = 1;            % normalize steady state Tobin's Q
RKBAR = (1/BETA+DELTA-1)*QBAR; % foc K
ALPHA = RKBAR*KBAR_O_YBAR;  % capital share in production

% baseline parametrization
THETA       = 1.5;          % multisectoral investment adjustment cost parameter
KAPPA       = 2;            % intertemporal investment adjustment cost parameter

% no multisectoral costs
% THETA = 0;
% KAPPA = 1.4;

% no intertemporal costs
% KAPPA = 0;
% THETA = -3.5;

% =========================================================================
% Model equations
% =========================================================================
model;
% Auxiliary expressions for multisectoral adjustment cost
#SAVBAR = steady_state(iv)/steady_state(y);
#xc = ( c/((1-SAVBAR)*yd) )^THETA;
#xiv = ( iv/(SAVBAR*yd) )^THETA;

[name='aggregate demand']
yd = ((1-SAVBAR)*(c/(1-SAVBAR))^(1+THETA) + SAVBAR*(iv/SAVBAR)^(1+THETA))^(1/(1+THETA));

[name='foc household wrt c (marginal utility of consumption)']
xc*lam = c^(-1);

[name='foc household wrt iv (Tobins Q)']
xiv*lam = lam*q*(DELTA*k/iv)^KAPPA;

[name='foc household wrt k (Euler equation capital)']
lam*q = BETA*lam(+1)*(rk(+1) + (1-DELTA)*q(+1)*(k(+1)/k)^KAPPA);

[name='capital accumulation']
k = ((1-DELTA)*k(-1)^(1-KAPPA) + DELTA*(iv/DELTA)^(1-KAPPA))^(1/(1-KAPPA));

[name='production function']
y = a*k(-1)^ALPHA;

[name='firm capital demand']
rk = a*ALPHA*k(-1)^(ALPHA-1);

[name='market clearing (resource constraint)']
y = yd;

[name='Evolution of technology']
log(a) = RHOA*log(a(-1)) + SIGA*epsa;

end;


% =========================================================================
% Steady State Model
% =========================================================================
steady_state_model;
A = ABAR;
Q = QBAR;
RK = (1/BETA+DELTA-1)*Q;
K = ((ALPHA*A)/RK)^(1/(1-ALPHA));
Y = A*K^ALPHA;
IV = DELTA*K;
SAV = IV / Y;
C = (1-SAV)*Y;
YD = ( (1-SAV)*(C/(1-SAV))^(1+THETA) + SAV*(IV/SAV)^(1+THETA) )^(1/(1+THETA));
XC = ( C/((1-SAV)*Y) )^THETA;
XIV = ( IV/(SAV*Y) )^THETA;
LAM = XC^(-1)*C^(-1);

% Set steady state of model variables
a = A;
q = Q;
rk = RK;
y = Y;
yd = YD;
c = C;
k = K;
iv = IV;
lam = LAM;
end;

% =========================================================================
% Declare settings for shocks
% =========================================================================
shocks;
var epsa = 1;
end;

% =========================================================================
% Specify Priors
% =========================================================================
estimated_params;
% --------------------------------------------------------------------------------------------------------------------------------------------------
%PARAMETER_NAME, INITIAL_VALUE, LOWER_BOUND, UPPER_BOUND, PRIOR_SHAPE,   PRIOR_MEAN, PRIOR_STANDARD_ERROR, PRIOR_3RD_PARAMETER, PRIOR_4TH_PARAMETER;
% --------------------------------------------------------------------------------------------------------------------------------------------------
ALPHA,           0.3,           1e-8,        0.9999,      normal_pdf,    0.3,        0.05;
RA,              2,             1e-8,        10,          gamma_pdf,     2,          0.25;
DELTA,           0.025,         1e-8,        0.9999,      uniform_pdf,   ,           ,                     0,                 0.4;
RHOA,            0.5,           1e-8,        0.9999,      beta_pdf,      0.5,        0.1;
SIGA,            0.6,           1e-8,        10,          inv_gamma_pdf, 0.6,        2;
THETA,           1.5,           1e-8,        10,          gamma_pdf,     1.5,        0.75;
KAPPA,           2,             1e-8,        10,          gamma_pdf,     2,          1.5;
end; % [estimated_params] end

% =========================================================================
% Computations
% =========================================================================
stoch_simul(order=1,irf=0);

varobs c iv;

%identification(parameter_set=calibration);
%identification(parameter_set=calibration, prior_mc=20);
%identification(parameter_set=calibration,advanced=1);
%identification(parameter_set=calibration,advanced=1, prior_mc=20);
identification(order=2);



% =========================================================================
% Latex
% =========================================================================
% collect_latex_files;
% if system(['pdflatex -halt-on-error -interaction=batchmode ' M_.fname '_TeX_binder.tex'])
%     error('TeX-File did not compile.')
% end
