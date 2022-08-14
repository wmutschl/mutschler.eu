---
title: Dynare parallel
#linktitle: Dynare parallel
summary: This is a quick tutorial on how to use the parallel option in Dynare on Windows, macOS and Linux. The example covers everything you need to set up the config file and provides an example where we estimate a small model using the Random-Walk Metropolis-Hastings with 4 chains computed in parallel.
toc: true
type: book
#date: "2021-08-19"
draft: false
weight: 50
---
***Please feel free to raise any comments or issues on the [website's Github repository](https://github.com/wmutschl/mutschler.eu). Pull requests are very much appreciated.***

## Description
In this quick tutorial, I will cover the necessary steps to run dynare parallel for (i) [Windows](#windows), (ii) [macOS](#macos), and (iii) [Ubuntu Linux](#linux) (which should also work on other Linux distributions). After some general remarks and establishing the example model, where we estimate a small model using the Random-Walk Metropolis-Hastings with 4 chains computed in parallel, I provide the required steps for each operating system. There are also videos below you might find useful to follow.

## General remarks and example model

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
Let's run this mod file:
```matlab
dynare mymodel
```
Note that by default all tasks are single threaded in Dynare (except some MEX files), i.e. they are run on a single core. Let's assume, however, that our machine has 4 CPUs, then the `estimation` command will run each chain sequentially and on core only; this is inefficient as the other 3 cores have nothing to do. Dynare has the ability to run the following tasks in parallel:

- the posterior sampling algorithms when using multiple chains
- the Metropolis-Hastings diagnostics
- the posterior IRFs
- the prior and posterior statistics
- some plotting routines

The parallelization is done by running several MATLAB or Octave processes in the background, either on local or on remote machines.[^1] Communication between master and slave processes are done through SMB on Windows and SSH on UNIX. Input and output data, and also some short status messages, are exchanged through network filesystems. Currently the system works only with homogenous grids: only Windows or only Unix machines. Running Dynare in parallel is actually quite easy:
```matlab
dynare mymodel parallel
```
However, we need to set up a configuration file first, which is a bit different for each operating system. The [manual](https://www.dynare.org/manual/the-configuration-file.html?highlight=parallel) has a dedicated section on how to set up a configuration file for Dynare. We will cover a basic use case, i.e. running stuff in parallel on a local notebook or desktop computer or server, i.e. on `localhost`.

[^1]: In Dynare 4.8 we plan to revise the parallel toolbox and I will update this guide accordingly.


## Windows
{{< youtube QKVm4bKTRbY >}}

### Step 1: PsTools

First you need to download [PsTools](https://docs.microsoft.com/en-us/sysinternals/downloads/pstools) and extract it to an arbitrary folder, e.g. `C:\dynare\PSTools`. Then you have to add this folder to your `PATH`. To this end, use this key combo: `WIN+PAUSE` which will open up a System Settings panel with basic information about your computer. On the left choose `Advanced system settings`, then `Environmental Variables`. Click on `Path` in the User variables section and click on `Edit`. Hit `New` and provide the path to PSTools, e.g. `C:\dynare\PSTools` . Click OK and close all windows. Now open a command prompt and type `psexec` and `psinfo` which should give you a license agreement window which you should agree to. 

### Step 2: Configuration file

Create a new file with a text editor or MATLAB's script editor and call it, for example, `myconf`.

In this file, we need to specify some settings to identify our machine and number of cores to use. Here is an example file:

```
[cluster]
Name = Local
Members = n1

[node]
Name = n1
ComputerName = localhost
CPUnbr = 4
NumberOfThreadsPerJob = 1
```

As we have only one machine, our `cluster` contains only one member `n1`. For each member, we need to specify options in the `node` section. The `name` must correspond to the `Members` declared above. We don't use a remote machine, so we select `localhost` . The most important setting is `CPUnbr` which corresponds to the number of cores you have. You can also (optionally) set the `NumberOfThreadsPerJob` to a number. For instance, if you have 8 cores and set `CPUnbr = 8` and `NumberOfThreadsPerJob=2`, Dynare parallel will run 8/2=4 chains in parallel.

### Step 3: Running dynare parallel

Now we should first test our configuration file by calling:

```
dynare mymodel parallel_test confile=myconf
```

If everything is okay, we can actually do the parallel estimation by calling:

```
dynare mymodel parallel confile=myconf
```

Another hint: If you always use the same configuration file, you can copy your configruation `myconf` into `C:\Users\wmutschl\AppData\Roaming` and rename it to `dynare.ini`. Then you can omit the `conffile` argument to the call above. Note, however, that the `conffile` option is more flexible.


## MacOS

{{< youtube yuB75NmE3Is >}}

### Step 1: Configuration file
Create a new file with a text editor or MATLAB's script editor and call it, for example, `myconf`.

In this file, we need to specify some settings to identify our machine and number of cores to use. Here is an example file:

```
[cluster]
Name = Local
Members = n1

[node]
Name = n1
ComputerName = localhost
CPUnbr = 4
NumberOfThreadsPerJob = 1
MatlabOctavePath=/Applications/MATLAB_R2020a.app/bin/matlab
```

As we have only one machine, our `cluster` contains only one member `n1`. For each member, we need to specify options in the `node` section. The `name` must correspond to the `Members` declared above. We don't use a remote machine, so we select `localhost` . The most important setting is `CPUnbr` which corresponds to the number of cores you have. You can also (optionally) set the `NumberOfThreadsPerJob` to a number. For instance, if you have 8 cores and set `CPUnbr = 8` and `NumberOfThreadsPerJob=2`, Dynare parallel will run 8/2=4 chains in parallel. Note that for MacOS it is important to set the `MatlabOctavePath` pointing to your binary of either MATLAB or Octave.


### Step 2: Running dynare parallel

Now we should first test our configuration file by calling:

```
dynare mymodel parallel_test confile=myconf
```

If everything is okay, we can actually do the parallel estimation by calling:

```
dynare mymodel parallel confile=myconf
```

Another hint: If you always use the same configuration file, you can copy your `myconf` file to `/Users/wmutschl` and rename it to `.dynare` (note that this becomes a hidden file). Then you can omit the `conffile` argument to the call above. Note, however, that the `conffile` option is more flexible.


## Linux

{{< youtube ei8MjNipUyU >}}

### Step 1: Configuration file

Create a new file with a text editor or MATLAB's script editor and call it, for example, `myconf`.

In this file, we need to specify some settings to identify our machine and number of cores to use. Here is an example file:

```
[cluster]
Name = Local
Members = n1

[node]
Name = n1
ComputerName = localhost
CPUnbr = 4
NumberOfThreadsPerJob = 1
```

As we have only one machine, our `cluster` contains only one member `n1`. For each member, we need to specify options in the `node` section. The `name` must correspond to the `Members` declared above. We don't use a remote machine, so we select `localhost` . The most important setting is `CPUnbr` which corresponds to the number of cores you have. You can also (optionally) set the `NumberOfThreadsPerJob` to a number. For instance, on our university cluster (where each node has 72 CPUs) I usually run 72/9=8 MCMC chains in parallel by using the following configuration file:

```
[cluster]
Name = Local
Members = n1

[node]
Name = n1
ComputerName = localhost
CPUnbr = 72
NumberOfThreadsPerJob = 9
```

### Step 2: Running dynare parallel

Now we should first test our configuration file by calling:

```
dynare mymodel parallel_test confile=myconf
```

If everything is okay, we can actually do the parallel estimation by calling:

```
dynare mymodel parallel confile=myconf
```

Another hint: If you always use the same configuration file, you can copy your `myconf` file to `/home/wmutschl` and rename it to `.dynare` (note that this becomes a hidden file). Then you can omit the `conffile` argument to the call above. Note, however, that the `conffile` option is more general and flexible.


