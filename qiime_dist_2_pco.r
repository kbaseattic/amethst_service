qiime_dist_2_pco <<-  function(
                                file_in,
                                file_out= "./my_PCoA"
                                #dist_method = "weighted_unifrac"
                                )
  
{
  # load packages
  #suppressPackageStartupMessages(library(matlab))
  suppressPackageStartupMessages(library(ecodist))
  #suppressPackageStartupMessages(library(Cairo))
  #suppressPackageStartupMessages(library(gplots))

  # define sub functions
  func_usage <- function() {
    writeLines("
     You supplied no arguments

     DESCRIPTION: (import_qiime_dist.r):
     Import a qiime distance matrix from file to a \"dist\" object.

     USAGE: MGRAST_plot_pca(
                            file_in = no default arg                               # (string)  input data file            
                            file_out = \"./my_PCoA\"                                       # (string) file out
                             )\n"
               )
    stop("import_qiime_dist stopped\n\n")
  }

  # import a qiime created distance matrix (very easy, already fomratted for R)
  unifrac.table <- read.table(file_in) # pain in the neck -- just use this to extract names -- can't do it from dist with standard methods
  unifrac.dist <- as.dist(read.table(file_in))
  
#################################################
  # convert unifrac dist to plot_pco *.DIST
  #dist_matrix <<- find_dist(my_data, dist_method)
  #DIST_file_out <- gsub(" ", "", paste(output_DIST_dir, file_in, ".", dist_method, ".DIST"))
  #if (print_dist > 0) { write_file(file_name = DIST_file_out, data = data.matrix(dist_matrix)) }
#################################################
  
  # perform the pco
  my_pco <<- pco(unifrac.dist)

  # scale eigen values from 0 to 1, and label them
  eigen_values <<- my_pco$values
  scaled_eigen_values <<- (eigen_values/sum(eigen_values))
  for (i in (1:dim(as.matrix(scaled_eigen_values))[1])) {names(scaled_eigen_values)[i]<<-gsub(" ", "", paste("PCO", i))}
  scaled_eigen_values <<- data.matrix(scaled_eigen_values)
  
  # label the eigen vectors
  eigen_vectors <<- data.matrix(my_pco$vectors) 
  #dimnames(eigen_vectors)[[1]] <<- dimnames(my_data)[[1]]
  dimnames(eigen_vectors)[[1]] <<- dimnames(unifrac.table)[[1]]

  # write eigen values and then eigen vectors to file_out
  #PCoA_file_out = gsub(" ", "", paste(output_dir, file_in, ".", dist_method, ".PCoA"))

  
  write(file=file_out, paste("# file_in: ", file_in,
          "\n#________________________________",
          "\n# EIGEN VALUES (scaled 0 to 1) >",
          "\n#________________________________"),
        append=FALSE)
  
  write.table(scaled_eigen_values, file=file_out, col.names=FALSE, row.names=TRUE, append = TRUE, sep="\t")
  write(file=file_out, paste("#________________________________",
          "\n# EIGEN VECTORS >",
          "\n#________________________________"),
          append=TRUE)
  write.table(eigen_vectors, file=file_out, col.names=FALSE, row.names=TRUE, append = TRUE, sep="\t")
    
}






  
  
