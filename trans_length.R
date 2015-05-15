len<-scan("/dev/shm/trans_length.matrix")
pdf("Trans_Length.pdf", width=8, height=6)
hist(len, breaks=20, main="Distribution of Sequence Length", xlab="Length", col="#ccd9dd")
