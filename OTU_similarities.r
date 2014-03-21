OTU_dists<- function(
                     file_in,
                     input_dir = "./",
                     output_PCoA_dir = "./",
                     print_dist = 1,
                     output_DIST_dir = "./",
                     dist_method = "OTU",
                     headers = 1,
                     debug = FALSE
                     )

{

# load packages
#  suppressPackageStartupMessages(library(matlab))      
  suppressPackageStartupMessages(library(ecodist))

##### SUBS
  func_usage <- function() {
    writeLines("
     You supplied no arguments

     DESCRIPTION: (OTU_similarities.r):
     This script will perform a PCoA analysis on the inputdata
     using the selected distance metric.
     Only two methods are possible in this version - OTU and w_OTU
     OTU = Zhou et al, w_OTU = abundance weighted OTU
     for other methods see MGRAST_plot_pco.r (and plot_pco_with_stats.pl)
     and plot_qiime_pco_with_stats.pl

     Output always produces a
     *.PCoA file that has the normalized eigenvalues (top n lines)
     and eigenvectors (bottom n x m matris, n lines) where n is the
     number of variables (e.g.subsystems), and m the number of
     samples. You can also choose to produce *.DIST files that contain
     the distance matrix used to generate the PCoA.

     USAGE: MGRAST_plot_pca(
                            file_in = no default arg                               # (string)  input data file            
                            input_dir = \"./\"                                       # (string)  directory(path) of input
                            output_PCoA_dir = \"./\"                                 # (string)  directory(path) for output PCoA file
                            print_dist = TRUE                                        # (boolean) print the DIST file (distance matrix)
                            output_DIST_dir = \"./\"                                 # (string)  directory(path) for output DIST file 
                            dist_method = \"OTU\"                            # (string)  distance/dissimilarity metric,
                                          (choose from one of the following options)
                                          \"OTU\" | \"w_OTU\"
                            headers = 0                                            # (booealan) print headers in output PCoA file 
                            )\n"
               )
    stop("OTU_similarities stopped\n\n")
  }


  # Function that calculates the dist matrix
  produce_dist <- function(M, dist_method, dist){

   n<-nrow(M)
   for (i in 1:(n-1)) {
     for (j in (i+1):n) {
       k <- n*(i-1) - i*(i-1)/2 + j-i
       Both <- M[i,] & M[j,]
       Either <- M[i,] | M [j,]
       if ( dist_method == "w_OTU" ){ dist [k] = 100 * sum ( Both*M[i,] , Both*M[j,] ) / sum ( M[i,] , M[j,] ) }
       else { dist [k] = 100 * sum (Both) / sum(Either) }
     }
   }
   return(dist)   
 }

 # Function to write output
  write_file <- function(data, file_name) {
    write.table(data, file=file_name, col.names=NA, row.names=TRUE, append = FALSE, sep="\t", quote = FALSE)
  }

  ##### END SUBS

  
  # stop and give the usage if the proper number of arguments is not given
  if ( nargs() == 0 ){
    func_usage()
  }

  # load data
  my_input_path_file <- gsub(" ", "", paste(input_dir,file_in))
  #Input <<- read.table(my_input_path_file, header = 1, sep = "\t", row.names = 1, quote = "", stringsAsFactors = FALSE, check.names=FALSE)
  Input <<- read.table(my_input_path_file, row.names=1, check.names=FALSE, header=TRUE, sep="\t", comment.char="", quote="", stringsAsFactors = FALSE )
  #           read.table(input_data_path,   row.names=1, check.names=FALSE, header=TRUE, sep="\t", comment.char="", quote="")
  #my_data <<- flipud(rot90(data.matrix(read.table(input_data_path, row.names=1, check.names=FALSE, header=TRUE, sep="\t", comment.char="", quote=""))))

  
  num_data_rows = dim(Input)[1] # substitute 0 for NA's if they exist in the data
  num_data_cols = dim(Input)[2]
  for (row_num in (1:num_data_rows)){
    for (col_num in (1:num_data_cols)){
      if (is.na(Input[row_num, col_num])){
        Input[row_num, col_num] <<- 0
      }
    }
  }

  row.names (Input) <- NULL
  M <- t (Input)
  
  # calculate distance matrix and produce *.DIST output files
  dist <- stats::dist (M)
  dist <- produce_dist(M, dist_method, dist)
  
  # generate string used to name the output *.DIST file 
  DIST_file_out <- ""
  if ( dist_method== "w_OTU" ) { DIST_file_out <- gsub(" ", "", paste(output_DIST_dir, file_in, ".", dist_method, ".DIST")) }
  else { DIST_file_out <- gsub(" ", "", paste(output_DIST_dir, file_in, ".", dist_method, ".DIST")) }
  if ( print_dist == 1 ) { write_file(file_name = DIST_file_out, data = data.matrix(dist)) }
  
  # perform pco and write output(s)    
  my_pco <- pco(dist)

  # scale eigen values from 0 to 1, and label them
  eigen_values <<- my_pco$values
  scaled_eigen_values <<- (eigen_values/sum(eigen_values))
  for (i in (1:dim(as.matrix(scaled_eigen_values))[1])) {names(scaled_eigen_values)[i]<<-gsub(" ", "", paste("PCO", i))}
  scaled_eigen_values <<- data.matrix(scaled_eigen_values)

  # label the eigen vectors
  eigen_vectors <<- data.matrix(my_pco$vectors) 
  dimnames(eigen_vectors)[[1]] <<- dimnames(Input)[[2]] #dimnames(Input)[[1]]
 
  # write eigen values and then eigen vectors to file_out
  PCoA_file_out = gsub(" ", "", paste(output_PCoA_dir, file_in, ".", dist_method, ".PCoA"))

  if ( headers == 1 ){
    write(file = PCoA_file_out, paste("# file_in    :", file_in,
            "\n# dist_method:", dist_method,
            "\n#________________________________",
            "\n# EIGEN VALUES (scaled 0 to 1) >",
            "\n#________________________________"),
          append=FALSE)
    write.table(scaled_eigen_values, file=PCoA_file_out, col.names=FALSE, row.names=TRUE, append = TRUE, sep="\t")
  }else{
    write.table(scaled_eigen_values, file=PCoA_file_out, col.names=FALSE, row.names=TRUE, append = FALSE, sep="\t")
  }
  
  if ( headers == 1 ){
    write(file = PCoA_file_out, paste("#________________________________",
            "\n# EIGEN VECTORS >",
            "\n#________________________________"),
          append=TRUE)
  }
  
  write.table(eigen_vectors, file=PCoA_file_out, col.names=FALSE, row.names=TRUE, append = TRUE, sep="\t")
  
}
