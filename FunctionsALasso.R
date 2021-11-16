# ADAPTIVE LASSO

# Transforming X by dividing with elements of the weight matrix
# Computing scaled inputs using LARS algorithm
scale_X <- function(X, Y, gamma) {
  library(glmnet)
  # Computing the best lambda for the Ridge estimator
  cv_mod <- cv.glmnet(X, Y, alpha = 0)
  # Optimal value of lambda for Ridge
  lambda_min <- cv_mod$lambda.min
  p <- ncol(X)
  n <- nrow(X)
  if (rankMatrix(X) < p) {
    # Calculating ridge estimator
    beta <- solve(crossprod(X) + lambda_min * diag(p)) %*% crossprod(X, Y)
  } else {
    # Calculating OLS
    beta <- solve(t(X) %*% X) %*% t(X) %*% Y
  }
  weights <- as.vector(abs(beta)^gamma)
  #Scales X
  X_w <- t(t(X)/weights)
  #returns scaled X
  return(list(X_w=X_w, weights = weights))
}


# STANDARDIZING INPUTS
standardizeXY <- function(X, Y, gamma) {
  n <- length(Y)
  p <- ncol(X)
  #Scaling X
  Xtilde <- scale_X(X,Y,gamma)$X_w
  Xmeans <- colMeans(Xtilde)
  # Center Y
  Ymean <- mean(Y)
  Ytilde <- Y - Ymean
  # Return:
  # Xtilde - centered and appropriately scaled X
  # Ytilde - centered Y
  # Ymean - the mean of original Y
  # Xmeans - means of columns of X (vector)
  # weights - defined as sqrt(X_j^{\top}X_j/n) after centering of X but before scaling
  return(list(Xtilde = Xtilde, Ytilde = Ytilde, Ymean = Ymean,Xmeans = Xmeans))
}

#Soft-thresholding of a scalar a at level lambda
soft <- function(a, lambda) {
  if (a > lambda) {
    return(a - lambda)
  } else if (a < (-lambda)) {
    return(a + lambda)
  } else {
    return(0)
  }
}

# Fit Adaptive LASSO on standardized data for a given lambda
# Xtilde - centered and scaled X, n x p
# Ytilde - centered Y, n x 1 (vector)
# lamdba - tuning parameter
# beta_start - p vector, an optional starting point for coordinate-descent algorithm
# eps - precision level for convergence assessment, default 0.001
fitadapLASSOstandardized <- function(Xtilde, Ytilde, lambda,gamma, beta_start = NULL, eps = 0.001) {
  n <- length(Ytilde)
  p <- ncol(Xtilde)
  # [ToDo]  Check that n is the same between Xtilde and Ytilde
  if (nrow(Xtilde) != length(Ytilde)) {
    stop("Error: nrow(X) and length(Y) are not equal")
  }
  # Check that lambda is non-negative
  if (lambda < 0) {
    stop("Error: Lambda is negative")
  }
  #Check that gamma is non-negative
  if (gamma < 0) {
    stop("Error: gamma is negative")
  }
  #  Check for starting point beta_start. If none supplied, initialize with OLS. If supplied, check for compatibility with Xtilde in terms of p
  if (is.null(beta_start)) {
    beta_start <- solve(t(Xtilde) %*% Xtilde) %*% t(Xtilde) %*% Y
  } else if (length(beta_start) != p) {
    stop("Error: dimension of p and ncol(X) do not match", ncol(Xtilde))
  }
  #  Coordinate-descent implementation. Stop when the difference between objective functions is less than eps for the first time.
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