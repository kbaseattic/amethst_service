dist_hist <- function(original_matrix_file, groups_list = "AMETHST_groups", perm_dists_path = "./DISTs", write_tables=TRUE, debug = FALSE){

# dist_hist <- function(distance_matrix_file, file_path = "./", groups_list = "groups", perm_dists_path = "./DISTs", debug = 0){ 


# Sub to process counts for an individual dist file
# return two matrices - one for within and one for between group counts
# This sub is the hear of the script  
  process_dist <- function(dist_matrix, groups) {

   # create some file names for output
   # real_table = paste(original_matrix_file, ".real_counts", sep="")
   # perm_table = paste(original_matrix_file, ".perm_counts_acg", sep="")
    
  # read in the groups
    groups_in <- readLines(groups_list)
    num_groups <- dim(data.frame(groups_in))[1]
  
  # read in the dists
    distance_matrix <- data.matrix(read.table(dist_matrix, row.names=1, header=TRUE, check.names=FALSE, sep="\t", comment.char="", quote=""))

  # initialize arrays to hold the distances for each unique pair of samples -- within and between group in separate arrays
    within_group_distances <- matrix()
    between_group_distances <- matrix()
  
    for (i in 1:num_groups){
     
      group_samples <- strsplit(groups_in[i], ",")
      if(debug==TRUE){print(paste("group_samples: ", group_samples))}
      num_samples <- dim(data.frame(group_samples))[1]
      num_pairs <- dim(combn(num_samples,2))[2]
      if(debug==TRUE){print(paste("num_pairs: ",num_pairs))}
      if(debug==TRUE){print(paste("num_samples: ",num_samples))}
    #group_distances <<- matrix (NA, size(combn(num_samples,2))[2], 1) #####
      #group_distances <<- matrix (NA, dim(combn(num_samples,2))[2], 1) #####
      group_distances <- matrix (NA, num_pairs, 1)
      
      
      #dimnames(group_distances)[[1]] <- c(rep("", dim(group_distances)[[1]]))

      if(debug==TRUE){print(paste("dim(group_distances)[[1]] : ",dim(group_distances)[[1]]))}
      dimnames(group_distances)[[1]] <- c(rep("",num_pairs))
      
      #dimnames(group_distances)[[1]] <- c(rep("", dim(group_distances)[[1]]))####<---
      
      gd_index <- 1 
    
      for (m in 2:num_samples){ # get all of the unique non-redundant pairs
      
        for (n in 1:(m-1)){
          
          if (
              identical( toString(charmatch( group_samples[[1]][m], dimnames(distance_matrix)[[1]])), "NA" ) ||
              identical( toString(charmatch(   group_samples[[1]][n], dimnames(distance_matrix)[[1]])), "NA" )
              )
            {
              
              stop (paste("sample names in the groups file:\n", groups_list,"\n (", noquote(group_samples[[1]][m]), " or ", noquote(group_samples[[1]][n]), ")\n are not in the distance_matrix:\n",dist_matrix, "\n",
                          "check the names in the groups and distance_matrix files to make sure that they match\n\n"))    
            }
          
          #if (debug==TRUE){ print(paste("gd_index =", gd_index, "distance:", distance_matrix[ noquote(group_samples[[1]][m]), noquote(group_samples[[1]][n]) ] )) } #####
          group_distances[gd_index,1] <- distance_matrix[ noquote(group_samples[[1]][m]), noquote(group_samples[[1]][n]) ] #####
          #if(debug==TRUE){print(paste("group_samples[[1]][n] :", group_samples[[1]][n]))}
          #if(debug==TRUE){print(paste("group_samples[[1]][m] :", group_samples[[1]][m]))}
          #if(debug==TRUE){print(paste("gd_index: ",gd_index))}
          dimnames(group_distances)[[1]][gd_index] <- paste(group_samples[[1]][n], "::", group_samples[[1]][m])
          gd_index <- gd_index + 1
          
        }
        
      }
      
      if ( i == 1 ){
        within_group_distances <- group_distances
      }else{
        within_group_distances <- rbind(within_group_distances, group_distances)
      }

      #return(group_distances)
      
    }
    
    
  #  
    for (p in 2:num_groups){ # get all of the unique non-redundant pairs
      
      for (q in 1:(p-1)){
        
        alpha_samples <- strsplit(groups_in[p], ",")
        num_alpha_samples <- dim(data.frame(alpha_samples))[1]
                                        #alpha_distances <- matrix(NA, size(combn(num_alpha_samples,2))[2], 1) ### ###  
        
        beta_samples <- strsplit(groups_in[q], ",")
        num_beta_samples <- dim(data.frame(beta_samples))[1]
                                        #beta_distances <- matrix(NA, size(combn(num_beta_samples,2))[2], 1) ### ###
        
        alpha_beta_distances <- matrix(NA, (num_alpha_samples*num_beta_samples), 1) # alpha and beta should be the same size
        dimnames(alpha_beta_distances)[[1]] <- c(rep("",num_alpha_samples*num_beta_samples)) #<--



        dist_index <- 1 ### ###
        
                                        #write(gsub(" ", "", (paste(">>Group(", p, ")::Group(", q, ")"))), file=output_file, append=TRUE)
        
        for (na in 1:num_alpha_samples){
          for (nb in 1:num_beta_samples){
            
            alpha_beta_distances[dist_index,1] <- distance_matrix[ noquote(alpha_samples[[1]][na]), noquote(beta_samples[[1]][nb]) ] ### ###
            dimnames(alpha_beta_distances)[[1]][dist_index] <- paste(alpha_samples[[1]][na], "::", beta_samples[[1]][nb]) #<--
            dist_index <- dist_index + 1 ### ###
            
          }
        }
        
      }
      
      if( (p-1) == 1 ){
        between_group_distances <- alpha_beta_distances
      }else{
        between_group_distances <- rbind(between_group_distances, alpha_beta_distances)
      }
      
      
    }   
    

    distances_list <- list("within"= within_group_distances, "between" = between_group_distances)
    
    return(distances_list)
    
  }


  





  
  

# Import groups from file

#groups_characterlist <<- readLines(groups_list)

  

  

# First, deal with the original file
  distances_list_real <<- process_dist(dist_matrix=original_matrix_file, groups=groups_list )
  
# now deal with the permutations


  perm_dists <- dir(perm_dists_path)
  num_perm <- length(perm_dists)
  
  
  within_group_distances_perm_sum <- matrix()
  between_group_distances_perm_sum <- matrix()
  
  for (j in 1:num_perm){
    
    perm_file <- paste( perm_dists_path,"/",perm_dists[j], sep="")

    if(debug==TRUE){print(paste( "perm_file: ", perm_file))}
    
    distances_list_perm <- process_dist(dist_matrix=perm_file, groups=groups_list)

    within_perm <- distances_list_perm$within
    between_perm <- distances_list_perm$between
    
    if(j == 1){
      #within_group_distances_perm_sum <- distances_list_perm$within
      #between_group_distances_perm_sum <- distances_list_perm$between

      within_group_distances_perm_sum <- within_perm
      between_group_distances_perm_sum <- between_perm

      
      if(debug==TRUE){print(paste("j: ",j,"     within_perm: ",within_perm[1,1]))}
      if(debug==TRUE){print(paste("j: ",j,"     within_sum   : ",within_group_distances_perm_sum[1,1]))}
    }else{
      #within_group_distances_perm_sum <- within_group_distances_perm_sum + distances_list_perm$within
      #between_group_distances_perm_sum <- between_group_distances_perm_sum + distances_list_perm$between
      within_group_distances_perm_sum <- within_group_distances_perm_sum + within_perm
      between_group_distances_perm_sum <- between_group_distances_perm_sum + between_perm
      if(debug==TRUE){print(paste("j: ",j,"     within_perm: ",within_perm[1,1]))}
      if(debug==TRUE){print(paste("j: ",j,"     within_sum   : ",within_group_distances_perm_sum[1,1]))}
    }
    
  }
  
  within_group_distances_perm_avg = ( within_group_distances_perm_sum / num_perm )
  between_group_distances_perm_avg = ( between_group_distances_perm_sum / num_perm )
  if(debug==TRUE){print(paste("j: ",j,"     within_1_1_avg: ",within_group_distances_perm_avg[1,1]))}
  
                                        # now plots
  
  within_group_real.hist <-  hist(distances_list_real$within, plot=FALSE, breaks=20)
  between_group_real.hist <-  hist(distances_list_real$between, plot=FALSE, breaks=20)
  
  within_group_perm.hist <-  hist(within_group_distances_perm_avg, plot=FALSE, breaks=20)
  between_group_perm.hist <-  hist(between_group_distances_perm_avg, plot=FALSE, breaks=20)
  
  x_max = max(within_group_real.hist$breaks, between_group_real.hist$breaks, within_group_perm.hist$breaks, between_group_perm.hist$breaks, na.rm=TRUE)
  y_max = max(within_group_real.hist$counts, between_group_real.hist$counts, within_group_perm.hist$counts, between_group_perm.hist$counts, na.rm=TRUE)
  
  
                                        #print(paste("my ylim =", my_ylim))

  legend_colors <- c("blue", "blue", "red", "red")
  legend_text <- c(paste("within_group.real  :: avg=", round(mean(within_group_real.hist$counts),digits=3),  ", sd=", round(sd(within_group_real.hist$counts),digits=3), sep=""),
                   paste("between_group.real :: avg=", round(mean(between_group_real.hist$counts),digits=3), ", sd=", round(sd(between_group_real.hist$counts),digits=3), sep=""),
                   paste("within_group.perm  :: avg=", round(mean(within_group_perm.hist$counts),digits=3),  ", sd=", round(sd(within_group_perm.hist$counts),digits=3), sep=""),
                   paste("between_group.perm :: avg=", round(mean(between_group_perm.hist$counts),digits=3), ", sd=", round(sd(between_group_perm.hist$counts),digits=3), sep="")
                         )

  
  plot(x = within_group_real.hist$breaks, y = c(within_group_real.hist$counts, 0), ylab="frequency", xlab="dist", type="l", lty=3, col=legend_colors[1], xlim=c(0,x_max), ylim=c(0,y_max), main="Distance comparison (real vs averaged perm)")
  lines(x = between_group_real.hist$breaks, y = c(between_group_real.hist$counts, 0), ylab="frequency", xlab="dist", type="l", col=legend_colors[2])
  lines(x = within_group_perm.hist$breaks, y = c(within_group_perm.hist$counts, 0), ylab="frequency", xlab="dist", type="l", lty=3, col=legend_colors[3])
  lines(x = between_group_perm.hist$breaks, y = c(between_group_perm.hist$counts, 0), ylab="frequency", xlab="dist", type="l", col=legend_colors[4])

  legend("topleft", legend = legend_text, pch=19, lty=c(3,1), col = legend_colors)
  
  
  
    
  if(write_tables == TRUE ){
    real_table = paste(original_matrix_file, ".real_counts", sep="")
    perm_table = paste(original_matrix_file, ".perm_counts_acg", sep="")
    write.table(rbind(distances_list_real$within, distances_list_real$between), file = real_table, col.names=NA, row.names = TRUE, sep="\t", quote=FALSE)
    #write.table(rbind(within_group_perm.hist$counts, between_group_perm.hist$counts), file = perm_table, col.names=NA, row.names = TRUE, sep="\t", quote=FALSE)
    if(debug==TRUE){print(paste("within:  ",within_group_real.hist$counts))}
    if(debug==TRUE){print(paste("class(within_group_real.hist$counts):  ",class(within_group_real.hist$counts)))}
    if(debug==TRUE){print(paste("between: ",between_group_real.hist$counts))}
    
    
  }
  
  #legend("topleft", legend = legend_text, pch=19, lty=c(3,1), col = c("blue", "blue", "red", "red"))
  
  








  
  
  
}



























