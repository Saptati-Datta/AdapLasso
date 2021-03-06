
<font size = "20">**Adaptive Lasso Using LARS Algorithm**

<font size = "6"> **Intended Functionality**\
<font size = "2">This package consists of the necessary functions to fit an Adaptive Lasso to a data. There exists certain scenarios where ordinary Lasso turns out to be inconsistent. The main reason for such a discrepancy is that Lasso does not always enjoy oracle properties. In such a case, it is convenient to take resort to Adaptive Lasso technique which satisfies the oracle properties, that is, it has the ability to perform the same asymptotically, as if we knew the true specification of the model beforehand. Such an algorithm was proposed by Zou(2006). This package consists of 9 functions: ```scale_X,standardize,soft,adaplasso,adaplassostd_lambda,adaplassostdseq_lambda,fitadapLASSO,cv.lambda``` and ```cv.gamma```.The functionality of each of these functions have been documented and they together help fit an adaptive lasso model using LARS algorithm.

<font size = "6"> **Installation Instructions**\
<font size = "2"> The package can be installed using the following two lines of code:
```{r include=TRUE}
devtools::install_github("Saptati-Datta/AdapLasso", build_vignettes = TRUE)
library(AdapLasso)
```



<font size = "6"> **An Example**\
<font size = "2">Here we apply our functions to fit an adaptive lasso to the mtcars data set.
```{r include=TRUE}
data <- mtcars
Y <- data$mpg
X <- cbind(data$disp, data$drat, data$wt)
gamma <- cv.gamma(X, Y)$gamma_min
lambda <- cv.lambda(X, Y)$tuning_seq
fit <- fitadaplasso(X, Y, tuning_seq = lambda, gamma = gamma)
plot(fit$tuning_seq, colSums(fit$beta_lamb != 0), ylab = "Non-zero beta", xlab = "tuning_seq",type = "l")
```

![Plot of sequences of lambdas vs non-zero betas](https://github.com/Saptati-Datta/AdapLasso/blob/main/README_files/figure-gfm/unnamed-chunk-2-1.png)

<font size = "6"> **Details**\
For further details, refer to the vignette and documentations for each function.
