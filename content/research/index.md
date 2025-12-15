# Working Papers

#### Pruned skewed Kalman filter and smoother with applications to DSGE models
[Journal of Economic Dynamics and Control](), revise and resubmit, with Gaygysyz Guljanov and Mark Trede.

[November 2025](/files/papers/GuljanovMutschlerTrede_PSKF.pdf) |
[January 2025](/files/papers/GuljanovMutschlerTrede_PSKF_2025_Jan.pdf) |
[Online Appendix](/files/papers/GuljanovMutschlerTrede_PSKF_Online_Appendix.pdf) |
[Codes](https://github.com/wmutschl/pruned-skewed-kalman-paper) |
[Dynare Toolbox](https://git.dynare.org/wmutschl/dynare/-/tree/pskf) |
[CQE Working Paper 101](https://www.wiwi.uni-muenster.de/cqe/sites/cqe/files/CQE_Paper/cqe_wp_101_2022.pdf) |
[Dynare Working Paper 78](https://www.dynare.org/wp-repo/dynarewp078.pdf)

<details class="abstract"><summary>Abstract</summary><div class="abstract-body">
The skewed Kalman filter (SKF) extends the classical Gaussian Kalman filter by accommodating asymmetric error distributions in linear state-space models. We introduce a computationally efficient method to mitigate the curse of increasing skewness dimensions inherent in the SKF. By analyzing skewness propagation in state-space systems, we develop the pruned skewed Kalman filter (PSKF), which eliminates elements in cumulative distribution functions that do not significantly impact asymmetry beyond a specified threshold. Extensive simulations on univariate and multivariate state-space models validate the PSKF's accuracy and efficiency. Additionally, we derive the skewed Kalman smoother and its pruned variant, applying them to estimate a New Keynesian DSGE model using US data via standard maximum likelihood and Bayesian MCMC methods. Results strongly favor skewed distributions, particularly for productivity and monetary policy shocks.
</div></details>

# Publications

#### The Price of War
[American Economic Review](https://www.aeaweb.org/) cond. accepted, with Jonathan Federle, André Meier, Gernot J. Müller, and Moritz Schularick.

[June 2025](/files/papers/Price_of_War_2025.pdf) |
[September 2024](/files/papers/Price_of_War_2024.pdf) |
[Code](https://github.com/wmutschl/price-of-war) |
[CEPR Discussion Paper 18834](/files/papers/Price_of_War_2024_CEPR.pdf) |
[Kiel Working Papers 2262](/files/papers/Price_of_War_2024_Kiel_Working_Paper.pdf) |
[Finance & History Podcast](https://creators.spotify.com/pod/show/carmen-hofmann/episodes/The-Price-of-War-e2ltfdq)

<details class="abstract"><summary>Abstract</summary><div class="abstract-body">
We assemble a new data set spanning 150 years and 60 countries to study the economic toll of war. A war of average intensity is associated with an output drop of close to 10 percent in the war-site economy, while consumer prices rise by approximately 20 percent. The capital stock, total factor productivity, and equity returns all decline sharply. The economic ramifications of war are not confined to the war site. The evidence points to adverse economic outcomes in other belligerent and third-party countries if they are exposed to the war site through trade linkages or share a common border.
</div></details>

#### Ökonomische Folgen: Was Kriege die Welt kosten
[Wirtschaftsdienst](https://doi.org/10.2478/wd-2024-0075) 104(4), April 2024, with Jonathan Federle, André Meier, Gernot J. Müller, and Moritz Schularick.

[Published version](/files/papers/Price_of_War_2024_Wirtschaftsdienst.pdf) | [Kiel Policy Brief 171](/files/papers/Price_of_War_2024_Kiel_Policy_Brief.pdf) | [Price of War Calculator](https://priceofwar.org/)

<details class="abstract"><summary>Abstract</summary><div class="abstract-body">
Amid escalating geopolitical tensions, we offers insights into the far-reaching consequences of wars. Based on a new dataset on major conflicts since 1870, the findings show that wars cause a substantial decline in GDP and spike in inflation within war zones. Interestingly, countries geographically close to war zones experience significant economic disruptions, even when neutral to the conflict, whereas countries far from the conflict may see minimal to slightly positive spillovers. The study demonstrates how wars represent a massive negative supply shock, with geographical proximity and trade integration explaining the varying effects on different countries.
</div></details>

#### The effect of observables, functional specifications, model features and shocks on identification in linearized DSGE models
[Economic Modelling](https://doi.org/10.1016/j.econmod.2019.09.039) 88, June 2020, with Sergey Ivashchenko.

[Published version](/files/papers/Ivashchenko_Mutschler_2019_EcoMod.pdf) | [Code](https://github.com/wmutschl/ReplicationDSGEHOS) | [CQE Working Paper 83](https://www.wiwi.uni-muenster.de/cqe/sites/cqe/files/CQE_Paper/cqe_wp_83_2019.pdf) | [SFB823 Discussion Paper 7616](http://dx.doi.org/10.17877/DE290R-17433)

<details class="abstract"><summary>Abstract</summary><div class="abstract-body">
The decisions a researcher makes at the model building stage are crucial for parameter identification. This paper contains a number of applied tips for solving identifiability problems and improving the strength of DSGE model parameter identification by fine-tuning the (1) choice of observables, (2) functional specifications, (3) model features and (4) choice of structural shocks. We offer a formal approach based on well-established diagnostics and indicators to uncover and address both theoretical (yes/no) identifiability issues and weak identification from a Bayesian perspective. The concepts are illustrated by two exemplary models that demonstrate the identification properties of different investment adjustment cost specifications and output-gap definitions. Our results provide theoretical support for the use of growth adjustment costs, investment-specific technology, and partial inflation indexation.
</div></details>

#### Higher-order statistics for DSGE models
[Econometrics and Statistics](https://doi.org/10.1016/j.ecosta.2016.10.005) 6, April 2018.

[Published version](/files/papers/Mutschler_2018_EcoSta.pdf) | [Online Appendix](/files/papers/Mutschler_2018_EcoSta_Appendix.pdf) | [Code](https://github.com/wmutschl/ReplicationDSGEHOS) | [CQE Working Paper 43](https://www.wiwi.uni-muenster.de/cqe/sites/cqe/files/CQE_Paper/CQE_WP_43_2015.pdf) | [SFB823 Discussion Paper 4816](http://dx.doi.org/10.17877/DE290R-17259)

<details class="abstract"><summary>Abstract</summary><div class="abstract-body">
Closed-form expressions for unconditional moments, cumulants and polyspectra of order higher than two are derived for non-Gaussian or nonlinear (pruned) solutions to DSGE models. Apart from the existence of moments and white noise property no distributional assumptions are needed. The accuracy and utility of the formulas for computing skewness and kurtosis are demonstrated by three prominent models: the baseline medium-sized New Keynesian model used for empirical analysis (first-order approximation), a small-scale business cycle model (second-order approximation) and the neoclassical growth model (third-order approximation). Both the Gaussian as well as Student’s t-distribution are considered as the underlying stochastic processes. Lastly, the efficiency gain of including higher-order statistics is demonstrated by the estimation of a RBC model within a Generalized Method of Moments framework.
</div></details>

#### Local Identification of Nonlinear and Non-Gaussian DSGE Models
[Wissenschaftliche Schriften der WWU Münster](https://nbn-resolving.de/urn:nbn:de:hbz:6-97219489383) Reihe IV, Bd. 10, February 2016. Monsenstein und Vannerdat.

[PhD Thesis (ISBN 978-3-8405-0135-7)](/files/papers/Mutschler2016PhDThesis.pdf)

<details class="abstract"><summary>Abstract</summary><div class="abstract-body">
This thesis adds to the literature on the local identification of nonlinear and non-Gaussian DSGE models. It gives applied researchers a strategy to detect identification problems and means to avoid them in practice. A comprehensive review of existing methods for linearized DSGE models is provided and extended to include restrictions from higher-order moments, cumulants and polyspectra. Another approach, established in this thesis, is to consider higher-order approximations. Formal rank criteria for a local identification of the deep parameters of nonlinear or non-Gaussian DSGE models, using the pruned state-space system are derived. The procedures can be implemented prior to estimating the nonlinear model. In this way, the identifiability of the Kim (2003) and the An and Schorfheide (2007) model are demonstrated, when solved by a second-order approximation.
</div></details>

#### Identification of DSGE models - The effect of higher-order approximation and pruning
[Journal of Economic Dynamics and Control](https://doi.org/10.1016/j.jedc.2015.04.007) 56(1), July 2015.

[Published version](/files/papers/Mutschler_2015_JEDC.pdf) | [Code](https://github.com/wmutschl/ReplicationDSGENonlinearIdentification) | [CQE Working Paper 33](https://www.wiwi.uni-muenster.de/cqe/sites/cqe/files/CQE_Paper/CQE_WP_33_2014.pdf)

<details class="abstract"><summary>Abstract</summary><div class="abstract-body">
This paper shows how to check rank criteria for a local identification of nonlinear DSGE models, given higher-order approximations and pruning. This approach imposes additional restrictions on (higher-order) moments and polyspectra, which can be used to identify parameters that are unidentified in a first-order approximation. The identification procedures are demonstrated by means of the Kim (2003) and the An and Schorfheide (2007) models. Both models are identifiable with a second-order approximation. Furthermore, analytical derivatives of unconditional moments, cumulants and corresponding polyspectra up to fourth order are derived for the pruned state-space.
</div></details>