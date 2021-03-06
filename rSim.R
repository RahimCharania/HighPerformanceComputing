library(Rmpi)
library(Rcpp)





X= Sys.time()
a <- matrix(c(0.5,0.1,0.1,0.5),nrow=2)
u <- matrix(rnorm(10000),ncol=2)
## Let’s start with the R version
rSim <- function(coeff, errors) {
simdata <- matrix(0, nrow(errors), ncol(errors))
for (row in 2:nrow(errors)) {
simdata[row,] = coeff %*% simdata[(row-1),] + errors[row,]
}
return(simdata)
}


rData <- rSim(a, u)
Sys.time()-X

Z=Sys.time()

suppressMessages(require(inline))
code <-'
arma::mat coeff = Rcpp::as<arma::mat>(a);
arma::mat errors = Rcpp::as<arma::mat>(u);
int m = errors.n_rows;
int n = errors.n_cols;
arma::mat simdata(m,n);
simdata.row(0) = arma::zeros<arma::mat>(1,n);
for (int row=1; row<m; row++) {
simdata.row(row) = simdata.row(row-1)*trans(coeff)
+ errors.row(row);
}
return Rcpp::wrap(simdata);
'


rcppSim <- cxxfunction(signature(a="numeric",u="numeric"),code,plugin="RcppArmadillo")
##rcppData <- rcppSim(a,u) # generated by C++ code
##stopifnot(all.equal(rData, rcppData)) # checking results

Sys.time()-Z



suppressMessages(library(rbenchmark))
res <- benchmark(rcppSim(a,u),
rSim(a,u),
columns=c("test", "replications", "elapsed",
"relative", "user.self", "sys.self"),
order="relative")
