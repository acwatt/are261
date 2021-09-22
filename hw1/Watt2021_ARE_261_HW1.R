## ---------------------------
## R version 3.6.3 (2020-02-29)
## Script name: hw1.R
##
## Purpose of script: run code necessary for hw1
##
## Author: Aaron Watt
## Email: aaron@acwatt.net
##
## Date Created: 2021-09-07
##
## ---------------------------
## Notes:
##


## PACKAGES ===========================================
install.packages("pacman")
# install.packages("car", repos="http://R-Forge.R-project.org")
# install.packages("plm")
# install.packages("lfe")
# install.packages('latex2exp')
library(pacman)
p_load(car, plm, lfe, latex2exp)
library(car)
library(plm)
library(lfe)
library(latex2exp)
library(tidyverse)
set.seed(194842)


## WORKING DIRECTORIES ===============================
setwd('hw1')

## LOAD DATA =========================================
data1 = read.csv('PS1_data.csv')


## SIMPLE APPROACH FOR CLUSTERED DATA ==============================
library(tidyverse)
FE1 = lm(kwh ~ factor(yearmonthid), data=data1)
FE2 = lm(kwh ~ factor(custid) + factor(yearmonthid), data=data1)
sigma2_vare = sum(FE1$residuals^2) / (summary(FE1)$df[2] - 1)
sigma2_e = sum(FE2$residuals^2) / (summary(FE2)$df[2] - 1)
sigma2_v = sigma2_vare - sigma2_e
rho = sigma2_v / (sigma2_v + sigma2_e)
sigma2_vare
sigma2_e
sigma2_v
rho

alpha = 0.05
kappa = 0.8
P = 0.5
MDE = 0.05*mean(data1$kwh)
T = length(unique(data1$yearmonthid))
t_a = qt(alpha/2, J, lower.tail=FALSE)
t_k = qt((1-kappa), J, lower.tail=FALSE)

J_hat = (t_a + t_k)^2*sigma2_e/(P*(1-P)*MDE^2)*(rho + (1-rho)/T)
J_hat


## SIMULATION ==================================================
# Define a function to run simulations
simulate <- function(data1, Jlist, Simulations, P=0.5, take_up=1) {
  # data1 = dataframe of representative observations to sample from
  # Jlist = list of sample sizes J (number of households)
  # Simulations = Number of simulations to run for each J
  # take_up = fraction of households assigned treatment that take up treatment
  # Start a dataframe to keep track of simulation outputs
  df = data.frame()
  print(paste('START:', Simulations, "simulations for sample sizes", min(Jlist), 'to', max(Jlist)))
  time_start = Sys.time()
  
  # Itererate over a list of sample sizes
  for (J in Jlist) {
    print(paste(format(Sys.time(), "%X"), ': Starting', Simulations, 'simulations for # households =', J))
    df1 = data.frame()
    
    # Run `Simulations` simulations
    for (s in 1:Simulations){
      # Generate sample of J households with replacement
      sample_hhs = sample(data1$custid, J, replace=TRUE)
      sample = bind_rows(lapply(sample_hhs, function(i) data1[data1$custid %in% c(i), ]))
      # create new HH ids in case a HH is repeated
      sample$id = rep(1:J, each=24)
      
      # Randomly treat P proportion of the observations (with take_up% actual being treated)
      Jtreat = round(P*J*take_up)
      idx = sample(1:J, Jtreat, replace=FALSE)
      sample$kwh_new = sample$kwh
      sample[sample$id %in% idx,]$kwh_new = sample[sample$id %in% idx,]$kwh*(1 - 0.05)
      sample$D = 0
      sample[sample$id %in% idx,]$D  = 1
      
      # Regress
      reg = summary(lm(kwh_new ~ D + factor(yearmonthid), data=sample))
      
      # Save p-value of average treatment effect estimate
      coef = coef(reg)['D', 'Estimate']
      pval = coef(reg)['D', 'Pr(>|t|)']
      df2 = data.frame(J=J, coef=coef, pval=pval, reject=(coef < 0 && pval <= 0.05))
      df1 = rbind(df1, df2)

    }
    # Save portion of rejected nulls (p < alpha)
    m = mean(df1$reject)
    se = (m*(1-m)/Simulations)^0.5
    lower = m - 1.96*se
    upper = m + 1.96*se
    print(paste0('Portion of simulations that lead to rejecting the null: ', m,
                ' [', lower,', ', upper, ']'))
    df = rbind(df, data.frame(J=J, portion=m, lower=lower, upper=upper, simulations=Simulations))
  }
  
  print(paste('DONE: Simulation duration:', round((Sys.time() - time_start)/60, 2), 'min'))
  return(df)
}

