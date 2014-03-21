avg_distances <- function(distance_matrix_file, file_path = "./", groups_list = "groups", output_file, output_dir = "./", debug = 0){ #10-20-11 - function to calculate average distances with specified groupings from a distance matrix

  if ( nargs() == 0){print_usage()} 

  suppressPackageStartupMessages(library(matlab))

  output_file = gsub(" ", "", paste(output_dir, output_file, ".AVG_DIST"))

  file_path = gsub(" ", "", paste(file_path, distance_matrix_file))
  distance_matrix <<- data.matrix(read.table(file_path, row.names=1, header=TRUE, check.names=FALSE, sep="\t", comment.char="", quote=""))

  #groups_dataframe <<- read.table(groups_list, header=FALSE, check.names=FALSE, sep = ",", comment.char="", quote="", fill=TRUE)
  groups_dataframe <<- read.table(groups_list, header=FALSE, check.names=FALSE, sep = ",", comment.char="", quote="", fill=TRUE, blank.lines.skip=TRUE)
  groups_characterlist <<- readLines(groups_list)

  groups_in <<- readLines(groups_list)
  num_groups <<- dim(data.frame(groups_in))[1]

  write(paste("######", distance_matrix_file, "avg_distances.r analysis ######"), file=output_file, append=TRUE)
  write("                                             ", file=output_file, append=TRUE)
  write("#############################################", file=output_file, append=TRUE)
  write("#>WITHIN GROUP Distances or Dissimilarities", file=output_file, append=TRUE)
  write("#############################################", file=output_file, append=TRUE)
  write("                                             ", file=output_file, append=TRUE)
  # This part extracts all of the within group distances
  for (i in 1:num_groups){
    
    if ( debug>0 ) { print(paste("Group:", i)) }
    #
    group_samples <- strsplit(groups_in[i], ",")
    num_samples <- dim(data.frame(group_samples))[1]
    write(gsub( " ", "", (paste(">Group(", i, ")", "\t", "group_members=", group_samples))), file=output_file, append=TRUE)
    group_distances <<- matrix (NA, size(combn(num_samples,2))[2], 1) #####
    gd_index <- 1 

      for (m in 2:num_samples){ # get all of the unique non-redundant pairs

        for (n in 1:(m-1)){

          if (
              identical( toString(charmatch( group_samples[[1]][m], dimnames(distance_matrix)[[1]])), "NA" ) ||
              identical( toString(charmatch(   group_samples[[1]][n], dimnames(distance_matrix)[[1]])), "NA" )
              )
            {
              #print()
              stop (paste("sample names in the groups file:\n", groups_list,"\n (", noquote(group_samples[[1]][m]), " or ", noquote(group_samples[[1]][n]), ")\n are not in the distance_matrix:\n",distance_matrix_file, "\n",
                    "check the names in the groups and distance_matrix files to make sure that they match\n\n"))    
            }

          if (debug>0){ print(paste("gd_index =", gd_index, "distance:", distance_matrix[ noquote(group_samples[[1]][m]), noquote(group_samples[[1]][n]) ] )) } #####
          group_distances[gd_index,1] <<- distance_matrix[ noquote(group_samples[[1]][m]), noquote(group_samples[[1]][n]) ] #####
          gd_index <- gd_index + 1
                    
          write(
                gsub(
                     " ", "", paste(
                                    noquote(group_samples[[1]][m]),
                                    "::",
                                    noquote(group_samples[[1]][n]),
                                    "\t",
                                    distance_matrix[ noquote(group_samples[[1]][m]), noquote(group_samples[[1]][n]) ]
                                    )
                     ),
                file = output_file,
                append=TRUE
                )
          ##
          
        }
        
      }
    
    write(gsub(" ", "", paste("->mean_Group(", i, ")", "\t", mean(group_distances), "\t", "stdev", "\t", sd(as.vector(group_distances)),"\t", "group_members=", group_samples)), file=output_file, append=TRUE)#####
    
    write("_____________________________________________", file=output_file, append=TRUE)
  }

  
  
  # This portion extracts the between group distances
  if (num_groups<2){
    write("                                             ", file=output_file, append=TRUE)
    write("#############################################", file=output_file, append=TRUE)
    write("#>>BETWEEN GROUP Distances or Dissimilarities", file=output_file, append=TRUE)
    write("        NA -- There is just one group        ", file=output_file, append=TRUE)
    write("#############################################", file=output_file, append=TRUE)
  }else{
    write("                                             ", file=output_file, append=TRUE)
    write("#############################################", file=output_file, append=TRUE)
    write("#>>BETWEEN GROUP Distances or Dissimilarities", file=output_file, append=TRUE)
    write("#############################################", file=output_file, append=TRUE)
    write("                                             ", file=output_file, append=TRUE)
    
    for (p in 2:num_groups){ # get all of the unique non-redundant pairs
    
      for (q in 1:(p-1)){
      
        alpha_samples <- strsplit(groups_in[p], ",")
        num_alpha_samples <- dim(data.frame(alpha_samples))[1]
        #alpha_distances <- matrix(NA, size(combn(num_alpha_samples,2))[2], 1) ### ###  
        
        beta_samples <- strsplit(groups_in[q], ",")
        num_beta_samples <- dim(data.frame(beta_samples))[1]
        #beta_distances <- matrix(NA, size(combn(num_beta_samples,2))[2], 1) ### ###

        alpha_beta_distances <<- matrix(NA, (num_alpha_samples*num_beta_samples), 1) # alpha and beta should be the same size
        dist_index <- 1 ### ###

        write(gsub(" ", "", (paste(">>Group(", p, ")::Group(", q, ")"))), file=output_file, append=TRUE)
      
        for (na in 1:num_alpha_samples){
          for (nb in 1:num_beta_samples){

            alpha_beta_distances[dist_index,1] <<- distance_matrix[ noquote(alpha_samples[[1]][na]), noquote(beta_samples[[1]][nb]) ] ### ###
            dist_index <- dist_index + 1 ### ###
            
            write(
                  gsub(
                       " ", "", paste(
                                      "Group(", p,")",
                                      noquote(alpha_samples[[1]][na]),
                                      "::Group(", q,")",
                                      noquote(beta_samples[[1]][nb]),
                                      "\t",
                                      distance_matrix[ noquote(alpha_samples[[1]][na]), noquote(beta_samples[[1]][nb]) ]
                                      )
                       ),
                  file = output_file,
                  append=TRUE
                  )
          }
        }
        write(gsub(" ", "", paste("->>mean_Group(", p, ")::Group(", q, ")", "\t", mean(alpha_beta_distances), "\t", "stdev", "\t", sd(as.vector(alpha_beta_distances)) )), file=output_file, append=TRUE)
        write("_____________________________________________", file=output_file, append=TRUE)
      }
      #write(gsub(" ", "", paste("->>mean_Group(", p, ")::Group(", q, ")", "\t", mean(alpha_beta_distances), "\t", "stdev", "\t", sd(alpha_beta_distances))), file=output_file, append=TRUE)
      #write("_____________________________________________", file=output_file, append=TRUE)
    }   
  }

}


