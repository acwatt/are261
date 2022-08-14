# ARE 261 Fowlie Review (2021)

# 1. Field experimental methods

**Approach 1: Build a structural model** (engineering estimate, e.g. energy efficiency)

- doesn't capture behavioral responses
- often over estimates (overly optimistic assumptions about technology performance)
- imperfections in impementation / installation
- Calibration errors in matching the model to real life structures

**Approach 2: Estimate counterfactual using non-experimental data**

- matching EE adopters and non-adopters using observable covariates
- BUT there remains a lot of unexplained variation in e- consumption, other choices like appliance adoption
- even small differences in unobservable factors/trends can confound the effects we are interested in detecting

**Approach 3: Randomized Control Trial**
- random treatment assignment ensures no systematic variation in unobserved factors across treat/untreated groups
- start with what the ideal experiment would look like



## Fundamentals

### Potential Outcomes Framework

In general, the potential outcome for unit i would depend on the vector of treatment assignments. But the Stable Unit Treatment Value Assumption (SUTVA) assumes each units' potential outcome depends only on their treatment assignment:
$$
Y_i(\vec D)=Y_i(D_i)
$$
The observed outcome for unit i is:
$$
Y_i = Y_i(0) +(Y_i(1)-Y_i(0))D_i
$$
And the unit-level causal effect of the treatment is:
$$
\tau_i = Y_i(1) - Y_i(0)
$$
$\rightarrow$ comparison for the same unit at the same point in time.

Average Treatment Effect: $ATE = \frac{1}{N}\sum\limits_{i=1}^N\tau_i$

- cannot directly observe both outcomes at the same time for a unit, so we cannot directly estimate the treatment effect for each unit.
- Fundamental challenge of causal inference: construct our best estimate of counterfactual outcomes







### Identifying Assumptions

- SUTVA: $\quad Y_i(\vec D)=Y_i(D_i)$

*Assignment Mechanizm:* assigns probabilities to all possible treatment vectors (can depend on covariates $X$ and potential outcomes $Y(0), Y(1)$)

- Conditional probabilties sum to one: 
$\sum_\mathcal D \Pr(D|X,Y(0),Y(1)) = 1$

- Probabilistic assignement: $0<\Pr(D|X,Y_{obs})<1$

- Unconfounded / ignorable assignment (potential outcomes are, conditional on $X$, MAR): $\Pr(D|X,Y(0),Y(1)) = \Pr(D|X)$

*Internal validity:* confidence with which we can state that the impact we estimate was caused by the treatment being evaluated (versus some other factors).

*External validity:* The extent to which a study's results can be generalized/applied to other subjects or settings.

*Construct validity:* The extent to which the experimental treatment mimics the real-world intervention of interest.


**SUTVA Violoations:**
If we can make precise assumptions about how SUTVA is violated, we may be able to apply structure on the problem and estimate how specific SUTVA violations affect our problem. Experiments designed to estimate spillovers can open up an exciting set of research questions.



### Hawthorne Effects
Gosnell, List, Metcalfe (2019)
- Change in behavior due to the awareness of being monitored.


### Imperfect compliance with Assignment
When mandatory assignment fails?
- Estimate the effect of the intent to treat: $E[y(1)|Z=1] - E[y(0)|Z=0]$
- Redefine your population of intereste to include only those whose treatment status you can manipulate (recruit-and-deny, or recruit-and-delay)
- Randomly manipulate the probability of treatment through randomly assigning an encouragment (Randomized Encouragement Design, RED). IV approach to identifying a LATE -- Requires no defires (monotonicity).

Assuming monotonicity of encouragement effects (no defiers), denote the three remaining types of units T as A (Always takers), N (never takers), and C (compliers) each with their own proportion in the population $\pi^t$ for $t\in\{A,N,C\}$.

Intent to Treat effect (ITT) is $E[Y_i|Z_i=1]-E[Y_i|Z_i=0]$. Using the Law of Total Expectation, we can condition on each of the groups:

