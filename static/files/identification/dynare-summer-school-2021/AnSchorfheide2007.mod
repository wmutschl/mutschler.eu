% =========================================================================
% DYNARE PREPROCESSING
% =========================================================================
% The macro variable(s) have the following meaning and possible values:
% - monpol: specifies Output Gap definition in Taylor Rule
%       - 0: deviation from flex-price output
%       - 1: deviation from steady state output
%       - 2: deviation from output growth
@#define monpol = 0

% =========================================================================
% Declare endogenous variables
% =========================================================================
var
YGR         ${YGR}$             (long_name='output growth rate (quarter-on-quarter)')
INFL        ${INFL}$            (long_name='annualized inflation rate')
INT         ${INT}$             (long_name='annualized nominal interest rate')
y           ${y}$               (long_name='detrended output (Y/A)')
c           ${c}$               (long_name='detrended consumption (C/A)')
r           ${R}$               (long_name='nominal interest rate')
p           ${\pi}$             (long_name='gross inflation rate')
g           ${g}$               (long_name='government consumption process (g = 1/(1-G/Y))')
z           ${z}$               (long_name='shifter to steady-state technology growth')
; % [var] end

% =========================================================================
% Declare observable variables
% =========================================================================
varobs YGR INFL INT;

% =========================================================================
% Declare exogenous variables
% =========================================================================
varexo
epsr        ${\varepsilon^R}$       (long_name='monetary policy shock')
epsg        ${\varepsilon^g}$       (long_name='government spending shock')
epsz        ${\varepsilon^z}$       (long_name='total factor productivity growth shock')
; % [varexo] end


% =========================================================================
% Declare parameters
% =========================================================================
parameters
RA          ${r_{A}}$               (long_name='annualized steady-state real interest rate')
PA          ${\pi^{(A)}}$           (long_name='annualized target inflation rate')
GAMQ        ${\gamma^{(Q)}}$        (long_name='quarterly steady-state growth rate of technology')
TAU         ${\tau}$                (long_name='inverse of intertemporal elasticity of subsitution')
NU          ${\nu}$                 (long_name='inverse of elasticity of demand in Dixit Stiglitz aggregator')
PSIP        ${\psi_\pi}$            (long_name='Taylor rule sensitivity parameter to inflation deviations')
PSIY        ${\psi_y}$              (long_name='Taylor rule sensitivity parameter to output deviations')
RHOR        ${\rho_R}$              (long_name='Taylor rule persistence')
RHOG        ${\rho_{g}}$            (long_name='persistence government spending process')
RHOZ        ${\rho_z}$              (long_name='persistence TFP growth rate process')
SIGR        ${\sigma_R}$            (long_name='standard deviation monetary policy shock')
SIGG        ${\sigma_{g}}$          (long_name='standard deviation government spending process')
SIGZ        ${\sigma_z}$            (long_name='standard deviation TFP growth shock')
PHI         ${\phi}$                (long_name='Rotemberg adjustment cost parameter')
C_o_Y       ${\bar{C}/\bar{Y}}$     (long_name='steady state consumption to output ratio')
OMEGA       ${\omega}$              (long_name='auxiliary parameter')
XI          ${\xi}$                 (long_name='auxiliary parameter')
; % parameter block end


% =========================================================================
% Calibrate parameter values
% =========================================================================
RA      = 1;
PA      = 3.2;
GAMQ    = 0.55;
TAU     = 2;
NU      = 0.1;
KAPPA   = 0.33;
PHI     = TAU*(1-NU)/NU/KAPPA/exp(PA/400)^2;
PSIP    = 1.5;
PSIY    = 0.125;
RHOR    = 0.75;
RHOG    = 0.95;
RHOZ    = 0.9;
SIGR    = 0.2;
SIGG    = 0.6;
SIGZ    = 0.3;
C_o_Y   = 0.85;
OMEGA   = 0;
XI      = 1;

% =========================================================================
% Model equations
% =========================================================================
model;
% -------------------------------------------------------------------------
% Auxiliary parameters and variables
#GAM = 1+GAMQ/100;
#BET = 1/(1+RA/400);
#PSTAR = 1+PA/400;
#G = 1/C_o_Y;
#ystar = (1-NU)^(1/TAU)*g;
#ystarback = (1-NU)^(1/TAU)*g(-1);
% -------------------------------------------------------------------------
% Monetary policy specification
@#if monpol == 0
#RSTAR = steady_state(r)*(p/PSTAR)^PSIP*(y/ystar)^PSIY;
@#endif
@#if monpol == 1
#RSTAR = steady_state(r)*(p/PSTAR)^PSIP*(y/steady_state(y))^PSIY;
@#endif
@#if monpol == 2
#RSTAR = steady_state(r)*(p/PSTAR)^PSIP*(y/y(-1)*z)^PSIY;
@#endif
% -------------------------------------------------------------------------
% Indexation rule
#gammap = steady_state(p);
#gammapback = steady_state(p);
% -------------------------------------------------------------------------
% Marginal utility and foc wrt c
#du_dc = c^(-TAU);
#dup_dcp = c(+1)^(-TAU);
#lam = du_dc;
#lamp = dup_dcp;

% =========================================================================
% Actual Model Equations
% =========================================================================
[name='Euler equation']
lam = BET*lamp*r/p(+1)/(GAM*z(+1));

