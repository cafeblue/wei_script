library(limma)
pdf("Gene_Express_Venn.pdf", width=6, height=6)
venn_file <- read.table("/dev/shm/venn.matrix", header=TRUE, check.names=FALSE)
venn_matrix <- venn_file[-1]
venn_ids <- names(venn_file)
venn_ids <- venn_ids[-1]
venn_count = vennCounts(venn_matrix)
vennDiagram(venn_matrix, names=venn_ids, main="Gene Expressed in Different Samples", cex=1)
