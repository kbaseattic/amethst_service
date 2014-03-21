# simple script to generate 4 or 8 files used for AMETHST analysis of MG-RAST or Qiime counts
create_eight <- function(
                         counts_file,
                         percent_file,
                         percent_screen = 100,
                         create=8,
                         output_prefix="my_out"
                         ){

  # usage function
  if ( nargs() == 0 ){
    writeLines("
     You supplied no arguments

     DESCRIPTION: (create_eight.r):
     Script to generate files used for AMETHST analyses.

     create_eight( counts_file, percent_file, percent_screen=100, create=8)

          counts_file:   [required] file with the raw abundance counts, R formatted
          percent_file:  [optional - but required if create=8] file with avg percent id values for counts_file data
          percent_screen [optional - bbut required if create=8] retained values must have percentid => this value
          create:        [4 or 8]  - number of files to create (1-4 or 1-8 below):
          
               1: raw_counts    | default_percentID | singletons_removed  (*.raw.percent_default.removed) ***[identical to counts_file]***
               2: normed_values | default_percentID | singletons_removed  (*.norm.percent_default.removed)
               3: raw_values    | default_percentID | singletons_included (*.raw.percent_default.included)
               4: normed_values | default_percentID | singletons_included (*.norm.percent_default.included)

               5: raw_counts    | percent_screenID  | singletons_removed  (*.raw.percent_screen.removed)
               6: normed_values | percent_screenID  | singletons_removed  (*.norm.percent_screen.removed)
               7: raw_values    | percent_screenID  | singletons_included (*.raw.percent_screen.included)
               8: normed_values | percent_screenID  | singletons_included (*.norm.percent_screen.included)

          output_prefix: prefix for the output, default is counts_file
      
     ")
  }

  
  # function to import the data
  import_data <- function(file_name){
    data.matrix(read.table(file_name, row.names=1, header=TRUE, sep="\t", comment.char="", quote="", check.names=FALSE))
  }

#####################################################################################################################
###################################### FUNCTION TO REMOVE SINGLETONS ################################################
#####################################################################################################################
#####################################################################################################################
  remove_singletons <- function(
                                my.matrix, abundance_limit = 1, debug=FALSE, tag=""
                                )
    {
      
      if ( nargs() == 0 ){
        writeLines(
                   "No arguments supplied

                   "
                   )
        usage()
      }

      usage <- function(){
        writeLines("
     DESCRIPTION: (remove_singletons):
     This is a script to remove singleton counts (or any counts that fail to meet a specified threshold)
     from a data matrix.  It assumes that columns are samples, rows are observations (taxons or functions).
     Rows with a sum of counts < abundance limit are removed.
     - Returns a filtered matrix.
     - Produces a matrix object called filtered.matrix with the filtered matrix
       and a list object, fail.list with names of rows that were filtered 

     USAGE:
     my.matrix.without_singletons <- remove_singletons(my.matrix, abundance_limit = 1, debug=FALSE)

     EXAMPLE:
     my.matrix.without_singletons <- remove_singletons(my.matrix, abundance_limit = 1, debug=FALSE)
     
     )
     "
                   )
      }

      print(paste("     removing singletons from matrix", tag, "...")) 
      
      dim_matrix <- dim(my.matrix)
      num_row <- dim_matrix[1]
      num_col <- dim_matrix[2]
      filtered.matrix <<- matrix(0,num_row,num_col)
      dimnames(filtered.matrix)[1] <<- dimnames(filtered.matrix)[1]
      dimnames(filtered.matrix)[2] <<- dimnames(filtered.matrix)[2]
      row_sums <<- matrix(0, num_row, 1)
      zero_row_count <<- 0
      
      # create a filtered matrix in with all NA's replaced with 0's
      my.matrix[ is.na(my.matrix) ]<-0
      
      # determine the sum of counts for each row
      for (i in 1:num_row){

        row_sums[i,1] <<- sum(my.matrix[i,])
        if ( row_sums[i,1] <= abundance_limit ){
          zero_row_count <<- zero_row_count + 1
        }
      }
      
      if (debug==TRUE){ print(paste("zero_row_count:", zero_row_count)) }
      filtered.matrix <<- matrix(0, (num_row - zero_row_count), num_col)
      fail.list <<- vector(mode="list", length=zero_row_count)
      dimnames(filtered.matrix)[[1]] <<- c(1:(num_row - zero_row_count))
      dimnames(filtered.matrix)[[2]] <<- dimnames(my.matrix)[[2]]
      
      # now build a filtered matrix that tosses any rows entirely populated with zeros (anything with row count < abundance_limit)
      # as well as a list with the names of the rows that were tossed
      screen.row_count = 1
      zero.row_count = 1
      for (i in 1:num_row){
        if (row_sums[i,1] > abundance_limit){
          for (j in 1:num_col){
            filtered.matrix[screen.row_count, j] <<- my.matrix[i,j]
            dimnames(filtered.matrix)[[1]][screen.row_count] <<- dimnames(my.matrix)[[1]][i]
          }
          screen.row_count = screen.row_count + 1
        }else{
          fail.list[zero.row_count] <<- dimnames(my.matrix)[[1]][i]
          zero.row_count = zero.row_count + 1
          
        }
      }

       print(paste("     removing singletons from matrix", tag, "DONE"))
      return(filtered.matrix)

      
      
    }
#####################################################################################################################
#####################################################################################################################
#####################################################################################################################
#####################################################################################################################


  

#####################################################################################################################
###################################### FUNCTION TO NORM CENTER SCALE ################################################
#####################################################################################################################
#####################################################################################################################
  norm_center_scale <- function(matrix_in, tag="") # end inputarguments
    {
      
      if ( nargs() == 0 ){
        writeLines("
     You supplied no arguments

     DESCRIPTION: (norm_center_scale.r):
     This is a script to perform the standard MG-RAST normalization on a matrix.  It assumes that
     columns are samples, and rows are observations (taxa or function counts). This analysis has
     3 steps:
     - All values are transformed with Log2
     - Transformed values within each sample (column) are standardized - values exhibit a mean of 0 and
       standard deviation of 1 after this procedure
     - All values transformed and standardized values, across the whole matrix, are scaled from
       min:max to 0:1

     USAGE:
     my_matrix.norm-stand-scale <- norm_center_scale(my_matrix)

     where my_matrix is an R matrix 

     )
     "
                   )
      }

      print(paste("     normalizing matrix", tag, "..."))
      
      ###### replace NA's with 0
      matrix_in[ is.na(matrix_in) ]<-0

      ###### get the diensions of the input object  
      number_entries = (dim(matrix_in)[1]) # number rows
      number_samples = (dim(matrix_in)[2]) # number columns

      ###### perform log transformation  
      log2_data = log2(matrix_in + 1)

      ###### create object to store data that are log transformed and centered  
      log2_cent_data <- matrix(0, number_entries, number_samples) # <<

      ###### pull column and row names from the input_data   
      dimnames(log2_cent_data)[[2]] <- dimnames(matrix_in)[[2]] # colnames #edited 6-15-10 # <<
      dimnames(log2_cent_data)[[1]] <- dimnames(matrix_in)[[1]] # rownames #edited 6-15-10 # <<

      ###### center data from each sample (column)  
      for (i in 1:number_samples){ 
        sample = log2_data[,i]
        mean_sample = mean(sample) 
        stdev_sample = sd(sample)
        for (j in 1:number_entries){
          log2_cent_data[j,i] <- ((log2_data[j,i] - mean_sample)/stdev_sample) # <<
        } 
      }

      ###### scale values from 0 to 1  
      min_value = min(log2_cent_data)
      max_value = max(log2_cent_data)
      for (i in 1:number_samples){ 
        for (j in 1:number_entries){
          log2_cent_data[j,i] <- (  (log2_cent_data[j,i] + abs(min_value))/(max_value + abs(min_value))) #<<
        } 
      }

      ####### return norm_center_scaled matrix
      print(paste("     normalizing matrix", tag, "DONE"))
      return(log2_cent_data)
      
    }
