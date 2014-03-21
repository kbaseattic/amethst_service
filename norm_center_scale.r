# Kevin P. Keegan - all rights reserved - 11-12-12
# function to perform log2 transformation and standardization persample,
# followed by linear scaling accross all samples
norm_center_scale <<- function(matrix_in) # end inputarguments
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

  
###### replace NA's with 0
  matrix_in[ is.na(matrix_in) ]<-0

###### get the diensions of the input object  
  number_entries = (dim(matrix_in)[1]) # number rows
  number_samples = (dim(matrix_in)[2]) # number columns

###### perform log transformation  
  log2_data = log2(matrix_in + 1)

###### create object to store data that are log transformed and centered  
  log2_cent_data <<- matrix(0, number_entries, number_samples)

###### pull column and row names from the input_data   
  dimnames(log2_cent_data)[[2]] <<- dimnames(matrix_in)[[2]] # colnames #edited 6-15-10
  dimnames(log2_cent_data)[[1]] <<- dimnames(matrix_in)[[1]] # rownames #edited 6-15-10

###### center data from each sample (column)  
  for (i in 1:number_samples){ 
    sample = log2_data[,i]
    mean_sample = mean(sample) 
    stdev_sample = sd(sample)
    for (j in 1:number_entries){
      log2_cent_data[j,i] <<- ((log2_data[j,i] - mean_sample)/stdev_sample)
    } 
  }

###### scale values from 0 to 1  
  min_value = min(log2_cent_data)
  max_value = max(log2_cent_data)
  for (i in 1:number_samples){ 
    for (j in 1:number_entries){
      log2_cent_data[j,i] <<- (  (log2_cent_data[j,i] + abs(min_value))/(max_value + abs(min_value)))
    } 
  }

####### return norm_center_scaled matrix
  return(log2_cent_data)

}

  ## max_value= max(log2_cent_data)
  ## for (i in 1:number_samples){ 
  ##   for (j in 1:number_entries){
  ##     if (log2_cent_data[j,i] == 0){
  ##     }else{
  ##       log2_cent_data[j,i] <<- ((log2_cent_data[j,i]/max_value))
  ##     } 
  ##   }
  ## }


  ## min_value = min(log2_cent_data)
  ## for (i in 1:number_samples){ 
  ##   for (j in 1:number_entries){
  ##     log2_cent_data[j,i] <<- (log2_cent_data[j,i] + abs(min_value))
  ##   } 
  ## }
  ## max_value= max(log2_cent_data)
  ## for (i in 1:number_samples){ 
  ##   for (j in 1:number_entries){
  ##     if (log2_cent_data[j,i] == 0){
  ##     }else{
  ##       log2_cent_data[j,i] <<- ((log2_cent_data[j,i]/max_value))
  ##     } 
  ##   }
  ## }
  

