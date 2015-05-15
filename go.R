#bp <- read.table("/dev/shm/bp.matrix", sep="\t", header=TRUE, check.names=FALSE)
#cc <- read.table("/dev/shm/cc.matrix", sep="\t", header=TRUE, check.names=FALSE)
#mf <- read.table("/dev/shm/mf.matrix", sep="\t", header=TRUE, check.names=FALSE)
bp <- read.table(commandArgs(TRUE)[1], sep="\t", header=TRUE, check.names=FALSE)
cc <- read.table(commandArgs(TRUE)[2], sep="\t", header=TRUE, check.names=FALSE)
mf <- read.table(commandArgs(TRUE)[3], sep="\t", header=TRUE, check.names=FALSE)
samples <- length(bp) - 1
cc_names <- cc$Description
mf_names <- mf$Description
bp_names <- bp$Description
cc_matrix <- c() 
mf_matrix <- c() 
bp_matrix <- c() 
for (num in bp[2:length(bp)]) bp_matrix <- rbind(bp_matrix, num)
for (num in cc[2:length(cc)]) cc_matrix <- rbind(cc_matrix, num)
for (num in mf[2:length(mf)]) mf_matrix <- rbind(mf_matrix, num)
all_matrix <- cbind(bp_matrix, cc_matrix, mf_matrix)
color_bar <- c("#E5562A","#491A5B","#8C6CA8","#BD1B8A","#7CB6E4")
pdf(commandArgs(TRUE)[4], width=10, height=4.5)
#par(las=2, mfrow=c(1,3), mai=c(1.5, 0.1, 0.5, 0.1), mar=c(15,0.5,2,0), omi=c(0,0.5,0,0), cex.axis=0.9, cex.lab=0.9, cex.main=1, mgp=c(1,0.5,0))
#par(las=2, mfrow=c(1,3), mar=c(12,5,2,0), omi=c(0,0.5,0,0), cex.axis=0.9, cex.lab=0.9, cex.main=1, mgp=c(3,0.5,0))
par(las=2, mfrow=c(1,3), mai=c(1.5,0,0.2,0), omi=c(0,0.5,0,0), cex.axis=0.9, cex.lab=0.9, cex.main=1, mgp=c(3,0.5,0))
layout(matrix(c(1,2,3), 1, 3, byrow = TRUE), widths=c(length(bp_names),length(cc_names), length(mf_names)))
#barplot(bp_matrix, beside=TRUE, names.arg=bp_names, main="Biological Process", col=color_bar[1:length(names(mf)[-1])], ylab="Frequency", ylim=c(0,max(all_matrix)*1.2))
#barplot(cc_matrix, beside=TRUE, names.arg=cc_names, main="Cellular Component", col=color_bar[1:length(names(mf)[-1])], ylim=c(0,max(all_matrix)*1.2),yaxt='n', ann=FALSE)
#barplot(mf_matrix, beside=TRUE, legend.text=names(mf)[-1], args.legend=list(horiz=F), col=color_bar[1:length(names(mf)[-1])], names.arg=mf_names, main="Molecular Fucntion", ylim=c(0,max(all_matrix)*1.2),yaxt='n', ann=FALSE)

bar_bp <- barplot(bp_matrix, beside=TRUE, main="Biological Process", col=color_bar[1:length(names(mf)[-1])], ylab="Frequency", ylim=c(0,max(all_matrix)*1.2))
bar_bp <- matrix(bar_bp, length(bp_names), samples , byrow=TRUE);
bar_bp <- (bar_bp[,1] + bar_bp[,samples]) / 2
text(bar_bp, par("usr")[1], labels =bp_names , srt = 45, adj = c(1.0,1.0), xpd = NA, cex=.8)
bar_cc <- barplot(cc_matrix, beside=TRUE, main="Cellular Component", col=color_bar[1:length(names(mf)[-1])], ylim=c(0,max(all_matrix)*1.2),yaxt='n', ann=FALSE)
bar_cc <- matrix(bar_cc, length(cc_names), samples , byrow=TRUE);
bar_cc <- (bar_cc[,1] + bar_cc[,samples]) / 2
text(bar_cc, par("usr")[1],labels =cc_names , srt = 45, adj = c(1.0,1.0), xpd = NA, cex=.8)
bar_mf <-barplot(mf_matrix, beside=TRUE, legend.text=names(mf)[-1], args.legend=list(horiz=F), col=color_bar[1:length(names(mf)[-1])], main="Molecular Fucntion", ylim=c(0,max(all_matrix)*1.2),yaxt='n', ann=FALSE)
bar_mf <- matrix(bar_mf, length(mf_names), samples , byrow=TRUE);
bar_mf <- (bar_mf[,1] + bar_mf[,samples]) / 2
text(bar_mf, par("usr")[3], labels =mf_names , srt = 45, adj = c(1.0,1.1), xpd = NA, cex=.8)
