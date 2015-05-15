len<-read.table(commandArgs(TRUE)[1])
pdf(commandArgs(TRUE)[2], width=8, height=6)
hist(len$V3, breaks=80, main="Coverage Distribution", xlab="Coverage", ylab="Bases", col="#ccd9dd")