$$
E[Y_i|Z_i=z]
= \sum\limits_{t\in\{A,N,C\}} E[Y_i|Z_i=z, T=t] \Pr(T=t)
= \sum\limits_{t\in\{A,N,C\}} \pi^t E[Y_i|Z_i=z, T=t]
$$

Recall that $Y_i = Y_i(0)(1-D_i) + Y_i(1) D_i$. \
By the definition of Never Takers, $T=N \implies D_i=0 \implies Y_i=Y_i(0)$. \
Similarly, $T=A \implies D_i=1 \implies Y_i=Y_i(1)$. \
For compliers, $(T=A) \cap (Z_i=z) \implies D_i=z \implies Y_i = Y_i(0)(1-z) + Y_i(1) z$.

Therefore, we can simplify the sum from above to
$$
\begin{aligned}
E[Y_i|Z_i=z] &= \sum\limits_{t\in\{A,N,C\}} \pi^t E[Y_i|Z_i=z, T=t] \\[2em]
&= \pi^A E[Y_i(1)|T=A] + \pi^N E[Y_i(0)|T=N] + \pi^C E[Y_i(0)(1-z) + Y_i(1) z |T=C]
\end{aligned}
$$

Recall that $ITT = E[Y_i|Z_i=1]-E[Y_i|Z_i=0]$, we can see the $T=A$ and $T=N$ terms above will cancel out, leaving only the complier terms left in ITT:
$$
\begin{aligned}
ITT &= E[Y_i|Z_i=1]-E[Y_i|Z_i=0] \\
&= \pi^C E[Y_i(1)|T=C] - \pi^CE[Y_i(0)|T=C]\\
&= \pi^C E[Y_i(1) - Y_i(0)|T=C]
\end{aligned}
$$

So the Intent to Treat effect is just the Local Average Treatment Effect of the compliers, multiplied by the proportion of the compliers in the population.

To estimate the LATE, we first estimate the ITT (first stage), then devide through by $\pi^C$ (second stage). But how do we estimate $\pi^C$?

*Identification Assumptions*
- Ignorable assignment of encouragement
- SUTVA
- Encouragement exclusion restriction: 
$Y_i(D,Z=0)=Y_i(D,Z=1)$
- Monotonicity: $D_{i|Z=1}\geq D_{i|Z=0}\quad\forall i$


> Fowlie, Meredith, Michael Greenstone, and Catherine Wolfram (2018). “Do Energy Efficiency Investments Deliver? Evidence from the Weatherization Assistance Program”, Quarterly Journal of Economics. 
- what is the causal impact of weatherization assistance on energy consumption among participating households in Michigan?
- Randomized encouragement design (30,000 HHs, 25% encouraged)
- Inc. take-up from 1% to 6% (shows low demand in elibible HHs)
- Upfront investment costs are ~2x the EE savings, and only 30% of projected savings
- No evidence of rebound effect (increased winter temps)
- Est. cost of avoided CO2 ~$200/ton

Contributions:
1. Causal evidence on returns to residential EE investments
2. Measure rebound and allow it as a part of returns
3. Provide test of ex ante EE engineering estimates



### Hetergeneous treatment effects
> Knittel and Stolper (2021), “Using Machine Learning to Target Treatment.”
- use causal forests and an adaptive neighborhood estimator to estimate treatment effects of each HH using a weighted average of treatment effects of neighboring HHs
- baseline electricity consumption and HH value seem to be the most important predictors of e- reduction from the Opower reports
- authors advocate that using these predictive techniques to target treatment could increase social welfare significantly
- but what is the parameter uncertainty and how does it affect estimates of the welfare improvements?

### Power Analysis
> Burlig, Preonas, and Woerman (2020) “Panel Data and Experimental Design.”
- derive the variance of panel estimators under arbitrary error structures.
- They give us formulas (and Stata code!) for difference-in-difference estimators that are robust to arbitrary serial correlation

- But simulation-based power analysis is often easier to setup and easier to test multiple complicated designs
- power-maximizing treatment fraction $P$ is 0.5, except when under a budget constraint -- often more expensive to provide treatment so constrained optimal treatment fraction is probably <0.5.



