library("ALL")
library("gplots")
hm <- read.table(commandArgs(TRUE)[1], sep="\t", header=TRUE, check.names=FALSE)
hm_matrix <- c()
for (num in hm[2:length(hm)]) hm_matrix <- cbind(hm_matrix, num)
rownames(hm_matrix) <- hm[[1]]
colnames(hm_matrix) <- names(hm)[-1]
hm_matrix <- log10(hm_matrix)
pdf(commandArgs(TRUE)[2], width=7, height=7)
heatmap.2(hm_matrix, col=redgreen(75), scale="column", key=TRUE, keysize=1, symkey=FALSE, density.info="none", trace="none", cexRow=0.8, cexCol=0.9, margins=c(6,6))