## dist_hist <- function(distance_matrix_file, groups_list = "AMETHST_groups", debug = 0){

## # dist_hist <- function(distance_matrix_file, file_path = "./", groups_list = "groups", perm_dists_path = "./DISTs", debug = 0){ 

##   legend_text <- c("within_group","between_group")
##   legend_colors <- c("red", "green")

## # First, deal with the original file

##   distance_matrix <<- data.matrix(read.table(distance_matrix_file, row.names=1, header=TRUE, check.names=FALSE, sep="\t", comment.char="", quote=""))
  
##   groups_dataframe <<- read.table(groups_list, header=FALSE, check.names=FALSE, sep = ",", comment.char="", quote="", fill=TRUE, blank.lines.skip=TRUE)
##   #groups_characterlist <<- readLines(groups_list)

##   groups_in <<- readLines(groups_list)
##   num_groups <<- dim(data.frame(groups_in))[1]

##   within_group_distances <- matrix()
##   between_group_distances <- matrix()
  
##   for (i in 1:num_groups){
    
##     if ( debug>0 ) { print(paste("Group:", i)) }
    
##     group_samples <- strsplit(groups_in[i], ",")
##     num_samples <- dim(data.frame(group_samples))[1]
##     group_distances <<- matrix (NA, size(combn(num_samples,2))[2], 1) #####
##     gd_index <- 1 
    
