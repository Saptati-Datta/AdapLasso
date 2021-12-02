# ADAPTIVE LASSO

# Transforming X by dividing with elements of the weight matrix
# Computing scaled inputs using LARS algorithm
#'  scale_X Scales a matrix of inputs according to  LARS algorithm
#'
#' @param X n x p  design matrix of inputs
#' @param Y n x 1 vector of outputs
#' @param gamma a scalar(>0) input used in the weight(user input)
#'
#' @return X_w(the scaled design matrix),weights
#' @export scale_X
#'
#' @examples
#' EXAMPLE
#' X <- matrix(rnorm(500), 50, 10)
#' Y <- rnorm(50)
#' gamma <- 2
#' #Scaling using scale_X
#' sc <- scale_X(X , Y , gamma)
#' #Deriving weighted design matrix
#' X_w <- sc$X_w
#' #Deriving weights
#' weights <- sc$weights
scale_X <- function(X, Y, gamma) {
  glmnet::cv.glmnet(X, Y, alpha = 0)
  Matrix::rankMatrix(X)
  # Computing the best lambda for the Ridge estimator
 cv_mod <- glmnet::cv.glmnet(X, Y, alpha = 0)
  # Optimal value of lambda for Ridge
  lambda_min <- cv_mod$lambda.min
  p <- ncol(X)
  n <- nrow(X)
  if (Matrix::rankMatrix(X) < p) {
    # Calculating ridge estimator
    beta <- solve(crossprod(X) + lambda_min * diag(p)) %*% crossprod(X, Y)
  } else {
    # Calculating OLS
    beta <- solve(t(X) %*% X) %*% t(X) %*% Y
  }
  weights <- as.vector(abs(beta)^gamma)
  # Scales X
  X_w <- t(t(X) / weights)
  # returns scaled X
  return(list(X_w = X_w, weights = weights))
}


# STANDARDIZING INPUTS
#' Standardizes the input design matrix X and output vector Y to mean 0 and scales X
#'@inheritParams scale_X
#'
#' @return Xtilde=scaled X, Ytilde= scaled Y, Ymeans = mean of Y , Xmeans =  Column means after centering the weighted X matrix from scale_X , weights = weights obtained by centering X_w which is obtained from scale X
#' @export standardizeXY
#'
#' @examples
#' X <- matrix(rnorm(500), 50, 10)
#' Y <- rnorm(50)
#' gamma <- 2
#' #Standardizing X and Y
#' std <- standardizeXY(X , Y , gamma)
#' #Deriving weighted and centered design matrix
#' Xtilde <- std$Xtilde
#' #Column means of centered X_w
#' Xmeans <- std$Xmeans
#' #Deriving centered Y
#' Ytilde <- std$Ytilde
#' #Mean of Ytilde
#' Ymean <- std$Ymean
#' # Weights
#' weights <- std$weights
standardizeXY <- function(X, Y, gamma) {
  n <- length(Y)
  p <- ncol(X)
  # Scaling X
  Xtilde <- scale_X(X, Y, gamma)$X_w
  Xmeans <- colMeans(Xtilde)
  Xcentered <- scale(Xtilde, scale = FALSE)
  weights <- sqrt(diag(crossprod(Xcentered) / n))
  Xtilde <- t(t(Xcentered) / weights)
  # Center Y
  Ymean <- mean(Y)
  Ytilde <- Y - Ymean
  # Return:
  # Xtilde - centered and appropriately scaled X
  # Ytilde - centered Y
  # Ymean - the mean of original Y
  # Xmeans - means of columns of X (vector)
  # weights - defined as sqrt(X_j^{\top}X_j/n) after centering of X but before scaling
  return(list(Xtilde = Xtilde, Ytilde = Ytilde, Ymean = Ymean, Xmeans = Xmeans, weights = weights))
}