[name='Phillips curve based on Rotemberg price setting and Dixit/Stiglitz aggregator']
1 = 1/NU*(1-lam^(-1))+PHI*(p-gammapback)*p - PHI/(2*NU)*(p-gammap)^2 + PHI*BET*(lamp/lam*y(+1)/y*(p(+1)-gammap)*p(+1));

[name='market clearing']
y = c + (1-1/g)*y + PHI/2*(p-gammapback)^2*y;

[name='Taylor rule']
r = RSTAR^(1-RHOR)*r(-1)^RHOR*exp(SIGR/100*epsr);

[name='government spending process']
log(g) = (1-RHOG)*log(G) + RHOG*log(g(-1)) + SIGG/100*epsg;

[name='technology growth process']
log(z) = XI*RHOZ*log(z(-1)) + SIGZ/100*epsz;

[name='output growth (q-on-q)']
YGR = GAMQ + 100*(log(y/steady_state(y)) - log(y(-1)/steady_state(y)) + log(z/steady_state(z)));

[name='annualized inflation']
INFL = PA + 400*log(p/steady_state(p));

[name='annualized nominal interest rate']
INT = PA + RA + 4*GAMQ + 400*log(r/steady_state(r));
end; % [model] end


% =========================================================================
% Steady state Model
% =========================================================================
steady_state_model;
GAMMA    = 1+GAMQ/100;
BETA     = 1/(1+RA/400);
PBARSTAR = 1+PA/400;
ZBAR = 1;
z    = ZBAR;
p    = PBARSTAR;
g    = 1/C_o_Y;
r    = GAMMA*ZBAR*PBARSTAR/BETA;
c    = (1-NU)^(1/TAU);
y    = g*c;
YGR  = GAMQ;
INFL = PA;
INT  = PA + RA + 4*GAMQ;
end; % [steady_state_model] end


% =========================================================================
% Declare settings for shocks
% =========================================================================
shocks;
var epsr = 1;
var epsg = 1;
var epsz = 1;
% corr e_r, e_g = 0.3;
% corr e_r, e_z = 0.2;
% corr e_z, e_g = 0.1;
end; % [shocks] end


% =========================================================================
% Specify Economic Priors
% =========================================================================
estimated_params;
% --------------------------------------------------------------------------------------------------------------------------------------------------
%PARAMETER_NAME, INITIAL_VALUE, LOWER_BOUND, UPPER_BOUND, PRIOR_SHAPE,   PRIOR_MEAN, PRIOR_STANDARD_ERROR, PRIOR_3RD_PARAMETER, PRIOR_4TH_PARAMETER;
% --------------------------------------------------------------------------------------------------------------------------------------------------
RA,              1,             1e-5,        10,          gamma_pdf,     0.8,        0.5;
PA,              3.2,           1e-5,        20,          gamma_pdf,     4,          2;
GAMQ,            0.55,          -5,          5,           normal_pdf,    0.4,        0.2;
TAU,             2,             1e-5,        10,          gamma_pdf,     2,          0.5;
NU,              0.1,           1e-5,        0.99999,     beta_pdf,      0.1,        0.05;
PSIP,            1.5,           1e-5,        10,          gamma_pdf,     1.5,        0.25;
PSIY,            0.125,         1e-5,        10,          gamma_pdf,     0.5,        0.25;
RHOR,            0.75,          1e-5,        0.99999,     beta_pdf,      0.5,        0.2;
RHOG,            0.95,          1e-5,        0.99999,     beta_pdf,      0.8,        0.1;
RHOZ,            0.9,           1e-5,        0.99999,     beta_pdf,      0.66,       0.15;
SIGR,            0.2,           1e-8,        5,           inv_gamma_pdf, 0.3,        4;
SIGG,            0.6,           1e-8,        5,           inv_gamma_pdf, 0.4,        4;
SIGZ,            0.3,           1e-8,        5,           inv_gamma_pdf, 0.4,        4;
C_o_Y,           0.85,          1e-5,        0.99999,     beta_pdf,      0.85,       0.1;
PHI,             50,            1e-5,        100,         gamma_pdf,     50,         20;
stderr epsz,     0.3,           1e-8,        5,           inv_gamma_pdf, 0.4,        4;
stderr epsr,     0.2,           1e-8,        5,           inv_gamma_pdf, 0.3,        4;
stderr epsg,     0.6,           1e-8,        5,           inv_gamma_pdf, 0.4,        4;
OMEGA,           0,             -10,         10,          normal_pdf,      0,        1;
XI,              1,             0,           2,           uniform_pdf,      ,         ,                    0,                   2;
% corr e_r,e_g,    0.3,           1e-8,        5,           inv_gamma_pdf, 0.4,        4;
% corr e_z,e_g,    0.3,           1e-8,        5,           inv_gamma_pdf, 0.4,        4;
% corr e_z,e_r,    0.3,           1e-8,        5,           inv_gamma_pdf, 0.4,        4;
end; % [estimated_params] end


% =========================================================================
% Steady-State, Checks and Diagnostics
% =========================================================================
steady;                 % compute steady state given the starting values
resid;                  % check the residuals of model equations evaluated at steady state
check;                  % check Blanchard-Kahn conditions
model_diagnostics;      % check obvious model errors