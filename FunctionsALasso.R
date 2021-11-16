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