# Soft-thresholding of a scalar a at level lambda
# a- scalar input
# lambda-tuning parameter
#' Soft-thresholding of a scalar a at level lambda
#'
#' @param a scalar to be soft-thresholded
#' @param lambda level of soft thresholding
#'
#' @return soft-thresholded value
#' @export soft
#'
#' @examples
#' a = 2
#' lambda = 1
#' soft(a , lambda)
soft <- function(a, lambda) {
  if (a > lambda) {
    return(a - lambda)
  } else if (a < (-lambda)) {
    return(a + lambda)
  } else {
    return(0)
  }
}
# Xtilde - centered and scaled X, n x p
# Ytilde - centered Y, n x 1
# lamdba - tuning parameter
# beta - value of beta at which to evaluate the function
# Computing the objective function
#'  Function for soft-thresholding
#'
#' @param Xtilde n x p design matrix X scaled according to LARS algorithm and centered to mean 0
#' @param Ytilde n x 1 centered output vector
#' @param beta   p x 1 vector of parameters
#' @param lambda tuning parameter(scalar)
#'
#' @return Objective function for Lasso
#' @export lasso
#'
#' @examples
#' X <- matrix(rnorm(500), 50, 10)
#' Y <- rnorm(50)
#' gamma <- 2
#' #Standardizing X and Y
#' std <- standardizeXY(X , Y , gamma)
#' #Deriving weighted and centered design matrix
#' Xtilde <- std$Xtilde
#' #Deriving centered Y
#' Ytilde <- std$Ytilde
#' #Defining beta
#' beta <- solve(crossprod(X)) %*% t(X) %*% Y
#' #Lambda value
#' lambda <- 2
#' #Objective function
#' obj <- lasso(Xtilde, Ytilde, beta, lambda)
lasso <- function(Xtilde, Ytilde, beta, lambda) {
  n <- length(Ytilde)
  # objective function
  fobj <- sum((Ytilde - (Xtilde %*% beta))^2) / (2 * n) + sum(lambda * abs(beta))
  # Return
  return(fobj)
}

# Fit LASSO on standardized data for a given lambda
# Xtilde - centered and scaled X, n x p
# Ytilde - centered Y, n x 1 (vector)
# lamdba - tuning parameter
# beta_start - p vector, an optional starting point for coordinate-descent algorithm
# eps - precision level for convergence assessment, default 0.001
#' Fits adaptive lasso based on standardized data
#'@inheritParams lasso
#' @param beta_start p x 1, optional starting point for coordinate descent algorithm
#' @param eps  precision level for convergence assessment, default 0.001
#'
#' @return beta = vector of parameters , fmin = optimal value of the objective function
#' @export fitadapLASSOstandardized
#'
#' @examples
#' X <- matrix(rnorm(500), 50, 10)
#' Y <- rnorm(50)
#' gamma <- 2
#' #Standardizing X and Y
#' std <- standardizeXY(X , Y , gamma)
#' #Deriving weighted and centered design matrix
#' Xtilde <- std$Xtilde
#' #Deriving centered Y
#' Ytilde <- std$Ytilde
#' # tuning parameter
#' lambda  <- 0.1
#' fit <- fitadapLASSOstandardized(Xtilde, Ytilde, lambda)
fitadapLASSOstandardized <- function(Xtilde, Ytilde, lambda, beta_start = NULL, eps = 0.001) {
  n <- length(Ytilde)
  p <- ncol(Xtilde)
  # Check that n is the same between Xtilde and Ytilde
  if (nrow(Xtilde) != length(Ytilde)) {
    stop("Error: nrow(X) and length(Y) are not equal")
  }
  # Check that lambda is non-negative
  if (lambda < 0) {
    stop("Error: Lambda is negative")
  }
  #  Check for starting point beta_start. If none supplied, initialize with a vector of zeros. If supplied, check for compatibility with Xtilde in terms of p
  if (is.null(beta_start)) {
    beta_start <- rep(0, p)
  } else if (length(beta_start) != p) {
    stop("Error: dimension of p and ncol(X) do not match", ncol(Xtilde))
  }
  # Coordinate-descent implementation. Stop when the difference between objective functions is less than eps for the first time.
  # For example, if you have 3 iterations with objectives 3, 1, 0.99999, your should return fmin = 0.99999, and not have another iteration
  # Get sample size
  n <- length(Ytilde)
  beta <- beta_start
  curr_obj <- lasso(Xtilde, Ytilde, beta, lambda)
  last_obj <- Inf
  r <- Ytilde - Xtilde %*% beta_start
  while ((last_obj - curr_obj) > eps) {
    for (j in 1:p)
    {
      beta_old <- beta[j]
      beta[j] <- soft(beta[j] + (crossprod(Xtilde[, j], r)) / n, lambda)
      r <- r + Xtilde[, j] * (beta_old - beta[j])
    }

    last_obj <- curr_obj
    curr_obj <- lasso(Xtilde, Ytilde, beta, lambda)
  }
  fmin <- curr_obj # Minimum value of the objective function
  # Return
  # beta - the solution (a vector)
  # fmin - optimal function value (value of objective at beta, scalar)
  return(list(beta = beta, fmin = fmin))
}