> Berkouwer, Susanna and Joshua Dean (2019). “Credit and Attention in the Adoption of Profitable Energy Efficient Technologies in Kenya.” UC Berkeley Working Paper.
- Randomize access to credit using an incentive-compatible mechinism
- examine role of credit constraints and inattention to under adoption of high-return cookstoves
- access to credit seems to close the energy efficiency gap in this setting (Nairobi) and there is no evidence of inattention to the energy savings of efficient cookstove adoption
- estimate a subsidy for cookstove adoption would have a marginal value of public funds of $19 per $1 spent


> Hahn, Robert W., and Robert D. Metcalfe. 2021. ”Efficiency and Equity Impacts of Energy Subsidies.” American Economic Review. 
- Study a large energy subsidy for low-income HHs: the California Alternate Rates for Energy
- Estimate that, depending on SCC, policy makers would need to weight the benefits of CARE recipients 6-16% more than non-CARE consumers to just break even in socail welfare
- they do a second welfare analysis supposing voucher use instead and define conditions under which vouchers could increase economic efficiency

> Gosnell, List, and Metcalfe, “The Impact of Management Practices on Employee Productivity.”
- Hawthorne productivity effects in Airline Captains
   - Hawthorne Effect: Change in behavior due ot the awareness of being observed or some tangible difference from the observation (compared to usual life) that changes behavior
- Treatments:
   - Monitoring of productivity-related behaviors: increased gains for the firm
   - Performance targets: further increase productivity beyond monitoring alone
   - pro-social incentives: don't appear to affect productivity by increase job satisfaction
- Contributions:
   - Among first to test isolated management practices
   - Monitoring and target provision can increast productivity, even for high-skilled workers in developed countries
   - treatments have potential for additional benefits (employee welfare, GHG emissions, etc)
- One additional takeaway: the existance of the principle-agent problem in this context (manager-employee) $\implies$ that an optimal pigouvian tax on the firms would lead to suboptimal abatement because the employees are not fully internalizing the costs to the firm (since productivity improvements can clearly be made that decrease GHG emissions)


> Carranza, Eliana and Robyn Meeks (2020). “Energy Efficiency and Electricity Reliability”. Review of Economics and Statistics.
- multilevel randomized saturation design: randomize neighborhoods at the transformer level to various levels of CFL subsidy saturation (10%-18%), then randomize HHs to receive the subsidy in each neighborhood
- good for estimating network, spillover, and general equilibrium effects
- peak electricity reduction has non-linear benefits because the way transformers overload, so reducing peak use by a little bit can have large external benefits
- in newly more reliable areas, electricity use may increase, a sort of welfare-improving rebound
- there is spillover in technology adoption (control HHs near treated HHs have more CFLs than control HHs in other neighborhoods)

















#  2. Quasi-experimental IV methods

## IV regressions
- having a large number of instruments relative to the sample size can bias the 2SLS estimator toward the OLS estimator (because $\hat x \to x$). Too many weak instrments is bad!

Assumptions:
- exclusion restriction
- relevance
- if heterogeneous treatment effects: monotonicity

Heterogeneous treatment effects:
- over-identification tests make sense with homogeneous effects
- if hetero: different instruments can identify different local average treatment effects (different subpopulations whose treatment status is affected by the instrument).
- combining multiple instruments in the presence of hetero. treatment effects, 2SLS estimates a mixture of LATEs

**Common IV issues and best practices:**
1. Uninteresting or poorly defined question:
   - pose a clear and interesting economic question
   - make the links between the estimated parameter and the underlying theory explict
   - if hetero. treatment effects are likely: think clearly about which units are affected by the exogenous variation in your instrument.

2. Invalid instruments:
   - Clearly explain the nature of the omitted variables problem and why it could lead to biased estimates.
   - Intuitively explain the rationale behind your IV strategy, including graphs, tables, institutional details.
   - Report 1st stage results
   - Report reducted form results
   - discuss which units are affected by the instrument and how to interpret your LATE

3. Weak instruments
   - Test if the instruments are significant predictors of the potentially endogenous regressors.
   - Report F statistic on instruments you decide to exclude
   - If using multiple instruments, also report the "just identified" estimates using only the "best" instrument.


