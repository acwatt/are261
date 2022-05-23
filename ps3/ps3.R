## ----setup, include=FALSE-------------------------------------------------------------------------------------------------------------------------------------------------
knitr::opts_chunk$set(echo = TRUE)


## ----Settings, echo=FALSE-------------------------------------------------------------------------------------------------------------------------------------------------
# stargazer table type (html, latex, or text)
# Change to latex when outputting to PDF, html when outputting to html
table_type = "latex"
cache_chunks = T
fig_h = 3.5
fig_w = 6


## ----packages, include=F, eval=T------------------------------------------------------------------------------------------------------------------------------------------
library(tidyverse)
library(haven)
library(fs)  # file handling
library(Hmisc)  # adding labels to data
library(latex2exp)  # latex in strings
library(stargazer)  # tables
library(rddtools)  # Regression discontinuity

plot_theme1 = theme(legend.title = element_blank(),
                    legend.box.margin = margin(-0.3, 0, -0.1, 0, "cm"),
                    legend.background = element_blank(),
                    legend.box.background = element_rect(colour = "black"),
                    panel.grid.major.x = element_blank(),
                    panel.grid.major.y = element_line( size=.1, color="grey" ),
                    axis.line.x = element_line(size=0.5, color='black'),
                    axis.line.y = element_line(size=0.5, color='black'),
                    plot.background = element_blank())


## ----Load Data, results='hide', echo=F, warning=F, message=F, cache=cache_chunks------------------------------------------------------------------------------------------
# Data labels
variable_labels_df = read.csv('datadefinitions.csv')
variable_labels <- setNames(as.character(variable_labels_df$Definition), variable_labels_df$Variable)
# Participating states
states_df = read_csv('nbp_states.csv', show_col_types=F) %>%
    left_join(., read_csv('state_abbr_lookup.csv', show_col_types=F), by = c('state' = 'State'))
# load data
data = bind_rows(lapply(dir_ls('./data/', recurse=T, regexp='emission_(.)*(.csv)'), read_csv, show_col_types=F)) %>%
    Hmisc::upData(., labels = variable_labels) %>%
    mutate(nbp = ifelse(State %in% states_df$Postal, 1, 0))  # NBP participating states


## ----Create Variables, include=F, cache=cache_chunks----------------------------------------------------------------------------------------------------------------------
df = data %>%
    select(State, 'Facility ID (ORISPL)', Date, Year, 'NOx (tons)', County, 'Operating Time', nbp) %>%
    rename(state=State, id='Facility ID (ORISPL)', date=Date, year=Year, nox='NOx (tons)', county=County, operating_time='Operating Time') %>%
    mutate(day_of_year = lubridate::yday(date),
           day_of_week = lubridate::wday(date, label=T, week_start=3),  # reference category = Wednesday
           month = lubridate::month(date),
           nox = ifelse(operating_time==0 & is.na(nox), 0, nox)) %>%
    filter(!is.na(nox))


## ----total daily mean nox, include=F, cache=cache_chunks------------------------------------------------------------------------------------------------------------------
# OLS regression of NOx emissions on six day-of-week indicators and a constant
# reference category = Wednesday
reg_fig1 = lm(nox ~ day_of_week, data=df %>% filter(nbp == 1))
# nox_hat = constant plus the regression residuals
df_daily_sums = df %>% 
    filter(nbp == 1) %>%  # filter in only NBP participating states
    mutate(nox_hat = reg_fig1$coefficients['(Intercept)'] + reg_fig1$residuals) %>%
    group_by(day_of_year, year) %>%
    summarise(nox_daily_sum = sum(nox_hat, na.rm=T)/1000)


## ----data: 2005 aggregation, echo=F, results='hide'-----------------------------------------------------------------------------------------------------------------------
df_2005_agg = df %>%
    filter(year == 2005, nbp == 1) %>%
    group_by(day_of_year) %>% 
    summarise(nox_daily_sum = sum(nox, na.rm=T)/1000,
              year = mean(year), month=mean(month)) %>%
    mutate(ozone_season = if_else(day_of_year %in% lubridate::yday('2005-05-01'):lubridate::yday('2005-09-30'), 1, 0)) %>%
    Hmisc::upData(., labels = list(nox_daily_sum = "Sum of daily avg NOx emissions from NBP states (1000s of tons)"))


