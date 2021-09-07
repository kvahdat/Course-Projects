####################### Midterm project ###########
###################################################
##### Kimia Vahdat, Hossein Tohidi,################
#####Sajjad Taghiyeh, Rezvan Mahdavi Hezaveh#######
############ Mojtaba Sardar Mehni #################
###################################################


### Loading the libraries
require(MASS)
require(faraway)
require(corrplot)
require(ISLR)
library(DAAG)
library(leaps)
library(glmnet)
require(dplyr)
require(leaps)
require(pls)
require(randomForest)
require(caret)
require(gbm)

### Reading the data
dat<-read.csv('C:\\Users\\msmsa\\Google Drive\\ST 516 - Experimental statistics for engineers2\\ST 516 Midterm Project\\bikes.csv',colClasses = c('numeric',rep('factor',5),rep('numeric',5)))
plot(dat$registered,col='blue',pch=1)
points(x=dat$casual,col='red',pch=2)
legend("topleft",legend=c("Registered","Casual"),pch=c(1,2),col=c("blue","red"))


### Checking for missing values in data
sum(is.na(dat)) 
dat<-dat[,-c(1,2)]

### Create center data for numeric data  
temp_c=dat$temp-mean(dat$temp)
hum_c=dat$hum-mean(dat$hum)
windspeed_c=dat$windspeed-mean(dat$windspeed)

### Create the interaction and square data (Complete sencond order)
dat$temp_s=temp_c^2
dat$hum_s=hum_c^2
dat$windspeed_s=windspeed_c^2
dat$temp.hum = temp_c*hum_c
dat$temp.wind = temp_c*windspeed_c
dat$hum.wind = hum_c*windspeed_c

#### Create two datasets for causal and registered data
dat1<-dat[,-c(9)] ### casual
dat2<-dat[,-c(8)] ### registered

### Checking the corrolation in input data
pairs(dat1)
pairs(dat2)

### Fit linear model to data and checking the diagnostic plots
fit1<-lm(casual~.,data=dat1)
fit2<-lm(registered~.,data=dat2)
par(mfrow=c(2,2))
plot(fit1)
summary(fit1)
vif(fit1)
dat1_cor= cor(dat1[,-c(1:4)])
corrplot(dat1_cor)
dat2_cor= cor(dat2[,-c(1:4)])
corrplot(dat2_cor)
par(mfrow=c(2,2))
plot(fit2)
vif(fit2)
summary(fit2)

### Removing outliers based on the cook's distance figure from linear model
dat1 <- dat1[-c(442,463,645),]
dat2 <- dat2[-c(668,669,693),]

### Fit Linear model to data again after the removing the outlier data
fit1<-lm(casual~.,data=dat1)
fit2<-lm(registered~.,data=dat2)
par(mfrow=c(2,2))
plot(fit1)
summary(fit1)
vif(fit1)
dat1_cor= cor(dat1[,-c(1:4)])
corrplot(dat1_cor)
dat2_cor= cor(dat2[,-c(1:4)])
corrplot(dat2_cor)
par(mfrow=c(2,2))
plot(fit2)
vif(fit2)
summary(fit2)

#########################################################################
#######################      BoxCOX Transformation     ##################
#########################################################################

### Calculating the best lambda for the casual data set  
par(mfrow=c(1,1))
box1=boxcox(fit1)
lambda1=box1$x[which.max(box1$y)]
lambda1

### Transform the casual data set using lambda = 0.2222222 
dat1$casual.box=(dat1$casual^lambda1-1)/lambda1
fit1.box<-lm(casual.box~.-casual,data=dat1)
par(mfrow=c(2,2))
plot(fit1.box)
summary(fit1.box)

box2=boxcox(fit2)
lambda2=box2$x[which.max(box2$y)]
lambda2

### Transform the casual data set using lambda = 0.6666667 
dat2$registered.box=(dat2$registered^lambda2-1)/lambda2
fit2.box<-lm(registered.box~.-registered,data=dat2)
par(mfrow=c(2,2))
plot(fit2.box)
summary(fit2.box)