##     for (m in 2:num_samples){ # get all of the unique non-redundant pairs
      
##       for (n in 1:(m-1)){
        
##         if (
##             identical( toString(charmatch( group_samples[[1]][m], dimnames(distance_matrix)[[1]])), "NA" ) ||
##             identical( toString(charmatch(   group_samples[[1]][n], dimnames(distance_matrix)[[1]])), "NA" )
##             )
##           {
            
##             stop (paste("sample names in the groups file:\n", groups_list,"\n (", noquote(group_samples[[1]][m]), " or ", noquote(group_samples[[1]][n]), ")\n are not in the distance_matrix:\n",distance_matrix_file, "\n",
##                         "check the names in the groups and distance_matrix files to make sure that they match\n\n"))    
##           }
        
##         if (debug>0){ print(paste("gd_index =", gd_index, "distance:", distance_matrix[ noquote(group_samples[[1]][m]), noquote(group_samples[[1]][n]) ] )) } #####
##         group_distances[gd_index,1] <<- distance_matrix[ noquote(group_samples[[1]][m]), noquote(group_samples[[1]][n]) ] #####
##         gd_index <- gd_index + 1
        
##       }
      
##     }
    
##     if ( i == 1 ){
##       within_group_distances <- group_distances
##     }else{
##       within_group_distances <- rbind(within_group_distances, group_distances)
##     }
    