## ----May regression constant only, echo=F---------------------------------------------------------------------------------------------------------------------------------
reg_poly1 = df_2005_agg %>% 
    filter(month %in% c(4,5)) %>%
    rdd_data(nox_daily_sum, day_of_year, data=.,
             cutpoint=lubridate::yday('2005-05-01')) %>%
    rdd_reg_lm(slope = "same", order = 2)

poly1_coef = reg_poly1$coefficients[2]


## ----Sept regression constant only, echo=F--------------------------------------------------------------------------------------------------------------------------------
reg_poly2 = df_2005_agg %>% 
    filter(month %in% c(9,10)) %>%
    rdd_data(nox_daily_sum, day_of_year, data=.,
             cutpoint=lubridate::yday('2005-10-01')) %>%
    rdd_reg_lm(slope = "same", order = 2)

poly2_coef = reg_poly2$coefficients[2]


## ----May regression separate trends, echo=F-------------------------------------------------------------------------------------------------------------------------------
reg_poly3 = df_2005_agg %>% 
    filter(month %in% c(4,5)) %>%
    rdd_data(nox_daily_sum, day_of_year, data=.,
             cutpoint=lubridate::yday('2005-05-01')) %>%
    rdd_reg_lm(slope = "separate", order = 2)

poly3_coef = reg_poly3$coefficients[2]


## ----Sept regression separate trends, echo=F------------------------------------------------------------------------------------------------------------------------------
reg_poly4 = df_2005_agg %>% 
    filter(month %in% c(9,10)) %>%
    rdd_data(nox_daily_sum, day_of_year, data=.,
             cutpoint=lubridate::yday('2005-10-01')) %>%
    rdd_reg_lm(slope = "separate", order = 2)

poly4_coef = reg_poly4$coefficients[2]


## ----data: season means, include=F----------------------------------------------------------------------------------------------------------------------------------------
df_ozone_season_mean = df %>%
    filter(year == 2005, nbp == 1) %>%
    mutate(ozone_season = if_else(day_of_year %in% lubridate::yday('2005-05-01'):lubridate::yday('2005-09-30'), 1, 0)) %>%
    group_by(state, ozone_season) %>%
    summarise(nox_dm_season = mean(nox, na.rm=T)) %>%
    Hmisc::upData(., labels = list(nox_dm_season = "Mean total daily NOx emissions from NBP states for season (tons)"))


## ----cross sectional season means regression, echo=F----------------------------------------------------------------------------------------------------------------------
reg_cross = df_ozone_season_mean %>% 
    lm(nox_dm_season ~ ozone_season, data=.)

cross_coef = reg_cross$coefficients[2]


## ----data: pre-post-means, include=F--------------------------------------------------------------------------------------------------------------------------------------
df_diff = df %>%
    group_by(day_of_year, year, nbp) %>%
    summarise(nox_dm_region = sum(nox, na.rm=T)/1000) %>%
    Hmisc::upData(., labels = list(nox_dm_region = "total daily NOx emissions from NBP states in NBP region (1000s of tons)")) %>%
    mutate(ozone_season = if_else(day_of_year %in% lubridate::yday('2005-05-01'):lubridate::yday('2005-09-30'), 1, 0),
           treat = ozone_season*(year==2005)*nbp)


## ----pre-post diffndiff regression, echo=F--------------------------------------------------------------------------------------------------------------------------------
reg_pre_post = df_diff %>%
    filter(nbp == 1) %>%
    lm(nox_dm_region ~ factor(year) + ozone_season + treat, data=.)

pre_post_coef = reg_pre_post$coefficients[4]
summary(reg_pre_post) 
summary(reg_pre_post, cluster="year") 


## ----east diffndiff regression, echo=F------------------------------------------------------------------------------------------------------------------------------------
reg_east_west = df_diff %>%
    filter(year == 2005) %>%
    lm(nox_dm_region ~ nbp + ozone_season + treat, data=.)
# nbp = 1 if east

east_west_coef = reg_east_west$coefficients[4]


## ----triple diffndiff regression, echo=F----------------------------------------------------------------------------------------------------------------------------------
reg_triple_diff = df_diff %>%
    lm(nox_dm_region ~ factor(year) + ozone_season + nbp 
       + factor(year)*ozone_season + factor(year)*nbp + ozone_season*nbp
       + treat, data=.)