#### Prediction accuracy with 5 folds cross validation####
#### calculating loocv for each model###
mse1=data.frame(matrix(NA,nrow=6,ncol=2))  # create dummy data frame to store MSE values
colnames(mse1)=c("model","MSE")
mse1$model=c("Transformation","Ridge","LASSO","PCA","Random Forest","GBM")

mse2=data.frame(matrix(NA,nrow=6,ncol=2))  # create dummy data frame to store MSE values
colnames(mse2)=c("model","MSE")
mse2$model=c("Transformation","Ridge","LASSO","PCA","Random Forest","GBM")


y1=dat1$casual.box
x1=dat1[,-c(15,8)]
df1=data.frame(y1,x1)

y2=dat2$registered.box
x2=dat2[,-c(15,8)]
df2=data.frame(y2,x2)

seed=100  # set seed
folds=5
# Model Transformation test MSE using CV
par(mfrow=c(1,1))
lmod1=lm(y1~.,data=df1)
cv.mse1=cv.lm(df1, lmod1, m=folds, seed=seed) # perform cross-validation

trans_inv=function(pred,lambda){
  pred = pred[pred>=0]
  return((pred*lambda+1)^(1/lambda))
}

mse1[1,2]=mean((cv.mse1$y1-cv.mse1$cvpred)^2)

# Model i test MSE using CV
par(mfrow=c(1,1))
lmod2=lm(y2~.,data=df2)
cv.mse2=cv.lm(df2, lmod2, m=folds, seed=seed) # perform cross-validation
mse2[1,2]=mean((cv.mse2$y2-cv.mse2$cvpred)^2)

###################################################################
################     Ridge     ####################################
###################################################################

### Ridge _ Casual data set

x1=model.matrix(y1~.,df1)[,-1]
y1=df1$y1

### create grid for lambda, fit model using all lambdas
grid=10^seq(10,-10,length=5000) # lambda ranges from 10^10 to 10^(-10) 
ridge.mod1=glmnet(x1,y1,alpha=0,lambda=grid)  

### plot coefficent values as we change lambda
plot(ridge.mod1,xlab="L2 Norm")  # x-axis is in terms of sum(beta^2)
abline(h=0,lty=3)

### optimize lambda using cross-validation
set.seed(100)
cv.ridge1=cv.glmnet(x1,y1,alpha=0,lambda=grid,nfolds = 5)
plot(cv.ridge1)
bestlam.r1=cv.ridge1$lambda.min
mse.r1=min(cv.ridge1$cvm)
bestlam.r1
mse.r1
mse1[2,2] = mse.r1

###########################
### Ridge _ Registered data set
x2=model.matrix(y2~.,df2)[,-1]
y2=df2$y2

### create grid for lambda, fit model using all lambdas
###grid=10^seq(10,-10,length=5000) # lambda ranges from 10^10 to 10^(-10)  
ridge.mod2=glmnet(x2,y2,alpha=0,lambda=grid)  

### plot coefficent values as we change lambda
plot(ridge.mod2,xlab="L2 Norm")  # x-axis is in terms of sum(beta^2)
abline(h=0,lty=3)

### optimize lambda using cross-validation
set.seed(100)
cv.ridge2=cv.glmnet(x2,y2,alpha=0,lambda=grid,nfolds = 5)
plot(cv.ridge2)
bestlam.r2=cv.ridge2$lambda.min
mse.r2=min(cv.ridge2$cvm)
bestlam.r2
mse.r2

mse2[2,2] = mse.r2

###################################################################
################     LASSO     ####################################
###################################################################

### LASSO _ Casual data set
### create grid for lambda, fit model using all lambdas
grid=10^seq(10,-10,length=5000) # lambda ranges from 10^10 to 10^(-10) 
lasso.mod1=glmnet(x1,y1,alpha=1,lambda=grid)  

### check coefficent values for each value of lambda
plot(lasso.mod1)  # x-axis is in terms of sum(beta^2)
abline(h=0,lty=3)