# write(gsub(" ", "", paste("mean Group(", i, ")", "\t", mean(group_distances), "\t", "stdev", "\t", sd(group_distances))), file=output_file, append=TRUE)


## if ( debug>0 ) { print(
##                                  paste(
##                                        noquote(group_samples[[1]][m]), "vs.", noquote(group_samples[[1]][n]), "dist =",
##                                        distance_matrix[ noquote(group_samples[[1]][m]), noquote(group_samples[[1]][n]) ]
##                                        )
##                                  )
##                          }




#### SUBS  
print_usage <- function() {
  writeLines("  ------------------------------------------------------------------------------
  avg_distances.r
  ------------------------------------------------------------------------------
  DESCRIPTION:
  This script will calculate the average within and between group distances given an
  input distance matrix and groupings file

  USAGE:
  sample_matrix(distance_matrix_file, file_path, groups_list, output_file)

       distance_matrix_file : string, no default         : name of the distance matrix file (a *.DIST output of plot_pco_with_stats.pl)
       file_path            : string, default = ./       : path of the distance_matrix_file
       groups_list          : string, default = groups   : name of the groups list - the groups list needs to follow these conventions:
                                - each line is a group
                                - individual sample names are comma separated on each line
                                - sample names must match the sample names in the distance_matrix_file
       
       output_file          : string, no default         : name for the output file
       output_dir           : string, default = ./       : path for the output
       debug                : boolean, default = 0       : (0|1) run the script in debug mode 
  ------------------------------------------------------------------------------
Arguents you supplied:")
  print(paste("distance_matrix_file: ", distance_matrix_file))
  print(paste("file_path:            ", file_path))
  print(paste("groups_list:          ", groups_list))
  print(paste("output_file:          ", output_file))
  print("------------------------------------------------------------------------------")
  stop("you did not enter the correct args -- see above")
}





