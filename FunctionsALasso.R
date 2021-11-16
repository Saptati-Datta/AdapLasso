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