## Hedonic regressions
**Household sorting**
- HHs sort across neighborhoods according to their wealth and preferences
- Workers sort across jobs (qualifications and preferences)
- Drivers sort across vehicles (budget constraint and preferences)

$\implies$ sorting can reveal information about preferences for attributes that are not direclty traded in markets.

**First stage:**
- Specify the hedonic price function $P(x,q)$. In theory, $\frac{dP}{dq}$ = MWTP for $q$.
- Concerns with estimating amenity levels:
   1. Sparse grid of amenity data (pollution monitors)
   2. Subjective beliefs -- perceived amenity vs actual amenity
   3. Dynamics: purchase decisions may reflect expectations about future amenity values.
- Omitted variables:
   1. different amenities may be spatially correlated because, e.g., wealthy HHs both prefer better air quality and vote to increase public school funding.
   2. Important to isolate exogenous variation in amenity of interest.
   3. Quasi-experimental approaches can offer a way to isolcate exogenous variation but sometimes compromise the ability to interpret econometric estimates as MWTP.
- Standard strategy: analyze transactions before relative to after a change in the spatial distribution of the amenity.
   1. strength: mitigate OVB by isolating quasi-random variation in amenity over time.
   2. Assumes a static price function, but the change in amenity may cause the price function to adjust.
   3. SUTVA violation: control HHs are indirectly treated.
   4. Kuminoff and Pop (2014) show that DiD models yield biased estiamtes of P() and MWTP when the price function shifts over time.
- if we want to evaluate discrete changes in amenities, we need to rely on second stage estimates (which can be confounded by selection bias).

> Nicolai V. Kuminoff and Jaren C. Pope, “Do ‘Capitalization Effects’ for Public Goods Reveal the Public’s Willingness to Pay?,” International Economic Review 55, no. 4 (2014): 1227–50, https://doi.org/10.1111/iere.12088.


**Second Stage:**
- Trace out demand function -- essential for welfare evaluation of non-marginal change in attribute, but more complicated.

*Hedonics Best practices:*
> Kelly C Bishop et al., “Best Practices for Using Hedonic Property Value Models to Measure Willingness to Pay for Environmental Quality,” Review of Environmental Economics & Policy 14, no. 2 (Summer 2020): 260–81, https://doi.org/10.1093/reep/reaa001.


*Which measure of housing value to use?*
> H. Spencer Banzhaf and Omar Farooque, “Interjurisdictional Housing Prices and Spatial Amenities: Which Measures of Housing Prices Reflect Local Public Goods?,” Regional Science and Urban Economics 43, no. 4 (July 2013): 635–48, https://doi.org/10.1016/j.regsciurbeco.2013.03.006.
- median housing values seem to do the poorest, while rental values might be the best option






## Causal Impacts of Air Pollution
- estimates of association between pollution exposure and health outcomes are potentially confounded by OVB, even after regression-adjusting for differences in observables.
- selection bias also possible if people move towards/away from the risk based on sensitivity



> Deryugina, Tatana, Garth Heutel, Nolan H. Miller, David Molitor, and Julian Reif (2019) ”The Mortality and Medical Costs of Air Pollution: Evidence from Changes in Wind Direction.” American Economic Review.
- first large-scale, quasi-experimental estimates of causal effects of short-term, acute PM2.5 exposure on mortality and medical costs.
- covers 97% of US elders 65 and older, and daily pollution data 1999-2013
- use changes in daily wind direction to instrument for PM2.5 changes and effects on mortality
- these IV estimates are significantly larger than OLS estimates, suggesting substantial bias in previous estimates
- use both a LASSO and survival random forest model to predict individual remaining life expectancy; both yeild similar results
- life expectancy, not age, is the best measure of vulnerability to air pollution -- those with less than 1 year expectancy are 30 times more likely to die from pollution than the typical medicare beneficiary (11 years expectancy)
- also use ML approach from Chernozhukov et al. (2018) to examine heterogeneous treatment effects and get similar results, using >1000 variables from medicare health histories.
1. first in econ to use a survival ML model
2. First to apply Chernozhukov et al (2018) to quasi-experimental study design
3. Separately identify the causal effects of multiple pollutants on mortality.



