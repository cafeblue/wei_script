cc <- scan("/dev/shm/cc.matrix", list(cc_name="", cc_num=0), sep="\t")
bp <- scan("/dev/shm/bp.matrix", list(bp_name="", bp_num=0), sep="\t")
mf <- scan("/dev/shm/mf.matrix", list(mf_name="", mf_num=0), sep="\t")
png("GO_plot.png", width=768, height=2048)
par(las=2, mfrow=c(3,1), mai=c(3.3, 1.1, 1.1, 0.1), cex.axis=1.5, cex.lab=1.5, cex.main=2, mgp=c(5,1,0))
x1 <- barplot(cc$cc_num, names.arg=cc$cc_name, main="Cellular Component", ylab="Frequency", ylim=c(0,max(cc$cc_num)*1.1))
y1 <- as.matrix(cc$cc_num)
text(x1,y1+200,as.character(cc$cc_num),cex=1.5)
x2 <- barplot(bp$bp_num, names.arg=bp$bp_name, main="Biological Process", ylab="Frequency", ylim=c(0,max(bp$bp_num)*1.1))
y2 <- as.matrix(bp$bp_num)
text(x2,y2+200,as.character(bp$bp_num),cex=1.5)
x3 <- barplot(mf$mf_num, names.arg=mf$mf_name, main="Molecular Function", ylab="Frequency", ylim=c(0,max(mf$mf_num)*1.1))
y3 <- as.matrix(mf$mf_num)
text(x3,y3+200,as.character(mf$mf_num),cex=1.5)
