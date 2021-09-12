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
library(tidyverse)
library(fs)
library(car)
library(fastDummies)
library(plm)


## WORKING DIRECTORIES ===============================
# setwd('hw1')

## LOAD DATA =========================================
data1_path = path('PS1_data.csv')
data2_path = path('pecanstreet_monthly.csv')
data3_path = path('pecanstreet_daily.csv')
data1 = read.csv(data1_path)
data2 = read.csv(data2_path)
data3 = read.csv(data3_path)


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
print(())

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


data1$custid

Model1 <- lm(kwh ~ yearmonthid, data=data1)
summary(Model1)
plot(Panel$x1, Panel$y, pch=19, xlab="x1", ylab="y")
abline(lm(Panel$y~Panel$x1),lwd=3, col="red")




## SIMPLE APPROACH FOR CLUSTERED DATA ==============================
# Estimate sigma_e (var(epsilon_it))
sigma2_eps = var(data1$kwh)
# Estimate sigma_varepsilon (var(varepsilon_it))
mod1 = lm(kwh ~ factor(custid), data=data1)
sigma2_vareps = var(mod1$residuals)
# Estimate simga_v (var(v_i))
sigma2_v = sigma2_eps - sigma2_vareps
# Estimate rho
rho = sigma2_v / (sigma2_v + sigma2_vareps)

alpha = 0.05
kappa = 0.8
P = 0.5
MDE = 50
J = length(unique(data1$custid))
T = length(unique(data1$yearmonthid))
t_a = qt(alpha, J, lower.tail=FALSE)
t_k = qt(1-kappa, J, lower.tail=FALSE)


J_hat = (t_a + t_k)^2*sigma2_eps/(P*(1-P)*MDE^2)*(rho + (1-rho)/T)
J_hat

MDE_data = (t_a + t_k)/(P*(1-P)*J)^0.5*((rho + (1-rho)/T)*sigma2_eps)^0.5
MDE_data

MDE_data / mean(data1$kwh)













