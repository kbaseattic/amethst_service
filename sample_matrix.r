sample_matrix <- function(file_name, file_dir = getwd(), num_perm = 1, perm_type = "sample_rand", write_files = 1, perm_dir = "./permutations/", verbose = 0, debug = 0){ #10-18-11 - function to generate permuations of data

  if ( nargs() == 0){print_usage()}

  # check to see if the permutations directory exists - if not, create one
  if ( file.exists(perm_dir)==FALSE ){
    dir.create(perm_dir)
  }

  file_path_name <<- gsub(" ", "",paste(file_dir, "/", file_name))
  my_data <<- data.matrix(read.table(file_path_name, row.names=1, check.names=FALSE, header=TRUE, sep="\t", comment.char="", quote=""))


  if(verbose==TRUE){print(my_data)}

  row_names <<- dimnames(my_data)[[1]]
  col_names <<- dimnames(my_data)[[2]]
  
  sum_data <<- base::sum(my_data)
  
  n_rows <<- dim(my_data)[1]
  index_rows <<- matrix( nrow=1, ncol=n_rows)
  for (i in 1:n_rows){
    index_rows[i] = i
  }
  
  n_cols <<- dim(my_data)[2]
  index_cols = matrix( nrow=1, ncol=n_cols)
  for (j in 1:n_cols){
    index_cols[j] = j
  }

  if(identical(perm_type, "sample_rand")){
    sample_rand_func(perm_dir, file_name, my_data, num_perm, sum_data, n_rows, n_cols, row_names, col_names, index_cols, index_rows, write_files, verbose, debug)
  }else if(identical(perm_type, "dataset_rand")){
    dataset_rand_func(perm_dir, file_name, my_data, num_perm, sum_data, n_rows, n_cols, row_names, col_names, index_cols, index_rows, write_files, verbose, debug)
  }else if(identical(perm_type, "rowwise_rand")){
    rowwise_rand_func(perm_dir, file_name, my_data, num_perm, sum_data, n_rows, n_cols, row_names, col_names, index_cols, index_rows, write_files, verbose, debug)
  }else if(identical(perm_type, "sampleid_rand")){
    sampleid_rand_func(perm_dir, file_name, my_data, num_perm, sum_data, n_rows, n_cols, row_names, col_names, index_cols, index_rows, write_files, verbose, debug)
  }else if(identical(perm_type, "complete_rand")){
    complete_rand_func(perm_dir, file_name,          num_perm, sum_data, n_rows, n_cols, row_names, col_names, index_cols, index_rows, write_files, verbose, debug)
  }else{
    print("you did not supply a valid argument for perm_type")
    print_usage() 
  }
  
}




##### SUB FUNCTIONS #####

# perform randomization that just shuffles values among fields within a sample (column) - dataset distribution is maintained, as is the distribution for each sample (column)
# shuld try to keep randomization in a sample
sample_rand_func <- function(perm_dir, file_name, my_data, num_perm, sum_data, n_rows, n_cols, row_names, col_names, index_cols, index_rows, write_files, verbose, debug) {
  for (k in 1:num_perm) {
    rand_data <<- matrix(0, n_rows, n_cols)
    dimnames(rand_data)[[1]] <<- row_names
    dimnames(rand_data)[[2]] <<- col_names
    for (cn in 1:n_cols){
      rand_data[,cn] <<- sample(my_data[,cn])
    }
    if (verbose > 0) { sum_rand_data = base::sum(rand_data); verbose_report(k, sum_data, sum_rand_data, rand_data) }
    if (write_files > 0) { write_files(perm_dir, file_name, rand_data, k) }
  }  
}



#perform randomizaton that shuffles values among fields across the whole dataset - dataset distribution is maintained, column (sample) distributions are not 
dataset_rand_func<- function(perm_dir, file_name, my_data, num_perm, sum_data, n_rows, n_cols, row_names, col_names, index_cols, index_rows, write_files, verbose, debug) {
  for (k in 1:num_perm) {
    rand_data <<- matrix(0, n_rows, n_cols)
    dimnames(rand_data)[[1]] <<- row_names
    dimnames(rand_data)[[2]] <<- col_names
    rand_values <- sample(matrix(as.numeric(paste(my_data))))
    #if ( debug == 1 ) { print("rand_values:   "); print(rand_values) }
    #if ( debug == 1 ) { print("num_rand_values"); print(n_rows*n_cols) } 
    rand_values_index = 1
    if(rand_values_index<=(n_rows*n_cols)) {
    for (nr in 1:n_rows) {
        for (nc in 1:n_cols) {
          rand_data[nr,nc] <<- (rand_values[rand_values_index])
          rand_values_index = rand_values_index+1
        }
      }
    }
    if (verbose > 0) { sum_rand_data = base::sum(rand_data); verbose_report(k, sum_data, sum_rand_data, rand_data) }
    if (write_files > 0) { write_files(perm_dir, file_name, rand_data, k) }
  }
}
  


