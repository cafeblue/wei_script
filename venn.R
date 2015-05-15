library(VennDiagram)
venn_file <- read.table(commandArgs(TRUE)[1], header=TRUE, check.names=FALSE)
arg1 <- venn_file[commandArgs(TRUE)[2]][!is.na(venn_file[commandArgs(TRUE)[2]])]
arg2 <- venn_file[commandArgs(TRUE)[3]][!is.na(venn_file[commandArgs(TRUE)[3]])]
title <- paste("Venn of", commandArgs(TRUE)[2], "and", commandArgs(TRUE)[3], sep=" ")
venn.diagram(list( commandArgs(TRUE)[2]=arg1, commandArgs(TRUE)[3]=arg2), commandArgs(TRUE)[4], main=title, scaled=FALSE, main.cex=2, col="transparent", fill=c("cornflowerblue", "darkorchid1"), alpha=.4, height=768, width=768, resolution=500, unit="px" )
