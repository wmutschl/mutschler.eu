---
# Page title
title: Dynare parallel

# Title for the menu link if you wish to use a shorter link title
linktitle: Parallel

# Page summary for search engines
summary: This is a quick tutorial on how to use the parallel option in Dynare on Windows, macOS and Linux. The example covers everything you need to set up and provides an example where we estimate a small model using the Random-Walk Metropolis-Hastings with 4 chains computed in parallel.

# Date page published
date: "2020-04-20T00:00:00Z"
lastmod: "2020-04-20T00:00:00Z"

# Academic page type (do not modify)
type: book

# Position of this page in the menu. Remove this option to sort alphabetically
weight: 30

# Page metadata.
draft: false  # Is this a draft? true/false
toc: true  # Show table of contents? true/false
---

In this quick tutorial, I will cover the necessary steps to run dynare parallel for (i) Windows, (ii) macOS, and (iii) Ubuntu (which should also work on other Linux distributions). You can select the operating system on the left, there are also Youtube videos you might find useful for your operating system. But first, some general remarks.

## Some general remarks

Let's consider the following example mod file called `mymodel.mod`:

```matlab
var YGR INFL INT y c r p g z;
varobs YGR INFL INT;
varexo epsr epsg epsz;

parameters TAU KAPPA PSI1 PSI2 RHOR RHOG RHOZ RA PA GAMQ;

TAU     = 2.00; PSI1    = 1.50; RHOR    = 0.60;
KAPPA   = 0.15; PSI2    = 1.00; RHOG    = 0.95;
RA      = 0.40; GAMQ    = 0.50; RHOZ    = 0.65;
PA      = 4.00;

model;
  #dy = y - y(-1);
  #BET = 1/(1+RA/400);
  y = y(+1) + g - g(+1) -1/TAU*(r - p(+1) - z(+1));
  p = BET*p(+1) + KAPPA*(y - g);
  c = y - g;
  r = RHOR*r(-1) + (1-RHOR)*PSI1*p + (1-RHOR)*PSI2*(dy + z) + epsr/100;
  g = RHOG*g(-1) + epsg/100;
  z = RHOZ*z(-1) + epsz/100;
  YGR = GAMQ + 100*(y - y(-1) + z);
  INFL = PA + 400*p;
  INT = PA + RA + 4*GAMQ + 400*r;
end;

steady_state_model;
  z = 0; p = 0; g = 0; r = 0; c = 0; y = 0;
  YGR = GAMQ; INFL = PA; INT = PA + RA + 4*GAMQ;
end;

shocks;
  var epsr = 0.20^2;
  var epsg = 0.80^2;
  var epsz = 0.45^2;
end;

estimated_params;
  TAU,             2.00,          1e-5,        10,          gamma_pdf,     2.00,       0.50;
  KAPPA,           0.15,          1e-5,        10,          gamma_pdf,     0.20,       0.10;
  PSI1,            1.50,          1e-5,        10,          gamma_pdf,     1.50,       0.25;
  PSI2,            1.00,          1e-5,        10,          gamma_pdf,     0.50,       0.25;
  RHOR,            0.60,          1e-5,        0.99999,     beta_pdf,      0.50,       0.20;
  RHOG,            0.95,          1e-5,        0.99999,     beta_pdf,      0.80,       0.10;
  RHOZ,            0.64,          1e-5,        0.99999,     beta_pdf,      0.66,       0.15;
  RA,              0.40,          1e-5,        10,          gamma_pdf,     0.50,       0.50;
  PA,              4.00,          1e-5,        20,          gamma_pdf,     7.00,       2.00;
  GAMQ,            0.50,          -5,          5,           normal_pdf,    0.40,       0.20;
  stderr epsr,     0.20,          1e-8,        5,           inv_gamma_pdf, 0.50,       0.26;
  stderr epsg,     0.80,          1e-8,        5,           inv_gamma_pdf, 1.25,       0.65;
  stderr epsz,     0.45,          1e-8,        5,           inv_gamma_pdf, 0.63,       0.33;
end;

model_diagnostics; steady; check;

stoch_simul(order=1,IRF=0,periods=10000);
save('simdat.mat', options_.varobs{:} );

estimation(datafile='simdat.mat',
           first_obs                 = 5001,
           nobs                      = 100,
           mode_compute              = 4,
           mcmc_jumping_covariance   = hessian,
           mh_replic                 = 2001,
           mh_nblocks                = 4,
           mh_jscale                 = 0.4,
           posterior_sampling_method = 'random_walk_metropolis_hastings',
           posterior_sampler_options = ('proposal_distribution', 'rand_multivariate_student',
                                      'student_degrees_of_freedom', 3)
           );
```

In Dynare, usually, all tasks are single threaded, i.e. they are run on a single core. Let's assume, however, that our machine has 4 CPUs, then the `estimation` command will run one chain after the other one on one core only; the other 3 cores have nothing to do. This is, of course, a waste of time and ressources, as we have 4 chains and 4 CPUs. So let's run these chains in parallel:

```matlab
dynare mymodel parallel
```

The parallelization is done by running several MATLAB or Octave processes in the background, either on local or on remote machines. Communication between master and slave processes are done through SMB on Windows and SSH on UNIX. Input and output data, and also some short status messages, are exchanged through network filesystems. Currently the system works only with homogenous grids: only Windows or only Unix machines. Also only the following routines are parallelized:

- the posterior sampling algorithms when using multiple chains
- the Metropolis-Hastings diagnostics
- the posterior IRFs
- the prior and posterior statistics
- some plotting routines

Nevertheless, we need to set up a configuration file first, which is a bit different for each operating system:

- [Dynare parallel on Windows 10](windows)

- [Dynare parallel on macOS Catalina](macos)

- [Dynare parallel on Ubuntu Linux](ubuntu)