##   }

  
##   #  
##   for (p in 2:num_groups){ # get all of the unique non-redundant pairs
    
##     for (q in 1:(p-1)){
      
##       alpha_samples <- strsplit(groups_in[p], ",")
##       num_alpha_samples <- dim(data.frame(alpha_samples))[1]
##                                         #alpha_distances <- matrix(NA, size(combn(num_alpha_samples,2))[2], 1) ### ###  
      
##       beta_samples <- strsplit(groups_in[q], ",")
##       num_beta_samples <- dim(data.frame(beta_samples))[1]
##                                         #beta_distances <- matrix(NA, size(combn(num_beta_samples,2))[2], 1) ### ###
      
##       alpha_beta_distances <<- matrix(NA, (num_alpha_samples*num_beta_samples), 1) # alpha and beta should be the same size
##       dist_index <- 1 ### ###
      
##       #write(gsub(" ", "", (paste(">>Group(", p, ")::Group(", q, ")"))), file=output_file, append=TRUE)
      
##       for (na in 1:num_alpha_samples){
##         for (nb in 1:num_beta_samples){
          
##           alpha_beta_distances[dist_index,1] <<- distance_matrix[ noquote(alpha_samples[[1]][na]), noquote(beta_samples[[1]][nb]) ] ### ###
##           dist_index <- dist_index + 1 ### ###
      
##         }
##       }
      
##     }

##     if( p == 1 ){
##       between_group_distances <- alpha_beta_distances
##     }else{
##       between_group_distances <- rbind(between_group_distances, alpha_beta_distances)
##     }
    
    
##   }   
  
  
## within_group.hist <-  hist(within_group_distances, plot=FALSE, breaks=20)
## between_group.hist <-  hist(between_group_distances, plot=FALSE, breaks=20)
  
## y_max = max(within_group.hist$counts, between_group.hist$counts, na.rm=TRUE)
## #print(paste("my ylim =", my_ylim))
  
