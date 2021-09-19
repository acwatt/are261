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
# install.packages("pacman")
# install.packages("car", repos="http://R-Forge.R-project.org")
install.packages("plm")
install.packages("lfe")
library(tidyverse)
library(fs)
library(car)
library(fastDummies)
library(plm)
library(lfe)


## WORKING DIRECTORIES ===============================
# setwd('hw1')

## LOAD DATA =========================================
data1_path = path('PS1_data.csv')
data2_path = path('pecanstreet_monthly.csv')
data3_path = path('pecanstreet_daily.csv')
data1 = read.csv(data1_path)
data2 = read.csv(data2_path)
data3 = read.csv(data3_path)


## SIMPLE APPROACH FOR CLUSTERED DATA ==============================
FE1 = lm(kwh ~ factor(yearmonthid), data=data1)
FE2 = lm(kwh ~ factor(custid) + factor(yearmonthid), data=data1)
sigma2_e = sum(FE1$residuals^2) / (summary(FE1)$df[2] - 1)
sigma2_vare = sum(FE2$residuals^2) / (summary(FE2)$df[2] - 1)
sigma_v = sigma1 - sigma2
rho = sigma2_v / (sigma2_v + sigma2_vare)

alpha = 0.05
kappa = 0.8
P = 0.5
MDE = 0.05*mean(data1$kwh)
J = length(unique(data1$custid))
T = length(unique(data1$yearmonthid))
t_a = qt(alpha/2, J, lower.tail=FALSE)
t_k = qt((1-kappa), J, lower.tail=FALSE)


J_hat = (t_a + t_k)^2*sigma2_eps/(P*(1-P)*MDE^2)*(rho + (1-rho)/T)
J_hat


## SIMULATION ==================================================
simulate <- function(data1, Jlist, Simulations) {
  df = data.frame()
  print(paste('START:', Simulations, "simulations for sample sizes", min(Jlist), 'to', max(Jlist)))
  time_start = Sys.time()
  for (J in Jlist) {
    print(paste(format(Sys.time(), "%X"), ': Starting', Simulations, 'simulations for # households =', J))
    df1 = data.frame()
    for (s in 1:Simulations){
      # Generate sample of J households
      sample_hhs = sample(data1$custid, J, replace=TRUE)
      # line below doesn't work with duplicate households
      # sample = data1[data1$custid %in% sample_hhs, ]
      sample = bind_rows(lapply(sample_hhs, function(i) data1[data1$custid %in% c(i), ]))
      # add new HH ids in case a HH is repeated
      sample$id = rep(1:J, each=24)
      
      # Randomly treat P proportion of the observations
      Jtreat = round(P*J)
      idx = sample(1:J, Jtreat, replace=FALSE)
      sample$kwh_new = sample$kwh
      sample[sample$id %in% idx,]$kwh_new = sample[sample$id %in% idx,]$kwh*(1 - 0.05)
      sample$D = 0
      sample[sample$id %in% idx,]$D  = 1
      
      # Regress
      reg = summary(lm(asinh(kwh_new) ~ D + factor(yearmonthid), data=sample))
      
      # Save p-value of average treatment effect estimate
      coef = coef(reg)['D', 'Estimate']
      pval = coef(reg)['D', 'Pr(>|t|)']
      df2 = data.frame(J=J, coef=coef, pval=pval, reject=(coef < 0 && pval <= 0.05))
      df1 = rbind(df1, df2)
      
    }
    # Save portion of rejected nulls (p < alpha)
    portion = mean(df1$reject)
    print(paste('Portion of simulations that lead to rejecting the null:', portion))
    df = rbind(df, data.frame(J=J, portion=portion))
    if (nrow(df) > 1) {
      # Basic scatter plot
      print(ggplot(df, aes(x=J, y=portion)) +
              labs(title=paste('Proportion of', S, 'simulations rejecting the null when sampling from J households')) +
              geom_line() +
              xlab('J (number of households in sample') +
              ylab(paste('Proportion rejecting the null')) +
              xlim(range(min(Jlist), max(Jlist))))
    }
  }
  print(paste('DONE: Simulation duration:', round((Sys.time() - time_start)/60,2), 'min'))
}

S0 = 10
Jlist0 = seq(from=100, to=200, by=10)
simulate(data1, Jlist0, S0)
S1 = 100
Jlist1 = seq(from=100, to=10000, by=100)
simulate(data1, Jlist1, S1)
S2 = 1000
Jlist2 = seq(from=7000, to=8000, by=10)
simulate(data1, Jlist2, S2)
S3 = 10000
Jlist3 = seq(from=7700, to=7900, by=10)
simulate(data1, Jlist3, S3)


## SIMILATED DATA ====================================
J = 10
T = 20
a = 100
tau = -10
P = 0.5
sigma_v = 5
sigma_d = 7
sigma_w = 3

set.seed(194842)
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

## ESTIMATION ========================================
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