### optimize lambda using cross-validation
set.seed(100)
cv.lasso1=cv.glmnet(x1,y1,alpha=1,lambda=grid,nfolds = 5)
plot(cv.lasso1)
bestlam.l1=cv.lasso1$lambda.min
mse.l1=min(cv.lasso1$cvm)
bestlam.l1
mse.l1
mse1[3,2] = mse.l1

coef(cv.lasso1)

#######################
### LASSO _ Registered data set
lasso.mod2=glmnet(x2,y2,alpha=1,lambda=grid)  

# check coefficent values for each value of lambda
plot(lasso.mod2)  # x-axis is in terms of sum(beta^2)
abline(h=0,lty=3)

# optimize lambda using cross-validation
set.seed(100)
cv.lasso2=cv.glmnet(x2,y2,alpha=1,lambda=grid,nfolds = 5)
plot(cv.lasso2)
bestlam.l2=cv.lasso2$lambda.min
mse.l2=min(cv.lasso2$cvm)
bestlam.l2
mse.l2
mse2[3,2] = mse.l2
coef(cv.lasso2) # temp.wind has been set to 0


###################################################################
#########     Principal Components Regression     #################
###################################################################

### PCA _ Casual data set
pcr.mod1=pcr(y1~.,data=df1,scale=T)
pcr.mod1.cv=crossval(pcr.mod1, segments = 5)
summary(pcr.mod1.cv)
validationplot(pcr.mod1.cv,val.type="MSEP")

# plotfitted values for OLS and PCR, compare with actual
lmod1=lm(y1~.,data=df1)
fit.pcr1=predict(pcr.mod1.cv,data=df1,ncomp=13)
plot(lmod1$fitted.values,df1$y1,pch=19,col="blue")
points(fit.pcr1,df1$y1,col="red",lwd=2)
abline(a=0,b=1)
mse1[4,2] = mean((fit.pcr1 - df1$y1)^2)

### Calcualte Rsquare
rss <- sum((fit.pcr1 - df1$y1) ^ 2)
tss <- sum((df1$y1 - mean(df1$y1)) ^ 2)
rsq <- 1 - rss/tss
rsq


#############
### PCA _ Registered data set
pcr.mod2=pcr(y2~.,data=df2,scale=T)
pcr.mod2.cv=crossval(pcr.mod2, segments = 5)
summary(pcr.mod2.cv)
validationplot(pcr.mod2.cv,val.type="MSEP")

# plotfitted values for OLS and PCR, compare with actual
lmod2=lm(y2~.,data=df2)
fit.pcr2=predict(pcr.mod2.cv,data=df2,ncomp=13)
plot(lmod2$fitted.values,df2$y2,pch=19,col="blue")
points(fit.pcr2,df2$y2,col="red",lwd=2)
abline(a=0,b=1)

mse2[4,2] = mean((fit.pcr2 - df2$y2)^2)
### Calcualte Rsquare
rss <- sum((fit.pcr2 - df2$y2) ^ 2)
tss <- sum((df2$y2 - mean(df2$y2)) ^ 2)
rsq <- 1 - rss/tss
rsq

###################################################################
############           Random Forest             ##################
###################################################################

### RF _ Casual data set
# tune model parameter mtry using caret
control=trainControl(method="cv", number=5, search="grid")

tunegrid=expand.grid(mtry=c(1:16))
rf_gridsearch1=train(y1~.,data=df1, method="rf", metric="RMSE", 
                    tuneGrid=tunegrid, trControl=control)

print(rf_gridsearch1)
plot(rf_gridsearch1)


rf.mod1=randomForest(y1~.,data=df1,mtry=5, ntree=1000, 
                    importance=T)
rf.mod1
plot(rf.mod1)

varImpPlot(rf.mod1,type=1,pch=19)

# plotfitted values for OLS and RT, compare with actual
#lmod1=lm(vel~.,data=fiber)
plot(lmod1$fitted.values,df1$y1,pch=19,col="blue")
points(rf.mod1$predicted,df1$y1,col="red",lwd=2)
abline(a=0,b=1)

mse1[5,2]= mean((rf.mod1$predicted-df1$y1)^2)