plotsim <- function(Simulations, Jlist, df, J_hat, take_up=1) {
  png(file=paste0('1-2_simulations_',Simulations, '_', min(Jlist), '-to-', max(Jlist), '_takeup-', take_up, '.png'),
      width=800, height=400)
  xlower = min(Jlist)
  xupper = max(Jlist)
  ylower = min(df$lower)
  yupper = max(df$upper)
  x1 = xlower + 0.1*(xupper - xlower)
  y1 = 0.8 + 0.05*(yupper-ylower)
  x2 = J_hat - 0.12*(xupper - xlower)
  y2 = ylower + 0.1*(yupper-ylower)
  a_size = 6
  print(ggplot(df, aes(x=J, y=portion)) +
          labs(title=paste('Proportion of', Simulations, 'simulations rejecting the null when sampling from J households'),
               subtitle="Shaded area = rough 95% confidence interval of portions") +
          geom_line() +
          xlab('J (number of households in sample') +
          ylab(paste('Proportion rejecting the null')) +
          xlim(range(min(Jlist), max(Jlist))) +
          geom_hline(yintercept=0.8, linetype="dashed", color = "red") +
          annotate("text", x=x1, y=y1, label=TeX("$\\kappa = 0.8$"), size=a_size) +
          geom_vline(xintercept=J_hat, linetype="dashed", color = "red") +
          annotate("text", x=x2, y=y2, label=TeX(sprintf('analytical $\\hat{J} = %d$', round(J_hat))), size=a_size) +
          geom_ribbon(aes(ymin = lower, ymax = upper), alpha = 0.5, linetype="dashed", color="green"))
  dev.off()
}

Jlist0 = seq(from=1000, to=3000, by=500)
sim0 = simulate(data1, Jlist0, Simulations=10)
plotsim(S0, Jlist0, sim0, J_hat)

Jlist1 = seq(from=100, to=3500, by=100)
sim1 = simulate(data1, Jlist1, Simulations=100)
plotsim(S1, Jlist1, sim1, J_hat)

Jlist2 = seq(from=1000, to=3000, by=100)
sim2 = simulate(data1, Jlist2, Simulations=1000)
plotsim(S2, Jlist2, sim2, J_hat)

Jlist3 = seq(from=2700, to=2800, by=10)
sim3 = simulate(data1, Jlist3, Simulations=10000)


# PART 3 -- TAKE UP =============================
# Opt-in design ==> take_up rate of 10%
# Explore the J space
Jlist4 = seq(from=1000, to=20000, by=500)
sim4 = simulate(data1, Jlist4, Simulations=20, take_up=0.10)
plotsim(20, Jlist4, sim4, J_hat/0.1^2, take_up=0.1)
# Hone in on J
Jlist5 = seq(from=7000, to=50000, by=500)
sim5 = simulate(data1, Jlist5, Simulations=100, take_up=0.10)
plotsim(100, Jlist5[1:length(portion_list)], sim5, J_hat/0.1^2, take_up=0.1)

