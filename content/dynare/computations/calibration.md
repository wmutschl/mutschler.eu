---
title: How to calibrate your model
linktitle: Calibration
toc: true
type: book
date: "2020-04-28T00:00:00+01:00"
draft: false
math: true

# Prev/next pager order (if `docs_section_pager` enabled in `params.toml`)
weight: 1
---
In this tutorial we will discuss how to calibrate DSGE models using the usual approach *those are the values commonly used in the literature*, but also more elaborate ways by targeting specific flippin variables and also using dynare sensitivity toolbox. First, we will discuss the [RBC model](rbc), we already derived.

## Common way: 
In most papers, people rely on the calibration found in other papers. While this approach gives mean to compare results across papers, it lacks the exact reasoning for the specific value. Nevertheless, 
Also dynare_sensitivity What is the domain of structural coefficients assuring the stability and determinacy of a DSGE model?

## Calibration
General hints: construct and parameterize the model such, that it corresponds to certain properties of the true economy. One often uses steady state characteristics for choosing the parameters in accordance with observed data. For instance, long-run averages (wages, working-hours, interest rates, inflation, consumption-shares, government-spending-ratios, etc.) are used to fix steady state values of the endogenous variables, which implies values for the parameters. You can use also use micro-studies, however, one has to be careful about the aggregation!

We will focus on OECD countries and discuss one **possible** way to calibrate the model parameters (there are many other ways):
### Productivity parameter of capital $\boldsymbol{\alpha}$
Due to the Cobb Douglas production function this should be equal to the proportion of capital income to total income of economy. So, one looks inside the national accounts for OECD countries and sets $\alpha$ to 1 minus the share of labor income over total income. For most OECD countries this implies a range of 0.25 to 0.35.

### $\boldsymbol{\beta}$ subjective intertemporal preference rate of households
This is the value of future utility in relation to present utility. Usually takes a value slightly less than unity, indicating that agents discount the future. For quarterly data, we typically set it around 0.99. A better way: fix this parameter by making use of the Euler equation in steady state: $\beta = \frac{1}{\bar{R}+1-\delta}$ where $\bar{R}=\alpha \frac{\bar{Y}}{\bar{K}}$ Looking at OECD data one usually finds that average capital productivity $\bar{K}/\bar{Y}$ is in the range of $9$ to $10$.

### $\boldsymbol{\delta}$ depreciation rate of capital stock
For quarterly data the literature uses values in the range of 0.02 to 0.03. A better way: use steady state implication that $\delta=\frac{\bar{I}}{\bar{K}}=\frac{\bar{I/Y}}{\bar{K/Y}}$. For OECD data one usually finds that average ratio of investment to output, $\bar{I}/\bar{Y}$, is around 0.25.

### $\boldsymbol{\gamma}$ and $\boldsymbol{\psi}$: individual's preferences regarding consumption and leisure
Often a certain interpretation in terms of elasticities of substitutions is possible. Here we can make use of the First-Order-Conditions in steady state, i.e.
$$\frac{\psi}{\gamma} = \bar{W}\frac{(1-\bar{L})}{\bar{C}}= (1-\alpha)\left(\frac{\bar{K}}{\bar{L}}\right)^\alpha\frac{(1-\bar{L})}{\bar{C}} = (1-\alpha)\left(\frac{\bar{K}}{\bar{L}}\right)^\alpha\frac{\frac{1}{\bar{L}}(1-\bar{L})}{\frac{\bar{C}}{\bar{L}}}$$
and noting that $\bar{C}/\bar{L}$ as well as $\bar{K}/\bar{L}$ are given in terms of already calibrated parameters (see steady state computations). Therefore, one possible way is to normalize one of the parameters to unity (e.g. $\gamma=1$) and calibrate the other one in terms of steady state ratios for which we would only require to calibrate steady state hours worked $\bar{L}$. Note that labor time is normalized and usually corresponds to 8 hours a day, i.e. $\bar{L}=1/3$.

### $\boldsymbol{\rho_A}$ and $\boldsymbol{\sigma_A}$ parameters of process for total factor productivity
These can be estimated based on a regression of the Solow Residual, i.e. production function residuals. $\rho_A$ is mostly set above 0.9 to reflect persistence of the technological process and $\sigma_A$ around $0.6$ in the simple RBC model. Another way would be to try different values for $\sigma_A$ and then try to match the shape of impulse-response-functions of corresponding (S)VAR models.