# Fit LASSO on standardized data for a sequence of lambda values. Sequential version of a previous function.
# Xtilde - centered and scaled X, n x p
# Ytilde - centered Y, n x 1
# lamdba_seq - sequence of tuning parameters, optional
# n_lambda - length of desired tuning parameter sequence, is only used when the tuning sequence is not supplied by the user
# eps - precision level for convergence assessment, default 0.001
#' Fits Adaptive Lasso on a sequence of lambda values based on standardized data
#'@inheritParams fitadapLASSOstandardized
#' @param lambda_seq (optional)sequence of tuning parameters
#' @param n_lambda length of desired tuning parameter sequence, is only used when the tuning sequence is not supplied by the user
#'
#' @return lambda_seq=the actual sequence of tuning parameters used,beta_mat=p x length(lambda_seq) matrix of corresponding solutions at each lambda value,fmin_vec = fmin_vec - length(lambda_seq) vector of corresponding objective function values at solution
#' @export fitadapLASSOstandardized_seq
#'
#' @examples
#' X <- matrix(rnorm(500), 50, 10)
#' Y <- rnorm(50)
#' gamma <- 2
#' #Standardizing X and Y
#' std <- standardizeXY(X , Y , gamma)
#' #Deriving weighted and centered design matrix
#' Xtilde <- std$Xtilde
#' #Deriving centered Y
#' Ytilde <- std$Ytilde
#' fit <- fitadapLASSOstandardized_seq(Xtilde, Ytilde)
fitadapLASSOstandardized_seq <- function(Xtilde, Ytilde, lambda_seq = NULL, n_lambda = 60, eps = 0.001) {
  n <- length(Ytilde)
  # Check that n is the same between Xtilde and Ytilde
  if (nrow(Xtilde) != length(Ytilde)) {
    stop("Dimensions of X and Y do not match")
  }

  # Check for the user-supplied lambda-seq (see below)
  if (is.null(lambda_seq) == FALSE) {
    # If lambda_seq is supplied, only keep values that are >= 0, and make sure the values are sorted from largest to smallest. If none of the supplied values satisfy the requirement, print the warning message and proceed as if the values were not supplied.
    lambda_seq <- sort(lambda_seq[lambda_seq >= 0], decreasing = TRUE)
    if (length(lambda_seq) == 0) {
      print("Warning: Lambda sequence not supplied")
      lambda_seq <- NULL
    } else {
      n_lambda <- length(lambda_seq)
    }
  }
  # If lambda_seq is not supplied, calculate lambda_max (the minimal value of lambda that gives zero solution), and create a sequence of length n_lambda as
  if (is.null(lambda_seq)) {
    lambda_max <- max(abs(crossprod(Xtilde, Ytilde)) / n)
    lambda_seq <- exp(seq(log(lambda_max), log(0.01), length = n_lambda))
  }

  p <- ncol(Xtilde)
  # Apply fitadapLASSOstandardized going from largest to smallest lambda (make sure supplied eps is carried over). Use warm starts strategy discussed in class for setting the starting values.
  beta <- rep(0, p)
  beta_mat <- matrix(0, p, n_lambda)
  fmin_vec <- rep(0, n_lambda)

  for (i in 1:(n_lambda)) {
    fit <- fitadapLASSOstandardized(Xtilde, Ytilde, lambda_seq[i], beta_start = beta, eps)
    beta_mat[, i] <- fit$beta
    fmin_vec[i] <- fit$fmin
    beta <- fit$beta
  }


  # Return output
  # lambda_seq - the actual sequence of tuning parameters used
  # beta_mat - p x length(lambda_seq) matrix of corresponding solutions at each lambda value
  # fmin_vec - length(lambda_seq) vector of corresponding objective function values at solution
  return(list(lambda_seq = lambda_seq, beta_mat = beta_mat, fmin_vec = fmin_vec))
}