> Chay, Kenneth and  Michael Greenstone (2005). "Does Air Quality Matter? Evidence from the Housing Market," Journal of Political Economy, University of Chicago Press, vol. 113(2), pages 376-424, April.
- use CAA attainment status as IV for TSP changes
- 1 $\mu$g/m$^3$ reduction in TSPs $\implies$ 0.2-0.4 percent increase in mean housing values
- Random coefficients model provides modest evidence for preference-based sorting across space and LATE may underestimate true welfare gains (ATE)
- OVB is a first-order issue when attempting to estimate structural demand parameters in the absence of a credible instrument
- MWTP functions (from hedonic theory) could be obtained and are incredibly important -- they can be used to (1) calculate the welfare effects of nonmarginal changes in goods for which explicity markets are missing and (2) forecast the consequences of alternative policies.
- conventional (cross-sectional and 1st differences) hedonic estimates produce unreliable and perverse/misleading estimates of MWTP

**LATE vs ATE in Hedonic models**
- heterogeneity in tastes $\implies$ individuals may sort into locations based on unobserved differences
- if individuals with lower WTP for air quality sort into lower air-quality locations, the authors identify the average MWTP for a non-random subpopulation (selection bias)
- Chay & Greenstone suggest that LATE is likely biased down compared to ATE in this context.
























# 3.a Differences-in-differences

## Electricity Sector Restructuring and Electricity markets
Market power in power markets - a rich literature..
- Markups and conduct, incentives and ability to exercise
market power Wolfram (1999), Puller (2007), McRae and
Wolak (2012)
- Market performance in deregulated wholesale markets
Borenstein, Bushnell, Wolak (2002), Wolak (2007), BMS
(2008), Mansur (2008)
- Using auction data/framework
- Wolak (2000), Hortascsu and Puller (2008), Reguant (2014)
- Sequential markets, financial traders Saravia (2003), BBKW
(2007), Jha and Woalk (2016), Ito and Reguant (2016),
Mercadal (2016)

> Davis, Lucas W. and Catherine D. Wolfram. 2012. “Deregulation, Consolidation and Efficiency: Evidence from U.S. Nuclear Power,” American Economic Journal: Applied Economics, 2012, 4(4), 194-225 
- Moving away from the traditional regulatory regime yielded efficiency gains in operating performance at nuclear plants.
- A broader lesson: Even modest improvements in operating efficiency can have substantial environmental implications when that technology represents a large share of total generation.
- A related issue is the effect of restructuring on the risk of nuclear accidents. Paper presents weak evidence that one measure of reactor safety may have actually improved with divestiture,

> Cicala, Steve (2022) “Imperfect Markets versus Imperfect Regulation in U.S. Electricity Generation,” American Economic Review.
- Assess the welfare implications of transitions to market-based dispatch over the period 1999-2012.
   - Evaluates the efficiency implications of moving to a regime in which a wholesale electricity market plays a larger role in coordinating dispatch.
- Focuses exclusively on supply-side efficiency (Why ?) Key findings?
    - Estimated gains from trade increase by 55%.
    - Costs from using uneconomical units fall 16%.
- Treated areas: We observe 15 different events in which PCAs have transitioned to market-based dispatch between 1999-2012.
- "Control" areas: Remaining areas (40% of generation capacity) stick with traditional dispatch methods for the duration.
- Identification challenge: Estimate counterfactual unit-level operations/market dispatch using a rich characterization of "control" areas to control for changes that might otherwise bias a simple DID comparison
- Concerns with this gains from trade metric?
    - Gains from trade are calculated as wedges measured on a PCA by PCA basis
    - This approach ignores the full social implications of increased trade across regions. (focused on monetary gains, but there exist possible non-market environmental impacts, like increased coal-burning as a result of trade between PCAs)
    - Emissions implications can be significant if older and under-utilized coal-fired generators increase their generation (and associated emissions) as a result of increased trade between areas.



## Electricity Demand
Why might it be important to focus empirical attention on the demand side?