# nbp = 1 if east

triple_diff_coef = reg_triple_diff$coefficients[5]


## ----Figure1, echo=F, message=F, fig.height=4, fig.width=7,  fig.cap="Total Daily nox Emissions in the NBP-Participating States"------------------------------------------
ggplot(df_daily_sums, aes(x=day_of_year, y=nox_daily_sum, group=year)) +
    geom_line(aes(linetype=factor(year)), color='darkblue') +
    ggtitle(TeX('')) +
    ylab('') + 
    scale_x_continuous('Day of year',
                       breaks=lubridate::yday(c('2002-01-01', '2002-05-01', '2002-10-01', '2002-12-31')),
                       labels=c('Jan 1', 'May 1', 'Oct 1', 'Dec 31'),
                       limits=c(1,365), expand=c(0.02,0.02)) +
    scale_y_continuous(expand=c(0.05,0.05),
                       breaks=c(2,4,6,8)) +
    plot_theme1 + theme(legend.position = c(0.9, 0.2)) +
    scale_linetype_manual(name = "Linetype",
                          values = c('2005'=1, '2002'=2))


## ----polynomial-regs, results='asis', echo=F, eval=T----------------------------------------------------------------------------------------------------------------------
stargazer(reg_poly1, reg_poly2, reg_poly3, reg_poly4,
          title="NBP Polynomial Regression Discontinuity Results for 2005", align=TRUE,
          header=F, type=table_type,
          dep.var.caption = "Total Daily Emissions (1000 tons)",
          dep.var.labels = "",
          column.labels=c("\\shortstack{NBP Start \\\\ (May)}",
                          "\\shortstack{NBP End \\\\ (Sepember)}",
                          "\\shortstack{NBP Start \\\\ (May)}",
                          "\\shortstack{NBP End \\\\ (Sepember)}"),
          add.lines = list(c("Separate Time Trend?", "\\centering\\text{No}", "\\text{No}", "\\text{Yes}", "\\text{Yes}")),
          covariate.labels = 'Ozone Season Indicator',
          keep='D',
          label = "tab:polynomial-regs",
          omit.stat = c("f", "rsq", "ser"), model.numbers=F
)