# Stoped sim5 mid-simulation, here's the data
portion_list = c(0.75, 0.77, 0.84, 0.79, 0.83, 0.86, 0.82, 0.91, 0.82, 0.86, 0.85, 0.87, 0.87, 0.91, 0.89, 0.87, 0.87, 0.87, 0.87, 0.9, 0.93, 0.92, 0.96, 0.97, 0.94, 0.97, 0.94, 0.96, 0.96, 0.96, 0.97, 0.97, 0.96, 0.95, 0.97, 0.94, 0.94, 0.97, 0.99, 0.96, 0.96, 0.98, 0.97, 0.99, 0.98, 0.99, 0.97, 0.97, 0.97, 1, 0.97, 0.99, 0.98, 1, 0.99, 1, 0.99, 0.99, 0.99, 1, 0.99, 1, 1, 0.99, 0.99, 0.98, 1)
lower_list = c(0.665129510429125, 0.687516828382997, 0.768145213103092, 0.710167585530688, 0.756375971313708, 0.791990541834242, 0.74469925896779, 0.853908374956684, 0.74469925896779, 0.791990541834242, 0.78001400140028, 0.804084526854463, 0.804084526854463, 0.853908374956684, 0.828673607639125, 0.804084526854463, 0.804084526854463, 0.804084526854463, 0.804084526854463, 0.8412, 0.879991184777082, 0.866826532932298, 0.92159200083316, 0.936564904665905, 0.893452579018811, 0.936564904665905, 0.893452579018811, 0.92159200083316, 0.92159200083316, 0.92159200083316, 0.936564904665905, 0.936564904665905, 0.92159200083316, 0.907282790353301, 0.936564904665905, 0.893452579018811, 0.893452579018811, 0.936564904665905, 0.97049824623271, 0.92159200083316, 0.92159200083316, 0.95256, 0.936564904665905, 0.97049824623271, 0.95256, 0.97049824623271, 0.936564904665905, 0.936564904665905, 0.936564904665905, 1, 0.936564904665905, 0.97049824623271, 0.95256, 1, 0.97049824623271, 1, 0.97049824623271, 0.97049824623271, 0.97049824623271, 1, 0.97049824623271, 1, 1, 0.97049824623271, 0.97049824623271, 0.95256, 1)
upper_list = c(0.834870489570875, 0.852483171617003, 0.911854786896908, 0.869832414469312, 0.903624028686292, 0.928009458165758, 0.89530074103221, 0.966091625043316, 0.89530074103221, 0.928009458165758, 0.91998599859972, 0.935915473145537, 0.935915473145537, 0.966091625043316, 0.951326392360875, 0.935915473145537, 0.935915473145537, 0.935915473145537, 0.935915473145537, 0.9588, 0.980008815222918, 0.973173467067702, 0.99840799916684, 1.00343509533409, 0.986547420981189, 1.00343509533409, 0.986547420981189, 0.99840799916684, 0.99840799916684, 0.99840799916684, 1.00343509533409, 1.00343509533409, 0.99840799916684, 0.992717209646699, 1.00343509533409, 0.986547420981189, 0.986547420981189, 1.00343509533409, 1.00950175376729, 0.99840799916684, 0.99840799916684, 1.00744, 1.00343509533409, 1.00950175376729, 1.00744, 1.00950175376729, 1.00343509533409, 1.00343509533409, 1.00343509533409, 1, 1.00343509533409, 1.00950175376729, 1.00744, 1, 1.00950175376729, 1, 1.00950175376729, 1.00950175376729, 1.00950175376729, 1, 1.00950175376729, 1, 1, 1.00950175376729, 1.00950175376729, 1.00744, 1)
sim5 = data.frame(J=Jlist5[1:length(portion_list)], portion=portion_list, lower=lower_list, upper=upper_list)


# Opt-out design ==> take_up rate of 50%
# Explore the J space
Jlist6 = seq(from=1000, to=7000, by=100)
sim6 = simulate(data1, Jlist6, Simulations=20, take_up=0.50)
plotsim(20, Jlist6, sim6, J_hat/0.5^2, take_up=0.5)
# Hone in on J
Jlist7 = seq(from=2000, to=6000, by=100)
sim7 = simulate(data1, Jlist7, Simulations=100, take_up=0.50)
plotsim(100, Jlist7, sim7, J_hat/0.5^2, take_up=0.5)




## QUESTION 2: PANEL DATA ===================================
library(lfe)  # fixed effects
library(latex2exp)  # greek text
library(tidyverse)  # data manipulation (like rbind)
set.seed(194842)