Implications for...
- Electrification!
- Demand response (resource adequacy, renewables integration)
- Impacts of carbon pricing (incidence)
- Price regulation
- Policy design for low-income programs




> Ito, Koichiro (2014). “Do Consumers Respond to Marginal or Average Price? Evidence from Nonlinear Electricity Pricing.” American Economic Review.
- uses discontinuity at border between different electricity service areas within the same cities that have different non-linear e- prices
- Uses a wieghting function to approximate how consumers would percieve different forms of the price (marginal, expected marginal, average)
- Frequent variation in e- prices makes it hard to believe there is HH sorting in reaction to prices, and consumers don't choose e- providers
- Policymakers claim that shifting from flat price to block non-linear pricing should decrease consumption because marginal price is increasing
- if consumers are reacting to average price, Ito shows that consumption actually increases under block pricing, because low consumption users now have a lower average price and increase use, and high-consumption users only have a slightly higher average price, so the decrease of high-consumption users does not offset the increase of the low-consumption users
- Ito shows consumers appear to be reacting to average price

*Related papers*:
- Deryugina, Tatyana, Alexander MacKay, and Julian Reif. 2020.
"The Long-Run Dynamics of Electricity Demand: Evidence from
Municipal Aggregation." American Economic Journal: Applied
Economics, 12 (1): 86-114.
- Shaffer Blake (2020). "Misunderstanding nonlinear prices:
Evidence from a natural experiment in electricity demand".
American Economic Journal: Economic Policy. 12(3).
79







## Emissions markets and environmental justice

**Carbon Pricing topics**
- Jurisdictional/operational limitations that give rise to incomplete markets.
- Environmental justice/equity concerns
- Uncertainty
- Market power
- Lobbying/political economy considerations
- Dynamics/innovation market failures
- General equilibrium impacts

> Meredith Fowlie, Stephen P Holland, and Erin T Mansur, “What Do Emissions Markets Deliver and to Whom? Evidence from Southern California’s NOx Trading Program,” American Economic Review 102, no. 2 (April 1, 2012): 965–93, https://doi.org/10.1257/aer.102.2.965.
- looked at California NOx emissions cap and trade program RECLAIM
- matched RECLAIM facilities to non-RECLAIM facilities and adjusted for bias
- found 20% reduction in emissions among RECLAIM plants
- did not find evidence that emissions were being reorganized toward low-socio-economic or racial minority communities
- BUT in larger cap and trade programs, all facilities will be treated directly or indirectly, so estimating/interpreting program effects is more nuanced
- policies are not implemented in isolation -- interactions with other policies are hard to disentangle


**Emissions Leakage:**
- In the short run, a shift of production activity and emissions to unregulated
foreign producers.
- Over the long term, firms may relocate to jurisdictions with less stringent
emissions control policies.
- If demand for carbon intensive inputs in the home country is sufficiently large
to affect world energy prices, fuel prices fall, and producers in unregulated
jurisdictions substitute towards these inputs (the GE channel).
- Negative leakage? Policy-induced reduction in green technology costs
accelerates adoption elsewhere.

> Lo Prete, Chiara, Ashis Tyagi, and Qingyu Xu (2021) “California’s cap-and-trade program and emission leakage in the Western Intedrconnection: comparing econometric and partial equilibrium model estimates” 
- match CA CAT regulated power plants to non-CAT regulated power plants in the US to estimate emissions leakage
- hard to believe we have good controls for CA because there have been large changes in CA's energy mix over the time of the study period that are not matched by other regions (nuclear, renewables)



