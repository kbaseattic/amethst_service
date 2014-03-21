# Kevin P. Keegan - all rights reserved - 11-12-12
# Function to remove "single counts -- or any count that is <= abundance_limit
remove_singletons <- function(
                              my.matrix, abundance_limit = 1, debug=FALSE
                              )
{

  if ( nargs() == 0 ){
     writeLines("
     You supplied no arguments

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
    #for (j in 1:num_col){
    #  if (my_matrix[i,j] > abundance_limit){
    #    filtered_matrix[i,j] <<- my_matrix[i,j] 
    #  }
    #}
    row_sums[i,1] <<- sum(my.matrix[i,])
    #if (debug == TRUE){print(paste("row:", i, "sum:", row_sums[i,1]))}
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
        #if(debug==TRUE){print(paste("i: ",i))}
        #if(debug==TRUE){print(paste("screen.row_count: ",screen.row_count))}
        #if(debug==TRUE){print(paste("j: ",j))}
        dimnames(filtered.matrix)[[1]][screen.row_count] <<- dimnames(my.matrix)[[1]][i]
      }
      screen.row_count = screen.row_count + 1
    }else{
      fail.list[zero.row_count] <<- dimnames(my.matrix)[[1]][i]
      zero.row_count = zero.row_count + 1

    }
  }

  return(filtered.matrix)
  
}
