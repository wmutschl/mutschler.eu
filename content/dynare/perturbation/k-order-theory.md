---
title: 'Solving DSGE models with k-order perturbation: what Dynare does'
linktitle: k-order perturbation theory
summary: In this video tutorial we have an in-depth look at k-order perturbation techniques. The first 80 minutes of the video cover the ingredients, notation and mathematical concepts underlying the theory. The second-part goes into a detailed exposition of the algorithmic steps to recover the coefficients of the approximated policy functions. The focus is really on understanding the general algorithm and how the tools and concepts from the first part can be applied. We also cover implementation details in Dynare.
toc: true
type: book
date: "2022-06-15"
draft: false
weight: 1
---
***Please feel free to raise any comments or issues on the [website's Github repository](https://github.com/wmutschl/mutschler.eu). Pull requests are very much appreciated.***

{{< youtube Kncb31hyp2E >}}

## Description
This video is a didactic reference and in-depth review of k-order perturbation.

The first 80 minutes of the video cover the ingredients, notation and mathematical concepts underlying the perturbation approach.

The second-part goes into a detail exposition of the algorithmic steps to recover the coefficients of the approximated policy functions. The focus is really on understanding the general algorithm and how the tools and concepts from the first part can be applied.

We also cover implementation details in Dynare.

Warning: this video is not targeted at beginners or newcomers to DSGE models, but for those who want to understand the perturbation approach in quite some detail.

## Slides
[Presentation](/files/perturbation/perturbation_order_k.pdf)

## Topics

- Dynare Model Framework and Information Set
- Typology and Ordering of Variables
- Declaration vs Decision Rule (DR) Ordering
- Perturbation Ingredients:
  - Perturbation Parameter
  - Policy Function Concept
  - Implicit Function Theorem
  - Taylor Approximations
- Notation:
  - dropping time indices and introducing x for previous states
  - (nested) policy functions for different groups of variables
  - dynamic model in terms of (nested) policy functions
  - input vectors for different functions
- Perturbation Objective:
  - What is the goal?
  - Discussion of assumption of differentiability
- Matrix vs Tensor Notation
  - Pros and Cons
  - What is a Tensor with examples
  - Einstein Summation Notation for Tensors with examples
- Faà di Bruno's formula
  - idea and in terms of Tensors and Einstein Summation Notation
  - Digging into the Notation
  - Equivalence Sets (Bell polynomials)
  - Examples for Fx, Fxu, Fxxu, Fxuu, Fxuup, Fxss (with special treatment of equivalence sets when pointing towards perturbation parameter)
- Tensor Unfolding
  - idea and ordering of columns
  - How to actually do it using matrix multiplication rules, Kronecker products and permutation matrices
  - Examples for Fx, Fxu, Fxxu, Fxuu, Fxuup, Fuss
  - Shortcut to decide when to use permutation matrices
  - Shortcut to decide when to switch terms around due to symmetry
- Perturbation Approximation: Overview of algorithmic steps
- First-order Approximation
  - Doing the Taylor Expansion and Evaluating it
  - Necessary and Sufficient Conditions
  - Recovering gx
    - necessary expressions in both tensor and matrix representation
    - solve a quadratic Matrix equation
  - Important Auxiliary Perturbation Matrices A and B used at higher-orders
  - Recovering gu
    - necessary expressions in both tensor and matrix representation
    - developing terms
    - take inverse of A
  - Recovering gs
    - necessary expressions in both tensor and matrix representation
    - developing terms
    - take inverse of (A+B)
  - Certainty Equivalence at first-order
- Second-order Approximation
  - Doing the Taylor Expansion and Evaluating it
  - Necessary and Sufficient Conditions
  - Recovering gxx
    - necessary expressions in both tensor and matrix representation
    - developing terms
    - Solve Generalized Sylvester Equation
    - how to algorithmically compute the RHS by evaluating a conditional Faà di Bruno formula
  - Recovering guu
    - necessary expressions in both tensor and matrix representation
    - developing terms
    - take inverse of A
    - how to algorithmically compute the RHS by evaluating a conditional Faà di Bruno formula
  - Recovering gxu
    - necessary expressions in both tensor and matrix representation
    - developing terms
    - take inverse of A
    - how to algorithmically compute the RHS by evaluating a conditional Faà di Bruno formula
  - Recovering gxs
    - necessary expressions in both tensor and matrix representation
    - developing terms
    - solving Generalized Sylvester Equation (actually zero RHS)
    - how to algorithmically compute the RHS by evaluating a conditional Faà di Bruno formula
  - Recovering gus
    - necessary expressions in both tensor and matrix representation
    - developing terms
    - take inverse of A (actually zero RHS)
    - how to algorithmically compute the RHS by evaluating a conditional Faà di Bruno formula
  - Recovering gss
    - necessary expressions in both tensor and matrix representation
    - developing terms
    - take inverse of (A+B)
    - level correction for uncertainty
    - how to algorithmically compute the RHS by evaluating a conditional Faà di Bruno formula
- Third-order approximation
  - necessary and sufficient conditions
  - overview of equations that need to be solved by either Generalized Sylvester algorithms or taking inverses
  - linear correction for uncertainty
- k-order Approximation
  - necessary and sufficient conditions
  - order of computation
- Computational Remarks as of Dynare 5.1

## References
- Juillard and Kamenik (2014)
- Levintal (2017)
- Mutschler (2022) - coming soon
- Schmitt-Grohé and Uribe (2004)