### Calcualte Rsquare
rss <- sum((rf.mod1$predicted - df1$y1) ^ 2)
tss <- sum((df1$y1 - mean(df1$y1)) ^ 2)
rsq <- 1 - rss/tss
rsq


#############
### RF _ Registered data set
rf_gridsearch2=train(y2~.,data=df2, method="rf", metric="RMSE", 
                     tuneGrid=tunegrid, trControl=control)

print(rf_gridsearch2)
plot(rf_gridsearch2)


rf.mod2=randomForest(y2~.,data=df2,mtry=9, ntree=1000, 
                     importance=T)
rf.mod2
plot(rf.mod2)

varImpPlot(rf.mod2,type=1,pch=19)

# plotfitted values for OLS and RT, compare with actual
#lmod1=lm(vel~.,data=fiber)
plot(lmod2$fitted.values,df2$y2,pch=19,col="blue")
points(rf.mod2$predicted,df2$y2,col="red",lwd=2)
abline(a=0,b=1)

mse2[5,2]= mean((rf.mod2$predicted-df2$y2)^2)

### Calcualte Rsquare
rss <- sum((rf.mod2$predicted - df2$y2) ^ 2)
tss <- sum((df2$y2 - mean(df2$y2)) ^ 2)
rsq <- 1 - rss/tss
rsq


###################################################################
############                 GBM                 ##################
###################################################################

### GBM _ Casual data set
### tune model parameter mtry using caret
control=trainControl(method="cv", number=5, search="grid")

tunegrid=expand.grid(n.trees=c(100,500,1000,2000,5000,7500),
                     interaction.depth=c(1,3,5),
                     shrinkage=c(0.001,0.005,0.01),
                     n.minobsinnode=c(1,3,5))
gb_gridsearch1=train(y1~.,data=df1, 
                    method="gbm", metric="RMSE",
                    tuneGrid=tunegrid, trControl=control)
print(gb_gridsearch1)
par(mfrow=c(2,2))
plot(gb_gridsearch1)

#choose n.tree=1000, int.depth=3, shrink=0.01, minobs=5

gb.mod1=gbm(y1~.,data=df1,
           distribution = "gaussian",n.trees = 1000,
           shrinkage = 0.01, interaction.depth = 3, 
           n.minobsinnode=5, cv.folds = 5)
par(mfrow=c(1,1))
summary(gb.mod1,cBars=10)
mse1[6,2]=mean((gb.mod1$fit - df1$y1)^2)

### Calcualte Rsquare
rss <- sum((gb.mod1$fit - df1$y1) ^ 2)
tss <- sum((df1$y1 - mean(df1$y1)) ^ 2)
rsq <- 1 - rss/tss
rsq

###########################################
### GBM _ Registered data set
# tune model parameter mtry using caret
control=trainControl(method="cv", number=5, search="grid")

tunegrid=expand.grid(n.trees=c(100,500,1000,2000,5000,7500),
                     interaction.depth=c(1,3,5),
                     shrinkage=c(0.001,0.005,0.01),
                     n.minobsinnode=c(1,3,5))
gb_gridsearch2=train(y2~.,data=df2, 
                     method="gbm", metric="RMSE",
                     tuneGrid=tunegrid, trControl=control)
print(gb_gridsearch2)
par(mfrow=c(2,2))
plot(gb_gridsearch2)

#choose n.tree=2000, int.depth=5, shrink=0.005, minobs=3

gb.mod2=gbm(y2~.,data=df2,
            distribution = "gaussian",n.trees = 2000,
            shrinkage = 0.005, interaction.depth = 5, 
            n.minobsinnode=3, cv.folds = 5)
par(mfrow=c(1,1))
summary(gb.mod2,cBars=10)
mse2[6,2]=mean((gb.mod2$fit - df2$y2)^2)
### Calcualte Rsquare
rss <- sum((gb.mod2$fit - df2$y2) ^ 2)
tss <- sum((df2$y2 - mean(df2$y2)) ^ 2)
rsq <- 1 - rss/tss
rsq