**Equity-oriented concerns about market-based regulation**
- In principle, market-based mechanisms could exacerbate - versus mitigate-
pre-existing exposure inequalities.
- The exibility inherent in market mechanisms could allow plant managers to
make abatement decisions on the basis of political/discriminatory motives
(versus pure cost minimization.
- More affluent neighborhoods may be more effective at pressuring plant
managers to invest in abatement versus purchasing permits.
- Marginal abatement costs may be lower in more affluent neighborhoods
(seems unlikely).
- Conjecture: Economists are too focused on efficiency when it comes to
emissions pricing.
- Economist's defense: Hakuna matata! Efficiency and equity are separable
under carbon pricing (recall the independence property!)
- Catch 1: `Fair' redistribution requires that we can estimate/anticipate the
incidence of a tax or trading policy...not easy!
- Catch 2: Given systemic inequities, disadvantaged groups are rightly
concerned that compensating transfers will not happen.
- Catch 3: Hard to pin down an unambiguous notion of fair and equitable?
- Going forward: (I think) economists need to place more emphasis on equity
implications.



> Hernandez-Cortes, Danae and Kyle Meng (2020). “Do Environmental Markets Cause Environmental Injustice? Evidence from California’s Carbon Market”. NBER WP27205. 




> Mansur, Erin and Glenn Sheriff (2021) “On the measurement of environmental inequality: Ranking emissions distributions generated by different policy instruments.” Forthcoming in the Journal of the Association of Environmental and Resource Economists, 6(5).



## Wildfire 

> Baylis, Patrick and Judd Boomhower (2021) “Building Codes and Community Resilience to Natural Disasters”.

















# 3.b Fixed Effects

















# 4. Discrete Choice Models: Logit

## Discrete Choice modeling fundementals



## Conditional Logit Model



## Applications

> Davis, Lucas (2021) What Matters for Electrification? Evidence from 70 Years of U.S. Home Heating Choices 



> Burgess, Robin, Michael Greenstone, Nicholas Ryan, Anant Sudarshan (2020). “The Role of Decentralized Solar in Completing Indian Electrification”

















# 5. Differentiated product markets

## Mixed Logit: Random taste variation

## Structural models of differentiated product markets - BLP

## Applications

> Grigolon, Laura, Mathias Reynaert, and Frank Verboven (2018). “Consumer Valuation of Fuel Costs and the Effectiveness of Tax Policy - Evidence from the European Car Market”, American Economic Journal: Economic Policy. 



> Ito, Koichiro and Shuang (2019) “Zhang Willingness to Pay for Clean Air: Evidence from Air Purifier Markets in China. Journal of Political Economy.

















# 6. Housing markets and environmental justice

## Neighborhood Choice

## Environmental Justice and hedonic/sorting models

## Applications

> Depro, Brooks, Christopher Timmins, and Maggie O’Neil (2015) ”White Flight and Coming to the Nuisance: Can Residential Mobility Explain Environmental Injustice?,” Journal of the Association of Environmental and Resource Economists 2, no. 3 (September 2015): 439-468. 



> Taylor, Dorceta. “Market Dynamics Residential Mobility, or Who Moves and Who Stays” Toxic Communities: Environmental Racism, Industrial Pollution, and Residential Mobility. NYU Press, 2014.

















# 7. Dynamic discrete choice

## Dynamic discrete choice fundementals

## Review Rust 1987

## Applications

> Bell, Samuel, Kelsey Jack, Chris Severen, Elizabeth Walker (2020). “Technology Adoption under Uncertainty: Take-up and Subsequent Investment in Zambia” The Review of Economics and Statistics. 



> Meredith Fowlie, Mar Reguant, and Stephen P. Ryan (2016). “Market-based Emissions Regulation and Industry Dynamics”. Journal of Political Economy



















# General Advice

## Experiments vs Structural Approaches

- Field experiments can be randomized, but often results can have limited external validity (may have little predictive value beyond the original context)
- Often field experiments are addressing small questions while the big questions are unanswered because they are out of reach of feasible experiments.
- In structural frameworks, the parameters often have clear economic interpretations, whereas field experiments can get sloppy. Experiments designed to estimate spillovers can open up an exciting set of research questions.
- higher detail / frequency data can 

## When thinking about a new model or experiment

- identify what the ideal experiment would be, and what assumptions can match your model to the ideal experiment
- 

## Five steps to understand how structure is used to identify parameters

1. Write down a sensible theoretical model (e.g., production function)
2. Be explicit about what we can and cannot observe
3. Think about the process that gives rise to the structural error. Impose (and hopefully substantiate) assumptions about statistical properties of the structural errors.
4. Derive statistical objects/estimands from the model.
5. Identify parameters that best rationalize the data, conditional on the assumed structure