## plot(x = within_group.hist$breaks, y = c(within_group.hist$counts, 0), ylab="frequency", xlab="breaks", type="l", col=legend_colors[1], ylim=c(0,y_max))
## lines(x = between_group.hist$breaks, y = c(between_group.hist$counts, 0), ylab="frequency", xlab="breaks", type="l", col=legend_colors[2])
## legend("topright", legend = legend_text, pch=19, col = legend_colors)
  
## }


















  
  








## dist_hist <- function(original_dist,
##                           #input_type = "file",
##                           #original_dist,
##                           perm_dists_path = "./DISTs",
##                           file_out_prefix = "my_dist_hist",
##                           create_figure=FALSE){

## # Print usage if
##    #if (nargs() == 0){print_usage()}
   
## # mport the original dist file
## original.dist <- data.matrix(read.table(original_dist, row.names=1, check.names=FALSE, header=TRUE, sep="\t", comment.char="", quote=""))

## original_hist <- hist(as.dist(original.dist), plot=FALSE, breaks=20)

## sum.dist <- matrix()

## perm_dists <- dir(perm_dists_path)

## for (i in 1:length(perm_dists)){

##   perm.dist <- data.matrix(read.table(  paste( perm_dists_path,"/",perm_dists[i], sep="") , row.names=1, check.names=FALSE, header=TRUE, sep="\t", comment.char="", quote=""))

##   # perm_hist <- hist(perm.dist, plot=FALSE, breaks=20)

##   if ( i==1 ){
##     sum.dist = perm.dist
##   }else{
##     sum.dist = sum.dist + perm.dist
##   }
 
## }

## avg.perm.dist = ( sum.dist / length(perm_dists) )

## #perm_hist <- hist(avg.perm.dist, plot=FALSE, breaks=20)
## perm_hist <- hist(as.dist(avg.perm.dist), plot=FALSE, breaks=20)

## print(attributes(as.dist(original.dist)))
## print(attributes(as.dist(avg.perm.dist)))

##   #num_breaks <- length(my_hist$breaks)
  
##   #print(paste(my_hist$counts, 0))
  


  

##   #print(my_hist$breaks)
##   #my_hist <- hist(temp.matrix)

## }
























## dist_hist <- function(original_dist,
##                           #input_type = "file",
##                           #original_dist,
##                           perm_dists_path = "./DISTs",
##                           file_out_prefix = "my_dist_hist",
##                           create_figure=FALSE){

## # Print usage if
##    #if (nargs() == 0){print_usage()}
   
## # mport the original dist file
## original.dist <- data.matrix(read.table(original_dist, row.names=1, check.names=FALSE, header=TRUE, sep="\t", comment.char="", quote=""))

## original_hist <- hist(as.dist(original.dist), plot=FALSE, breaks=20)

## sum.dist <- matrix()

## perm_dists <- dir(perm_dists_path)

## for (i in 1:length(perm_dists)){

##   perm.dist <- data.matrix(read.table(  paste( perm_dists_path,"/",perm_dists[i], sep="") , row.names=1, check.names=FALSE, header=TRUE, sep="\t", comment.char="", quote=""))

##   # perm_hist <- hist(perm.dist, plot=FALSE, breaks=20)

##   if ( i==1 ){
##     sum.dist = perm.dist
##   }else{
##     sum.dist = sum.dist + perm.dist
##   }
 
## }

## avg.perm.dist = ( sum.dist / length(perm_dists) )

## #perm_hist <- hist(avg.perm.dist, plot=FALSE, breaks=20)
## perm_hist <- hist(as.dist(avg.perm.dist), plot=FALSE, breaks=20)

## print(attributes(as.dist(original.dist)))
## print(attributes(as.dist(avg.perm.dist)))

##   #num_breaks <- length(my_hist$breaks)
  
##   #print(paste(my_hist$counts, 0))
  
## plot(x = original_hist$breaks, y = c(original_hist$counts, 0), ylab="frequency", xlab="breaks", type="l", col="blue")
## lines(x = perm_hist$breaks, y = c(perm_hist$counts, 0), ylab="frequency", xlab="breaks", type="l", col="red")


  

##   #print(my_hist$breaks)
##   #my_hist <- hist(temp.matrix)

## }
  
