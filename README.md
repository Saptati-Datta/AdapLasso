
<font size = "10">_**Adaptive Lasso Using LARS Algorithm**_

<font size = "6"> **Intended Functionality**\
<font size = "2">This package consists of the necessary functions to fit an Adaptive Lasso to a data. There exists certain scenarios where ordinary Lasso turns out to be inconsistent. The main reason for such a discrepancy is that Lasso does not always enjoy oracle properties. In such a case, it is convenient to take resort to Adaptive Lasso technique which satisfies the oracle properties, that is, it has the ability to perform the same asymptotically, as if we knew the true specification of the model beforehand. Such an algorithm was proposed by Zou(2006). This package consists of 9 functions: ```scale_X,standardizeXY,soft,lasso,fitadapLASSOstandardized,fitadapLASSOstandardized_seq,fitadapLASSO,cvLASSO``` and ```cv.gamma```.The functionality of each of these functions have been documented and they together help fit an adaptive lasso model using LARS algorithm.\

<font size = "6"> **Installation Instructions**\
<font size = "2"> The package can be installed using the following two lines of code:
```{r}
devtools::install_github("Saptati-Datta/AdapLasso",build_vignettes=TRUE)
library(AdapLasso)

```
<font size = "6"> **Remaining Part of the Project**
<font size = "2"> Part of the project that is still to be completed :

* The vignette is partially complete as of yet.References to be added.

* If time permits,I will also try to make tests.

* Changes in parts of documentation and adding more examples