# Define a function to run simulations
simulate2 <- function(data, MDElist, Simulations, P=0.5, take_up=1, sample_size=97, day_or_month='day') {
  # data = dataframe of representative observations to sample from
  # MDElist = list of sample sizes J (number of households)
  # Simulations = Number of simulations to run for each J
  # take_up = fraction of households assigned treatment that take up treatment
  # Start a dataframe to keep track of simulation outputs
  df = data.frame()
  print(paste('START:', Simulations, "simulations for MDE sizes", min(MDElist), 'to', max(MDElist)))
  time_start = proc.time()
  
  # Itererate over a list of sample sizes
  for (MDE in MDElist) {
    print(paste(format(Sys.time(), "%X"), ': Starting', Simulations, 'simulations for MDE =', MDE))
    df1 = data.frame()
    
    # Run `Simulations` simulations
    for (s in 1:Simulations){
      # Generate sample of J households with replacement
      sample_hhs = sample(data$hhid, sample_size, replace=TRUE)
      sample = bind_rows(lapply(sample_hhs, function(i) data[data$hhid %in% c(i), ]))
      # create new HH ids in case a HH is repeated
      obs_per_hh = 24
      sample$time = sample$month
      if (day_or_month=='day') {
        obs_per_hh = 2*365
        sample$time = sample$day
      }
      sample$HHid = rep(1:sample_size, each=obs_per_hh)
      
      # Treat second year of observations
      sample[sample$year == 2014,]$kwh = sample[sample$year == 2014,]$kwh*(1 - MDE)
      sample$treat = ifelse(sample$year == 2014, 1, 0)
      
      # Regress
      # reg = summary(lm(kwh ~ D + factor(t) + factor(hhid), data=sample))
      reg = summary(felm(kwh ~ treat | time + HHid, data=sample))
      
      # Save p-value of average treatment effect estimate
      coef = coef(reg)['treat', 'Estimate']
      pval = coef(reg)['treat', 'Pr(>|t|)']
      df2 = data.frame(MDE=MDE, coef=coef, pval=pval, reject=(coef < 0 && pval <= 0.05))
      df1 = rbind(df1, df2)
      
    }
    # Save portion of rejected nulls (p < alpha)
    m = mean(df1$reject)
    se = (m*(1-m)/Simulations)^0.5
    lower = m - 1.96*se
    upper = m + 1.96*se
    print(paste0('Portion of simulations that lead to rejecting the null: ', m,
                 ' [', lower,', ', upper, ']'))
    df = rbind(df, data.frame(MDE=MDE, portion=m, lower=lower, upper=upper, simulations=Simulations))
  }
  
  print(paste('DONE: Simulation duration:', round((proc.time() - time_start)[3]/60, 2), 'min'))
  return(df)
}

plotsim2 <- function(df, day_or_month) {
  Simulations = df$simulations[1]
  xlower = min(df$MDE)
  xupper = max(df$MDE)
  ylower = min(df$lower)
  yupper = max(df$upper)
  x1 = xlower + 0.1*(xupper - xlower)
  y1 = 0.8 + 0.05*(yupper-ylower)
  a_size = 6
  
  png(file=paste0('2-2_', day_or_month, '_simulations_',Simulations, '_', xlower, '-to-', xupper, '.png'), width=800, height=400)
  print(ggplot(df, aes(x=MDE, y=portion)) +
          labs(title=paste('Proportion of', Simulations, 'simulations rejecting the null when applying MDE'),
               subtitle="Shaded area = rough 95% confidence interval of portions") +
          geom_line() +
          xlab('MDE (simulated treatment effect size)') +
          ylab(paste('Proportion rejecting the null')) +
          xlim(range(xlower, xupper)) +
          geom_hline(yintercept=0.8, linetype="dashed", color = "red") +
          annotate("text", x=x1, y=y1, label=TeX("$\\kappa = 0.8$"), size=a_size) +
          geom_ribbon(aes(ymin = lower, ymax = upper), alpha = 0.5, linetype="dashed", color="green"))
  dev.off()
}

data_monthly = read.csv('pecanstreet_monthly.csv')
data_daily = read.csv('pecanstreet_daily.csv')

# Monthly
MDElistmonth = seq(from=0, to=0.04, by=0.001)
mde_sim_month = simulate2(data_monthly,  MDElistmonth, Simulations=100, day_or_month='month')
plotsim2(mde_sim_month, 'month')

# Daily
MDElistday = seq(from=0, to=0.02, by=0.0005)
mde_sim_day = simulate2(data_daily,  MDElistday, Simulations=100, day_or_month='day')
plotsim2(mde_sim_day, 'day')







## Synthetic data to help understand modeling ===============
x <- rnorm(20)
df <- data.frame(x = x,
                 y = x + rnorm(20))

plot(y ~ x, data = df)

# model
mod <- lm(y ~ x, data = df)

# predicts + interval
newx <- seq(min(df$x), max(df$x), length.out=100)
preds <- predict(mod, newdata = data.frame(x=newx), 
                 interval = 'confidence')

# plot
plot(y ~ x, data = df, type = 'n')
# add fill
polygon(c(rev(newx), newx), c(rev(preds[ ,3]), preds[ ,2]), col = 'grey80', border = NA)
# model
abline(mod)
# intervals
lines(newx, preds[ ,3], lty = 'dashed', col = 'red')
lines(newx, preds[ ,2], lty = 'dashed', col = 'red')


