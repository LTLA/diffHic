# This tests the post-hoc clustering methods. We're just recording results here,
# rather than doing rigorous tests, because that would be equivalent to just repeating
# the R code and that seems a bit like a waste of time. 

suppressPackageStartupMessages(require(diffHic))
checkResults <- function(data.list, result.list, pval.col="PValue", tol, ..., true.pos) {
    out <- diClusters(data.list, result.list, cluster.args=list(tol=tol), pval.col=pval.col, ...)

    # Checking that the clustering is fine.
    all.ids <- unlist(out$indices)
    was.sig <- !is.na(all.ids)
    if (is.list(data.list)) { 
        ref <- do.call(rbind, data.list)[was.sig,]
    } else {
        ref <- data.list[was.sig,]
    }
    bbox <- boundingBox(ref, all.ids[was.sig])
    stopifnot(all(anchors(bbox, type="first")==anchors(out$interactions, type="first")))
    stopifnot(all(anchors(bbox, type="second")==anchors(out$interactions, type="second")))

    # Checking that the right interactions were chosen.
    if (is.data.frame(result.list)) { 
        all.ps <- result.list[,pval.col] 
    } else { 
        all.ps <- unlist(sapply(result.list, FUN=function(x) { x[,pval.col] })) 
    }
    if (any(was.sig) && any(!was.sig)) { stopifnot(max(all.ps[was.sig]) < min(all.ps[!was.sig])) }

    # Reporting the observed and estimated FDRs.
    np <- sum(!overlapsAny(out$interactions, true.pos))
    return(data.frame(Observed=np/length(out$interactions), Estimated=out$FDR))
}

set.seed(100)
regions <- GRanges("chrA", IRanges(1:500, 1:500))
first.anchor <- sample(500, 1000, replace=TRUE)
second.anchor <- sample(500, 1000, replace=TRUE)
interactions <- InteractionSet(matrix(0, nrow=1000, ncol=1), GInteractions(first.anchor, second.anchor, regions, mode="reverse"))
test.p <- runif(1000)
test.p[rep(1:2, 100) + rep(0:99, each=2) * 10] <- 0 

true.pos <- interactions[test.p==0]
checkResults(interactions, data.frame(PValue=test.p), tol=0, target=0.05, true.pos=true.pos)
checkResults(list(interactions), list(data.frame(PValue=test.p)), tol=0, target=0.05, true.pos=true.pos)
checkResults(list(interactions), list(data.frame(PValue=test.p)), tol=10, target=0.05, true.pos=true.pos)

checkResults(list(interactions, interactions[1:10]), list(data.frame(PValue=test.p), data.frame(PValue=test.p[1:10])), tol=0, target=0.05, true.pos=true.pos) # Multiple entries
checkResults(list(interactions, interactions[1:10]), list(data.frame(PValue=test.p), data.frame(PValue=test.p[1:10])), equiweight=FALSE, tol=0, target=0.05, true.pos=true.pos)

# Smaller number of DI entries
set.seed(50)
test.p <- runif(1000)
test.p[rep(1:2, 50) + rep(0:49, each=2) * 10] <- 0  

true.pos <- interactions[test.p==0]
checkResults(list(interactions), list(data.frame(PValue=test.p)), tol=0, target=0.05, true.pos=true.pos)
checkResults(list(interactions), list(data.frame(PValue=test.p)), tol=5, target=0.05, true.pos=true.pos)
checkResults(list(interactions), list(data.frame(PValue=test.p)), tol=5, target=0.1, true.pos=true.pos)
checkResults(list(interactions), list(data.frame(whee=test.p)), tol=2, pval.col="whee", target=0.05, true.pos=true.pos)

signs <- ifelse(rbinom(1000, 1, 0.5)!=0, 1, -1)
checkResults(list(interactions, interactions[1:10]), list(data.frame(PValue=test.p, logFC=signs), data.frame(PValue=test.p[1:10], logFC=signs[1:10])), 
             tol=0, target=0.05, true.pos=true.pos)
checkResults(list(interactions, interactions[1:10]), list(data.frame(PValue=test.p, logFC=signs), data.frame(PValue=test.p[1:10], logFC=signs[1:10])), 
             tol=0, fc.col="logFC", target=0.05, true.pos=true.pos)

checkResults(list(interactions), list(data.frame(PValue=test.p)), tol=0, grid.length=11, target=0.05, true.pos=true.pos) # Fiddling with grid search parameters.
checkResults(list(interactions), list(data.frame(PValue=test.p)), tol=0, iterations=10, target=0.05, true.pos=true.pos)

###################################################