#  Fit LASSO on original data using a sequence of lambda values
# X - n x p matrix of covariates
# Y - n x 1 response vector
# lambda_seq - sequence of tuning parameters, optional
# n_lambda - length of desired tuning parameter sequence, is only used when the tuning sequence is not supplied by the user
# eps - precision level for convergence assessment, default 0.001


#'  Fits adaptive LASSO
#'@inheritParams scale_X
#'@inheritParams fitadapLASSOstandardized_seq
#' @return lambda_seq = the actual sequence of tuning parameters used,beta_mat = p x length(lambda_seq) matrix of corresponding solutions at each lambda value (original data without center or scale), beta0_vec = length(lambda_seq) vector of intercepts (original data without center or scale)
#' @export fitadapLASSO
#'
#' @examples
#' #EXAMPLE 1
#' X <- matrix(rnorm(500), 50, 10)
#' Y <- rnorm(50)
#' gamma <- 2
#' # Fits adaptive LASSO
#' fit <- fitadapLASSO(X , Y , gamma = gamma)
#' # EXAMPLE 2
#' X <- matrix(rchisq(500, 3), 50, 10)
#' Y <- rbinom(50)
#' lambda_seq <- runif(100, 1, 2)
#' #Fits adaptive lasso
#' fit2 <- fitadapLASSO(X, Y, lambda_seq = lambda_seq, gamma = 0.1, eps = 0.002 )
fitadapLASSO <- function(X, Y, lambda_seq = NULL, n_lambda = 60, gamma = 0.01, eps = 0.001) {
  # Center and standardize X,Y based on standardizeXY function
  sc <- scale_X(X, Y, gamma)
  Std <- standardizeXY(X, Y, gamma)
  X <- Std$Xtilde
  Y <- Std$Ytilde

  # Fit Lasso on a sequence of values using fitadapLASSOstandardized_seq (make sure the parameters carry over)
  fit <- fitadapLASSOstandardized_seq(X, Y, lambda_seq, n_lambda, eps)
  n_lambda <- length(fit$lambda_seq)
  lambda_seq <- fit$lambda_seq
  # Perform back scaling and centering to get original intercept and coefficient vector for each lambda
  beta <- fit$beta_mat
  beta_mat <- beta / (sc$weights * Std$weights)
  beta0_vec <- Std$Ymean - ((Std$Xmeans) %*% beta_mat)

  # Return output
  # lambda_seq - the actual sequence of tuning parameters used
  # beta_mat - p x length(lambda_seq) matrix of corresponding solutions at each lambda value (original data without center or scale)
  # beta0_vec - length(lambda_seq) vector of intercepts (original data without center or scale)
  return(list(lambda_seq = lambda_seq, beta_mat = beta_mat, beta0_vec = beta0_vec))
}