## SIMILATED DATA ====================================
J = 10
T = 20
a = 100
tau = -10
P = 0.5
sigma_v = 5
sigma_d = 7
sigma_w = 3

alpha = rep(a, T)
d = rnorm(T, mean=0, sd=sigma_d)


df = data.frame()
for (j in 1:J) {
  D = sample(c(0,1), replace=TRUE, size=T)
  v = rnorm(T, mean=0, sd=sigma_v)
  w = rnorm(T, mean=0, sd=sigma_w)
  df_temp = data.frame(alpha, D, v, d, w, j=j, t=1:T)
  df = rbind(df, df_temp)
}

df <- dummy_cols(df, select_columns = c('j', 't'))
df$Y = df$alpha + tau*df$D + df$v + df$d + df$w
df_fe <- subset(df, select = -c(j, t, alpha, v, d, w))

Model0 <- lm(Y ~ 1, data=df)
Model1 <- lm(Y ~ D, data=df)
Model2 <- lm(Y ~ ., data=df_fe)
Model2b <- lm(Y ~ D + factor(j) + factor(t), data=df)
Model3 <- plm(Y ~ D, data=df, index = c("j", "t"), model = "pooling")
summary(Model0)
var(Model0$residuals)
(summary(Model3)$sigma)**2
var(df$Y)
summary(Model1)
summary(Model2)
sum3 = summary(Model3)
coef(Model3)

## ESTIMATION OF PANEL DATA POWER CALCULATION from Burlig et al. ================================
# png('scatter1.png')
# scatterplot(kwh ~ yearmonthid | custid, boxplots=FALSE, smooth=TRUE, reg.line=FALSE, data=data1)
# dev.off()

sigma2_w_hat = var(summary(lm(Y ~ factor(custid) + factor(yearmonthid), data=data1))$residuals)

## ESTIMATE COVARIANCES FROM Appendix D.1 of Burlig et al. 2020
# STEP 1
# Determine all feasible ranges of experiments with (m + r) periods
# We will have r=24 post-treatment periods in the actual experiment (m=0)
# There are 24 periods in the dataset, so only one feasible range

# STEP 2.a
# Regress the outcome variable on unit and time-period fixed effects and store the residuals
model0 = lm(Y ~ factor(custid) + factor(yearmonthid), data=data1)
model0resids = summary(model0)$residuals

# STEP 2.b
# Store the variance of the residuals
sigma2_w_hat = var(model0resids)
print(sigma2_w_hat)
varhat = 1/(nrow(model0resids)-2)

# STEP 2.c
# For each pair of pre-treatment periods... skip since there are no pre-treatment periods

# STEP 2.d
# For each pair of post-treatment periods, calculate the covariance between 
# these periods’ residuals.
covs = c()
for (t in 1:T-1) {
  for (s in t+1:T) {
    e_t = model0resids[data1$custid == t, ]
    e_s = model0resids[data1$custid == s, ]
    covs = c(covs, cov(e_t, e_s))
  }
}
# Save an unweighted average of these r(r − 1)/2 covariances
psiA_w_hat = mean(covs)

# STEP 2.e
# For each pair of pre- and post-treatment periods... skip

# STEP 3
# Calculate the average of each of the estimated covariances for all possible
# ranges of time periods.
# Done -- only one possilbe range of 24 time periods, so calculated values of
# sigma2_w_hat and  psiA_w_hat are the avereages.

# STEP 4
# Plug in the values!
MDE = 0.05  # 5%, the treatment effect to detect
J_start = 100  # lower bound of search for min. number of units needed
alpha = 0.05  # signifcance level
kappa = 0.8
P = 0.5
m = 0
r = 24
MDEthreshold = 0.01

J = J_start - 1
while (MDEdiff > MDEthreshold)
{
  J = J + 1
  print(c("J = ", J))
  t_a = qt(alpha, J, lower.tail=FALSE)
  t_k = qt(1-kappa, J, lower.tail=FALSE)
  term1 = 1/(P*(1-P)*J)
  # Equation (2)
  #######################################################################################
  #Can't use this formula without pre-treatment periods
  #######################################################################################
  MDEdiff = (t_a + t_b)( term1 * () )
  print(c("MDEdiff = ", MDEdiff))
}

Model1 <- lm(kwh ~ yearmonthid, data=data1)
summary(Model1)
plot(Panel$x1, Panel$y, pch=19, xlab="x1", ylab="y")
abline(lm(Panel$y~Panel$x1),lwd=3, col="red")