#####################################################################################################################
#####################################################################################################################
#####################################################################################################################
#####################################################################################################################



#####################################################################################################################
################################################## MAIN #############################################################
#####################################################################################################################
#####################################################################################################################

  # use counts_file as output_prefix if no other output_prefix was specified
  if ( identical(output_prefix , "my_out") ) { output_prefix <- counts_file }
  
  # create all 8 outputs
  if ( create==8 ){
    print("     creating 8 files ...")
    
    # import data
    print("     importing data ...")
    raw_counts.matrix <- import_data(counts_file) # (output_3)
    my_id.matrix <<- import_data(percent_file)
    print("     importing data DONE")

    print("     checking agreement of counts and percentid files ...")
    # Make sure rows and columns agree between two files
    my_id.matrix[ rownames(raw_counts.matrix), ] 
    my_id.matrix[ ,colnames(raw_counts.matrix) ]
    print("     checking agreement of counts and percentid files DONE")
    
    # raw counts with singletons removed (output_1)
    raw_counts.singletons_rm.matrix <- remove_singletons(raw_counts.matrix, abundance_limit = 1, tag="make_out_1")
    #rownames(raw_counts.singletons_rm.matrix) <- rownames(raw_counts.matrix)
    #colnames(raw_counts.singletons_rm.matrix) <- colnames(raw_counts.matrix)

    # normalized raw counts with singletons removed (output_2)
    normed_counts.singletons_rm.matrix <- norm_center_scale(raw_counts.singletons_rm.matrix, tag="make_out_2")

    # normalized raw counts with singletons included (output_4)
    normed_counts.matrix <- norm_center_scale(raw_counts.matrix, tag="make_out_4")

    # counts that are the same or greater than percent_screen (filtered to remove rows that sum to 0) # make output_7
    raw_counts.pass_screen.matrix <- matrix(0,dim(raw_counts.matrix)[1],dim(raw_counts.matrix)[2]) 
    rownames(raw_counts.pass_screen.matrix) <- rownames(raw_counts.matrix)
    colnames(raw_counts.pass_screen.matrix) <- colnames(raw_counts.matrix)

    print(paste("     filtering for percentid", percent_screen, "% ID ..."))
    for (i in 1:dim(raw_counts.matrix)[1]){
      for (j in 1:dim(raw_counts.matrix)[2]){
        if ( my_id.matrix[i,j] >= percent_screen ){
          raw_counts.pass_screen.matrix[i,j]<-raw_counts.matrix[i,j]
        }
      }
    }
    print(paste("     filtering for percentid", percent_screen, "% ID DONE"))

    raw_counts.pass_screen2.matrix <- remove_singletons(raw_counts.pass_screen.matrix, abundance_limit = 0, tag="make_out_7_rm_0s")

    # pass_screen counts with singletons removed (output_5)
    raw_counts.pass_screen2.singletons_rm.matrix <- remove_singletons(raw_counts.pass_screen2.matrix, abundance_limit = 1, tag="make_out_5")
    #rownames(raw_counts.pass_screen.singletons_rm.matrix) <- rownames(raw_counts.matrix)
    #colnames(raw_counts.pass_screen.singletons_rm.matrix) <- colnames(raw_counts.matrix) 
  
    # pass_screen normalized raw counts with singletons removed (output_6)
    normed_counts.pass_screen2.singletons_rm.matrix <- norm_center_scale(raw_counts.pass_screen2.singletons_rm.matrix, tag="make_out_6")
  
    # pass_screen normalized raw counts with singletons included (output_8)
    normed_counts.pass_screen2.matrix <- norm_center_scale(raw_counts.pass_screen2.matrix, tag="make_out_8")
  
    # Write all 8 of the output files
    print("     printing output files ...")
    
    output_1_filename <- gsub(" ", "", paste( "1.", output_prefix,".raw.percent_default.removed.txt" ))
    write.table(raw_counts.singletons_rm.matrix, file = output_1_filename, col.names=NA, row.names = TRUE, sep="\t", quote=FALSE)

    output_2_filename <- gsub(" ", "", paste( "2.", output_prefix,".norm.percent_default.removed.txt" ))
    write.table(normed_counts.singletons_rm.matrix, file = output_2_filename, col.names=NA, row.names = TRUE, sep="\t", quote=FALSE)
  
    output_3_filename <- gsub(" ", "", paste( "3.", output_prefix,".raw.percent_default.included.txt" ))
    write.table(raw_counts.matrix, file = output_3_filename, col.names=NA, row.names = TRUE, sep="\t", quote=FALSE)

    output_4_filename <- gsub(" ", "", paste( "4.", output_prefix,".norm.percent_default.included.txt" ))
    write.table(normed_counts.matrix, file = output_4_filename, col.names=NA, row.names = TRUE, sep="\t", quote=FALSE)
    
    output_5_filename <- gsub(" ", "", paste( "5.", output_prefix,".raw.percent_screen_", percent_screen, "p",".removed.txt" ))
    write.table(raw_counts.pass_screen2.singletons_rm.matrix, file = output_5_filename, col.names=NA, row.names = TRUE, sep="\t", quote=FALSE)

    output_6_filename <- gsub(" ", "", paste( "6.", output_prefix,".norm.percent_screen_", percent_screen, "p", "removed.txt" ))
    write.table(normed_counts.pass_screen2.singletons_rm.matrix, file = output_6_filename, col.names=NA, row.names = TRUE, sep="\t", quote=FALSE)

    output_7_filename <- gsub(" ", "", paste( "7.", output_prefix,".raw.percent_screen_", percent_screen, "p", ".included.txt" ))
    write.table(raw_counts.pass_screen2.matrix, file = output_7_filename, col.names=NA, row.names = TRUE, sep="\t", quote=FALSE)
  
    output_8_filename <- gsub(" ", "", paste( "8.", output_prefix,".norm.percent_screen_", percent_screen, "p", ".included.txt" ))
    write.table(normed_counts.pass_screen2.matrix, file = output_8_filename, col.names=NA, row.names = TRUE, sep="\t", quote=FALSE)

    print("     printing output files DONE")
    print("     creating 8 files DONE")

  }else if (create==4) {

    # create just the first 4 outputs 
    print("     creating 4 files ...")
    
    # import data
    print("     importing data ...")
    raw_counts.matrix <- import_data(counts_file) # (output_3)
    print("     importing data DONE")
    
    # raw counts with singletons removed (output_1)
    raw_counts.singletons_rm.matrix <- remove_singletons(raw_counts.matrix, abundance_limit = 1, tag="make_out_1")
    
    # normalized raw counts with singletons removed (output_2)
    normed_counts.singletons_rm.matrix <- norm_center_scale(raw_counts.singletons_rm.matrix, tag="make_out_2")

    # normalized raw counts with singletons included (output_4)
    normed_counts.matrix <- norm_center_scale(raw_counts.matrix, tag="make_out_4")

    # Write 4 output files
    print("     printing output files ...")
    
    output_1_filename <- gsub(" ", "", paste( "1.", output_prefix,".raw.percent_default.removed.txt" ))
    write.table(raw_counts.singletons_rm.matrix, file = output_1_filename, col.names=NA, row.names = TRUE, sep="\t", quote=FALSE)

    output_2_filename <- gsub(" ", "", paste( "2.", output_prefix,".norm.percent_default.removed.txt" ))
    write.table(normed_counts.singletons_rm.matrix, file = output_2_filename, col.names=NA, row.names = TRUE, sep="\t", quote=FALSE)
  
    output_3_filename <- gsub(" ", "", paste( "3.", output_prefix,".raw.percent_default.included.txt" ))
    write.table(raw_counts.matrix, file = output_3_filename, col.names=NA, row.names = TRUE, sep="\t", quote=FALSE)

    output_4_filename <- gsub(" ", "", paste( "4.", output_prefix,".norm.percent_default.included.txt" ))
    write.table(normed_counts.matrix, file = output_4_filename, col.names=NA, row.names = TRUE, sep="\t", quote=FALSE)

    print("     printing output files DONE")
    print("     creating 4 files DONE")

  }else{

    writeLines(
                   "Invalid \"create\" value supplied, valid entries are 4 and 8

                   "
                   )
        usage()
      }
    
}