#' Perform cross-validation to select the best fit and finds the optimal lambda for a particular gamma value
#'
#' @param X n x p matrix of covariates
#' @param Y n x 1 response vector
#' @param lambda_seq (optional)sequence of tuning parameters
#' @param n_lambda length of desired tuning parameter sequence, is only used when the tuning sequence is not supplied by the user
#' @param gamma scalar used in the weight vector(default value 0.01)
#' @param k  number of folds for k-fold cross-validation, default is 5
#' @param fold_ids (optional) vector of length n specifying the folds assignment (from 1 to max(folds_ids)), if supplied the value of k is ignored
#' @param eps precision level for convergence assessment, default 0.001
#'
#' @return lambda_seq - the actual sequence of tuning parameters used, beta_mat - p x length(lambda_seq) matrix of corresponding solutions at each lambda value (original data without center or scale), beta0_vec - length(lambda_seq) vector of intercepts (original data without center or scale),fold_ids - used splitting into folds from 1 to k (either as supplied or as generated in the beginning),lambda_min - selected lambda based on minimal rule,lambda_1se - selected lambda based on 1SE rule, cvm - values of CV(lambda) for each lambda,cvm - values of CV(lambda) for each lambda, cvse - values of SE_CV(lambda) for each lambda
#' @export cvLASSO
#'
#' @examples
#' X <- matrix(rnorm(500), 50, 10)
#' Y <- rnorm(50)
#' fit_cv <- cvLASSO(X, Y)
cvLASSO <- function(X, Y, lambda_seq = NULL, n_lambda = 60, gamma = 0.01, k = 5, fold_ids = NULL, eps = 0.001) {
  n <- length(Y)
  # Fit Lasso on original data using fitadapLASSO
  fit_lasso <- fitadapLASSO(X, Y, lambda_seq, n_lambda, eps)
  #  If fold_ids is NULL, split the data randomly into k folds. If fold_ids is not NULL, split the data according to supplied fold_ids.
  if (is.null(fold_ids)) {
    fold_ids <- sample(1:n, size = n) %% k + 1
  }


  # Defining vectors for loop over folds and lambdas
  lambda_seq <- fit_lasso$lambda_seq
  n_lambda <- length(lambda_seq)
  cvm <- rep(NA, n_lambda) # want to have CV(lambda)
  cvse <- rep(NA, n_lambda) # want to have SE_CV(lambda)
  cv_folds <- matrix(NA, k, n_lambda)

  for (fold in 1:k) {
    #  Create training data xtrain and ytrain, everything except fold
    Xtrain <- X[fold_ids != fold, ]
    Ytrain <- Y[fold_ids != fold]


    # Create testing data xtest and ytest, everything in fold
    Xtest <- X[fold_ids == fold, ]
    Ytest <- Y[fold_ids == fold]
    # Calculate LASSO on each fold using fitadapLASSO, and perform any additional calculations needed for CV(lambda) and SE_CV(lambda)
    # Fitting Lasso
    Lasso <- fitadapLASSO(Xtrain, Ytrain, lambda_seq, gamma, n_lambda, eps)


    #  Complete with anything else you need for cvm and cvse
    cv_folds[fold, ] <- colSums((Ytest - t(c(Lasso$beta0_vec) + t(Xtest %*% Lasso$beta_mat)))^2)
  }


  # To get cvm and cvse from cv_folds
  beta_mat <- fit_lasso$beta_mat
  beta0_vec <- fit_lasso$beta0_vec
  cvm <- colMeans(cv_folds)
  cvse <- apply(cv_folds, 2, sd) / sqrt(k)

  # Find lambda_min
  min <- which.min(cvm)
  lambda_min <- lambda_seq[min]


  # Find lambda_1SE
  lambda_seqvec <- subset(lambda_seq, cvm <= (cvm[min] + cvse[min]))
  lambda_1se <- max(lambda_seqvec)
  # Return output
  # Output from fitadapLASSO on the whole data
  # lambda_seq - the actual sequence of tuning parameters used
  # beta_mat - p x length(lambda_seq) matrix of corresponding solutions at each lambda value (original data without center or scale)
  # beta0_vec - length(lambda_seq) vector of intercepts (original data without center or scale)
  # fold_ids - used splitting into folds from 1 to k (either as supplied or as generated in the beginning)
  # lambda_min - selected lambda based on minimal rule
  # lambda_1se - selected lambda based on 1SE rule
  # cvm - values of CV(lambda) for each lambda
  # cvse - values of SE_CV(lambda) for each lambda
  return(list(lambda_seq = lambda_seq, beta_mat = beta_mat, beta0_vec = beta0_vec, fold_ids = fold_ids, lambda_min = lambda_min, lambda_1se = lambda_1se, cvm = cvm, cvse = cvse))
}
# Cross-Validation to choose gamma from a sequence of gamma values
#' Cross-Validation to choose the optimal gamma from a sequence of gamma values for a particular sequence of lambdas
#'
#' @param X n x p matrix of covariates
#' @param Y n x 1 response vector
#' @param lambda_seq (optional)sequence of tuning parameters
#' @param n_lambda length of desired tuning parameter sequence, is only used when the tuning sequence is not supplied by the user
#' @param gamma_seq (optional)sequence of gamma values(used in determining weights)
#' @param n_gamma length of the desired sequence of gamma values
#' @param k number of folds for k-fold cross-validation, default is 5
#' @param fold_ids (optional) vector of length n specifying the folds assignment (from 1 to max(folds_ids)), if supplied the value of k is ignored
#' @param eps precision level for convergence assessment, default 0.001
#'
#' @return  cvm = a n_gamma x n_lambda matrix giving CV(lambda, gamma) for each pair of (lambda, gamma), gamma_min = optimal gamma
#' @export cv.gamma
#'
#' @examples
#' X <- matrix(rnorm(500), 50, 10)
#' Y <- rnorm(50)
#' fit_cv_gamma <- cv.gamma(X , Y)
cv.gamma <- function(X, Y, lambda_seq = NULL, n_lambda = 60, gamma_seq = NULL, n_gamma = 60, k = 5, fold_ids = NULL, eps = 0.001) {
  n <- length(Y)
  #  Check for the user-supplied gamma-seq (see below)
  if (is.null(lambda_seq) == FALSE) {
    # If lambda_seq is supplied, only keep values that are >= 0, and make sure the values are sorted from largest to smallest. If none of the supplied values satisfy the requirement, print the warning message and proceed as if the values were not supplied.
    lambda_seq <- gamma_seq[gamma_seq > 0]
    if (length(gamma_seq) == 0) {
      print("Warning: gamma sequence not supplied")
      gamma_seq <- NULL
    } else {
      n_gamma <- length(gamma_seq)
    }
  }
  # If lambda_seq is not supplied, calculate lambda_max (the minimal value of lambda that gives zero solution), and create a sequence of length n_lambda as
  if (is.null(gamma_seq)) {
    gamma_seq <- seq(0.0001, 10, by = 0.1)
    n_gamma <- length(gamma_seq)
  }
 fit_cv <- cvLASSO(X, Y, lambda_seq , n_lambda , gamma , k , fold_ids , eps)
 lambda_seq <- fit_cv$lambda_seq
  # defining a cross-validation matrix
  cvm <- matrix(NA, n_gamma, n_lambda)

  for (i in 1:n_gamma) {
    cv <- cvLASSO(X, Y, lambda_seq, n_lambda, gamma_seq[i], k, fold_ids, eps)
    cvm[i, ] <- cv$cvm
  }
  #Finds the row corresponding to the minimum entry of the matrix
  gamma_min_ind <- which(cvm == min(cvm), arr.ind = T)[1]
  #Finds the gamma which minimizes the cross-validation error
  gamma_min <- gamma_seq[gamma_min_ind]
  #Finds the column corresponding to the minimum entry of the matrix
  lambda_min_ind <- which(cvm == min(cvm), arr.ind = T)[2]
  #Finds the gamma which minimizes the cross-validation error
  lambda_min <- lambda_seq[lambda_min_ind]

  # Return
  return(list(cvm = cvm, gamma_min = gamma_min,lambda_min = lambda_min))
}
