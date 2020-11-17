---
title: Dynare parallel on Windows
linktitle: Windows
toc: true
type: book
date: "2020-03-20T00:00:00+01:00"
draft: false

# Prev/next pager order (if `docs_section_pager` enabled in `params.toml`)
weight: 1
---

```md
{{< youtube QKVm4bKTRbY >}}
```

### Step 1: PsTools

First you need to download [PsTools](https://docs.microsoft.com/en-us/sysinternals/downloads/pstools) and extract it to an arbitrary folder, e.g. `C:\dynare\PSTools`. Then you have to add this folder to your `PATH`. To this end, use this key combo: `WIN+PAUSE` which will open up a System Settings panel with basic information about your computer. On the left choose `Advanced system settings`, then `Environmental Variables`. Click on `Path` in the User variables section and click on `Edit`. Hit `New` and provide the path to PSTools, e.g. `C:\dynare\PSTools` . Click OK and close all windows. Now open a command prompt and type `psexec` and `psinfo` which should give you a license agreement window which you should agree to. 

### Step 2: Configuration file

The [manual](https://www.dynare.org/manual/the-configuration-file.html?highlight=parallel) has a dedicated section on how to set up a configuration file for Dynare. We will cover a basic use case, i.e. running stuff in parallel on a local notebook or desktop computer or server, i.e. on `localhost`.

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

As we have only one machine, our `cluster` contains only one member `n1`. For each member, we need to specify options in the `node` section. The `name` must correspond to the `Members` declared above. We don't use a remote machine, so we select `localhost` . The most important setting is `CPUnbr` which corresponds to the number of cores you have. You can also (optionally) set the `NumberOfThreadsPerJob` to a number. For instance, on our university cluster I usually run 8 MCMC chains in parallel by using the following configuration file (note that 72/9=8):

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

### Step 3: Running dynare parallel

Now we should first test our configuration file by calling:

```
dynare mymodel parallel_test confile=myconf
```

If everything is okay, we can actually do the parallel estimation by calling:

```
dynare mymodel parallel confile=myconf
```

Another hint: If you always use the same configuration file, you can copy your configruation `myconf` into `C:\Users\wmutschl\AppData\Roaming` and rename it to `dynare.ini`. Then you can omit the `conffile` argument to the call above. Note, however, that the `conffile` option is more general and flexible.
