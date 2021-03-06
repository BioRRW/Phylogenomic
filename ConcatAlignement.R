#!/usr/bin/env Rscript
# Exploring saturation :
#https://2infectious.wordpress.com/2014/06/17/concatenating-sequence-alignments/

library("optparse")
library("ape")


option_list = list(
  make_option(c("-f", "--file"), type="character", default=NULL,
              help="file with individual alignement file names (or locations)", metavar="character"),
  make_option(c("-g", "--graphical"), action="store_true", default=FALSE,
              help="produce a fancy graphical representation of the alignement"),
  make_option(c("-o", "--out"), type="character", default=NULL,
              help="output alignement prefix", metavar="character"),
  make_option(c("-p", "--partionFinder"), action="store_true", default=FALSE,
	      help="produce a partion file ready to ready by partion Finder")
  );

opt_parser = OptionParser(option_list=option_list);
opt = parse_args(opt_parser);

if (is.null(opt$file) & is.null(opt$out)){
  print_help(opt_parser)
  stop("Two arguments must be supplied (input and output files names).n", call.=FALSE)
}



# Reading list of alignment to concatenate :
listALN = read.table(opt$file, header=FALSE)
bindAln = c()
PartFile = c()
init=0

# Taking into account empty alignement (even as first entry)
for(i in seq(1, length(listALN$V1))){
	print(listALN$V1[i])
	aln = listALN$V1[i]
	new = read.dna(as.character(aln), format="fasta")

	#Test if empty :
	if(dim(new)[2]==0){
		write.table(c(as.character(aln), "Is empty"), file=paste(as.character(aln),".WarningEmpty", sep=""), quote=F, row.names=F)
		next
	}
	row.names(new) = gsub("_.*", "", labels(new))
	if(init==0 & dim(new)[2]!=0){ 
		bindAln = new
		if(opt$partionFinder){
			PartFile = paste("gene",as.character(i), "_pos1 ","= 1-",as.character(dim(new)[2]), as.character('\\3;'), sep='')
			PartFile = c( PartFile , paste("gene",as.character(i), "_pos2 ","= 2-",as.character(dim(new)[2]), as.character('\\3;'), sep='') )
			PartFile = c( PartFile , paste("gene",as.character(i), "_pos3 ","= 3-",as.character(dim(new)[2]), as.character('\\3;'), sep='') )
		} else {
			PartFile = paste("DNA, gene",as.character(i),"=1-",as.character(dim(new)[2]), sep='') 
		}
		init=1
	}
	else{ 
		lastPos = dim(bindAln)[2]
		bindAln = cbind(bindAln, new, fill.with.gaps=TRUE,check.names=TRUE) 
		if(opt$partionFinder){
			PartFile = c(PartFile, paste("gene",as.character(i),"_pos1 ", "= ",as.character(lastPos + 1), "-",as.character(lastPos + dim(new)[2]), as.character('\\3;'), sep='' ))
			PartFile = c(PartFile, paste("gene",as.character(i),"_pos2 ", "= ",as.character(lastPos + 2), "-",as.character(lastPos + dim(new)[2]), as.character('\\3;'), sep='' ))
			PartFile = c(PartFile, paste("gene",as.character(i),"_pos3 ", "= ",as.character(lastPos + 3), "-",as.character(lastPos + dim(new)[2]), as.character('\\3;'), sep='' ))
		} else {
			PartFile = c(PartFile, paste("DNA, gene",as.character(i),"=",as.character(lastPos + 1), "-",as.character(lastPos + dim(new)[2]), sep='' ))
		}
	}
	
}


# concatenate the alignments, checking the names of the sequences in case samples order varies between alignments, and padding out the final alignment with gaps if any samples are missing from the individual alignments
#c=cbind(a,b,fill.with.gaps=TRUE,check.names=TRUE)

# write the concat aln to a new fasta, without any column spacers or anything else between nucleotides
write.dna(bindAln, file=paste(opt$out,"fasta", sep='.'), format="fasta", colsep="")
write.table(PartFile, file=paste(opt$out, "partition",sep='.'), quote=F, col.names=F, row.names=F)


# have a look at your concatenated aln
if(opt$graphical){
	pdf(file=paste(opt$out,"visualAlignment.pdf", sep='.'))
	image.DNAbin(bindAln)
	dev.off()
}