# perform a complete randomization of counts; all counts are randomly distributed -- should lose the sample and data set distributions
# draws from the uniform multinomial distribution with exactly sum_data events in n_rows * n_cols buckets
complete_rand_func <- function(perm_dir, file_name, num_perm, sum_data, n_rows, n_cols, row_names, col_names,  index_cols, index_rows, write_files, verbose, debug) { 
  for (k in 1:num_perm) {  
    rand_data <<- matrix(0, n_rows, n_cols)
    dimnames(rand_data)[[1]] <<- row_names
    dimnames(rand_data)[[2]] <<- col_names
    for (l in 1:sum_data) {  
      sample_row <<- sample(index_rows, size=1)
      sample_col <<- sample(index_cols, size=1)
      rand_data[sample_row, sample_col] <<- (rand_data[sample_row, sample_col] + 1)  
    }
    if (verbose > 0) { sum_rand_data = base::sum(rand_data); verbose_report(k, sum_data, sum_rand_data, rand_data) }
    if (write_files > 0) { write_files(perm_dir, file_name, rand_data, k) } 
  }  
}

# scramble rows
rowwise_rand_func <- function(perm_dir, file_name, my_data, num_perm, sum_data, n_rows, n_cols, row_names, col_names, index_cols, index_rows, write_files, verbose, debug) {
  for (k in 1:num_perm) {
    rand_data <<- matrix(0, n_rows, n_cols)
    dimnames(rand_data)[[1]] <<- row_names
    dimnames(rand_data)[[2]] <<- col_names
    for (cr in 1:n_rows){
      rand_data[cr,] <<- sample(my_data[cr,])
    }
    if (verbose > 0) { sum_rand_data = base::sum(rand_data); verbose_report(k, sum_data, sum_rand_data, rand_data) }
    if (write_files > 0) { write_files(perm_dir, file_name, rand_data, k) }
  }
}

# scramble sample labels only
sampleid_rand_func <- function(perm_dir, file_name, my_data, num_perm, sum_data, n_rows, n_cols, row_names, col_names, index_cols, index_rows, write_files, verbose, debug) {
  for (k in 1:num_perm) {
    rand_data <<- matrix(0, n_rows, n_cols)
    dimnames(rand_data)[[1]] <<- row_names
    dimnames(rand_data)[[2]] <<- col_names
    scramble_col<<- sample(index_cols)

    for (cn in 1:n_cols){
      rand_data[,cn] <<- my_data[,scramble_col[cn]]
    }
    if (verbose > 0) { sum_rand_data = base::sum(rand_data); verbose_report(k, sum_data, sum_rand_data, rand_data) }
    if (write_files > 0) { write_files(perm_dir, file_name, rand_data, k) }
  }
}



verbose_report <- function(k, sum_data, sum_rand_data, rand_data) {
  print('-----------------------------------')
  print(paste("iteration:     (", k, ")"))
  print(paste("sum_data:      (", sum_data, ")"))
  print(paste("sum_rand_data: (", sum_rand_data, ")"))
  print(paste("*******rand_data:*******"))
  print(rand_data)
  print('-----------------------------------')
}



write_files <- function(perm_dir, file_name, rand_data, k) {
  file_out <- gsub(" ", "", paste(perm_dir, file_name, ".permutation.", k))
  write.table(rand_data, file=file_out, col.names=NA, row.names=TRUE, append = FALSE, sep="\t", quote = FALSE)
}



print_usage <- function() {
  writeLines("  ------------------------------------------------------------------------------
  sample_matrix.r
  ------------------------------------------------------------------------------
  DESCRIPTION:
  This script will calculate permutations and derived stats abundance count data

  USAGE:
  sample_matrix(file_name, num_perm = 1, perm_type = \"sample_rand\", write_files = 0, perm_dir = \"./permutations/\", verbose = 0, debug = 0)

       file_name   : boolean, required name of file to process
       file_dir    : string, default = getwd()  :path for the file to process
       num_perm    : integer, number of permutations
       perm_type   : string, select type of permuations to perform from
                     \"sample_rand\"   - uses \"sample\" function to shuffle fields within each column (sample)
                     (maintains total counts, the original data set distribution, and distribution in each sample(column))
                     \"dataset_rand\"  - shuffles fields within the entire data set
                     (maintains total counts and the original data set distribution)
                     \"complete_rand\" - randomly distributes sum of counts about equally sized matrix (only works with integers!!)
                     (maintains total counts, but not distribution)
       write_files : default = 0               : boolean, write a file for each permutation/iteration
       perm_dir    : default = \"./permutations/\", directory for permutation files
       verbose     : default = 0               : boolean, print verbose output to STDOUT
       debug       : default = 0               : boolean, print debug output to STDOUT
  ------------------------------------------------------------------------------
Arguents you supplied:")
  print(paste("file_name: ", file_name))
  print(paste("file_dir:  ", file_dir))
  print(paste("num_perm:  ", num_perm))
  print(paste("perm_type: ", perm_type))
  print(paste("verbose:   ", verbose))
  print(paste("debug:     ", debug))
  print("------------------------------------------------------------------------------")
  stop("you did not enter the correct args -- see above")
}


  