## ----RDD-poly-1-text, echo=F----------------------------------------------------------------------------------------------------------------------------------------------
text1 = "Regression Discontinuity plot with quadratic time trend for beginning 
of 2005 NBP season (constant shift only). The dependent variable is total average daily \\nox emissions (in
1000's of Tons) in the NBP participating states in April and May, 2005. The fitted
RDD lines use a quadratic time trend, with shared time trend parameters on either
side of the discontinuity -- only the regression intercept term differs on either side."
x_ = 1


## ----RDD-poly-1, echo=F, warning=F, message=F, fig.height = fig_h, fig.width = fig_w,  fig.cap = text1--------------------------------------------------------------------
data.frame(x = reg_poly1$model$x, y = reg_poly1$model$y, y_hat = reg_poly1$fitted.values) %>%
    mutate(treat = as.factor(ifelse(x >= 0, 'NBP Operating', 'NBP Not Operating'))) %>%
    mutate(y_hat_shift = ifelse(treat=='NBP Operating', y_hat - poly1_coef, NA)) %>%
    ggplot(aes(x=x, y=y, color=treat)) + geom_point() +
    geom_line(aes(x=x, y=y_hat, color=treat)) +
    geom_line(aes(x=x, y=y_hat_shift), linetype = "dashed") +
    xlab('Days after May 1, 2005') +
    ylab(TeX('Total NO$_{x}$ emissions (1000 tons)')) +
    plot_theme1 + theme(legend.position = c(0.2, 0.15)) +
    annotate("segment", x = 3, y = 4.75, xend = 3, yend = 3,
                  arrow = arrow(length = unit(0.5, "cm"))) + 
    annotate("text", x = 10+x_, y = 3.75, label = TeX(paste(round(poly1_coef,3)*1000, "tons NO$_{x}$")))


## ----RDD-poly-2-text, echo=F----------------------------------------------------------------------------------------------------------------------------------------------
text2 = "Regression Discontinuity plot with quadratic time trend for end of 2005 
NBP season (constant shift only). The dependent variable is total average daily \\nox emissions (in
1000's of Tons) in the NBP participating states in September and October, 2005. The fitted
RDD lines use a quadratic time trend, with shared time trend parameters on either
side of the discontinuity -- only the regression intercept term differs on either side."


## ----RDD-poly-2, echo=F, warning=F, message=F, fig.height = fig_h, fig.width = fig_w,  fig.cap = text2--------------------------------------------------------------------
data.frame(x = reg_poly2$model$x, y = reg_poly2$model$y, y_hat = reg_poly2$fitted.values) %>%
    mutate(treat = as.factor(ifelse(x >= 0, 'NBP Operating', 'NBP Not Operating'))) %>%
    mutate(y_hat_shift = ifelse(treat=='NBP Operating', y_hat - poly2_coef, NA)) %>%
    ggplot(aes(x=x, y=y, color=treat)) + geom_point() +
    geom_line(aes(x=x, y=y_hat, color=treat)) +
    geom_line(aes(x=x, y=y_hat_shift), linetype = "dashed") +
    xlab('Days after October 1, 2005') +
    ylab(TeX('Total NO$_{x}$ emissions (1000 tons)')) +
    plot_theme1 + theme(legend.position = c(0.2, 0.85)) +
    annotate("segment", x = 4, y = 3.7, xend = 4, yend =5.9,
                  arrow = arrow(length = unit(0.5, "cm"))) + 
    annotate("text", x = 10+x_, y = 4.5, label = TeX(paste(round(poly2_coef,3)*1000, "tons NO$_{x}$")))


## ----RDD-poly-3-text, echo=F----------------------------------------------------------------------------------------------------------------------------------------------
text3 = "Regression Discontinuity plot with quadratic time trend for beginning of 
2005 NBP season (constant and trend shifts). The dependent variable is total average daily \\nox emissions (in
1000's of Tons) in the NBP participating states in September and October, 2005. The fitted
RDD lines use a quadratic time trend, with separate time trend parameters on either
side of the discontinuity (a spline RDD) -- both the intercept and time trend
parameters differs on either side of the regulation threshold (October 1st)."


## ----RDD-poly-3, echo=F, warning=F, message=F, fig.height = fig_h, fig.width = fig_w,  fig.cap = text3--------------------------------------------------------------------
data.frame(x = reg_poly3$model$x, y = reg_poly3$model$y, y_hat = reg_poly3$fitted.values) %>%
    mutate(treat = as.factor(ifelse(x >= 0, 'NBP Operating', 'NBP Not Operating'))) %>%
    mutate(y_hat_shift = ifelse(treat=='NBP Operating', y_hat - poly3_coef, NA)) %>%
    ggplot(aes(x=x, y=y, color=treat)) + geom_point() +
    geom_line(aes(x=x, y=y_hat, color=treat)) +
    geom_line(aes(x=x, y=y_hat_shift), linetype = "dashed") +
    xlab('Days after May 1, 2005') +
    ylab(TeX('Total NO$_{x}$ emissions (1000 tons)')) +
    plot_theme1 + theme(legend.position = c(0.2, 0.15)) +
    annotate("segment", x = 6, y = 4.5, xend = 6, yend = 2.9,
                  arrow = arrow(length = unit(0.5, "cm"))) + 
    annotate("text", x = 12+x_, y = 3.5, label = TeX(paste(round(poly3_coef,3)*1000, "tons NO$_{x}$")))


## ----RDD-poly-4-text, echo=F----------------------------------------------------------------------------------------------------------------------------------------------
text4 = "Regression Discontinuity plot with quadratic time trend for end of 2005
NBP season (constant and trend shifts). The dependent variable is total average daily \\nox emissions (in 
1000's of Tons) in the NBP participating states in September and October, 2005. 
The fitted RDD lines use a quadratic time trend, with separate time trend parameters on either
side of the discontinuity (a spline RDD) -- both the intercept and time trend
parameters differs on either side of the regulation threshold (October 1st)."


## ----RDD-poly-4, echo=F, warning=F, message=F, fig.height = fig_h, fig.width = fig_w,  fig.cap = text1--------------------------------------------------------------------
data.frame(x = reg_poly4$model$x, y = reg_poly4$model$y, y_hat = reg_poly4$fitted.values) %>%
    mutate(treat = as.factor(ifelse(x >= 0, 'NBP Operating', 'NBP Not Operating'))) %>%
    mutate(y_hat_shift = ifelse(treat=='NBP Operating', y_hat - poly4_coef, NA)) %>%
    ggplot(aes(x=x, y=y, color=treat)) + geom_point() +
    geom_line(aes(x=x, y=y_hat, color=treat)) +
    geom_line(aes(x=x, y=y_hat_shift), linetype = "dashed") +
    xlab('Days after October 1, 2005') +
    ylab(TeX('Total NO$_{x}$ emissions (1000 tons)')) +
    plot_theme1 + theme(legend.position = c(0.2, 0.85)) +
    annotate("segment", x = 4, y = 3.4, xend = 4, yend = 6,
                  arrow = arrow(length = unit(0.5, "cm"))) + 
    annotate("text", x = 10+x_, y = 4.5, label = TeX(paste(round(poly4_coef,3)*1000, "tons NO$_{x}$")))


## ----cross-sectional-reg, results='asis', echo=F, eval=T------------------------------------------------------------------------------------------------------------------
stargazer(reg_cross,
          title="NBP Cross-sectional, Seasonal Mean Results for 2005", align=TRUE,
          header=F, type=table_type,
          dep.var.caption = "Season-Mean Daily Emissions per state (tons)",
          dep.var.labels = "",
          column.labels=c("\\shortstack{Season level \\\\ Cross Section}"),
          covariate.labels = 'Ozone Season Indicator',
          keep='ozone_season',
          label = "tab:cross-sectional-reg",
          omit.stat = c("f", "rsq", "ser"), model.numbers=F
)


## ----diff-regs-short, results='asis', echo=F, eval=T----------------------------------------------------------------------------------------------------------------------
stargazer(reg_pre_post, reg_east_west, reg_triple_diff,
          title="NBP Differences Regression Results", align=TRUE,
          header=F, type=table_type,
          dep.var.caption = "Total Region Daily Emissions (1000 tons)",
          dep.var.labels = "",
          column.labels=c("\\shortstack{Pre-Post \\\\ Diff-in-Diff}",
                          "\\shortstack{East-West \\\\ Diff-in-Diff}",
                          "\\shortstack{Triple \\\\ Differences}"),
          covariate.labels = c('NBP Participation'),
          keep='treat',
          add.lines = list(c("East only", "\\centering\\text{Yes}", "\\text{No}", "\\text{No}"),
                           c("2005 only", "\\centering\\text{No}", "\\text{Yes}", "\\text{No}")),
          label = "tab:diff-regs-short",
          omit.stat = c("f", "rsq", "ser"), model.numbers=F,
          notes = c("Region-total daily \\nox  emissions are the sum of total average",
          "daily \\nox  emissions of all states in each region.")
)


## ----diff-regs-long, results='asis', echo=F, eval=T-----------------------------------------------------------------------------------------------------------------------
stargazer(reg_pre_post, reg_east_west, reg_triple_diff,
          title="NBP Differences Regression Results", align=TRUE,
          header=F, type=table_type,
          dep.var.caption = "Total Region Daily Emissions (1000 tons)",
          dep.var.labels = "",
          column.labels=c("\\shortstack{Pre-Post \\\\ Diff-in-Diff}",
                          "\\shortstack{East-West \\\\ Diff-in-Diff}",
                          "\\shortstack{Triple \\\\ Differences}"),
          order = c('treat'),
          covariate.labels = c('NBP Participation',
                               'year = 2005',
                               'East Region',
                               'Ozone Season (May-Sept)',
                               'year=2005 \\& Ozone Season',
                               'year=2005 \\& East Region',
                               'Ozone Season \\& East Region',
                               'Intercept'),
          add.lines = list(c("East only", "\\centering\\text{Yes}", "\\text{No}", "\\text{No}"),
                           c("2005 only", "\\centering\\text{No}", "\\text{Yes}", "\\text{No}")),
          label = "tab:diff-regs-long",
          omit.stat = c("f", "rsq", "ser"), model.numbers=F,
          notes = c("Region-total daily \\nox  emissions are the sum of total average",
          "daily \\nox  emissions of all states in each region.")
)


## ----eval=F---------------------------------------------------------------------------------------------------------------------------------------------------------------
## 

