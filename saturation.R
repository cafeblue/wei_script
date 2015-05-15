sature <- read.table(commandArgs(TRUE)[1])
title <- paste(c("Saturation Evaluation of Sample ", commandArgs(TRUE)[2]), sep="")
pdf(commandArgs(TRUE)[3], width=8, height=8)
barplot(sature[[2]], space=.2, names.arg=sature[[1]], col="#8C6CA8", main=title, xlab = "Reads Number", ylab="Isoform Number", ylim=c(0,max(sature[[2]])*1.2), cex.axis=.7, cex.names=.7)
