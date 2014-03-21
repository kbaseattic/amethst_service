plot_dists<- function(
                     file_in,
                     num_breaks = 10,
                     debug = TRUE
                     ){

  # you need to run AVG_DIST.2.r.pl on data before this
  
  distance_matrix <- data.matrix(read.table(file_in, row.names=1, header=FALSE, check.names=FALSE, sep="\t", comment.char="", quote=""))
  
  num_dists <- dim(distance_matrix)[1]

  E1_count <<- 1
  C_count <<- 1
  Ch_count <<- 1
  Ch1_count <<- 1
  Ch2_count <<- 1
  Ch3_count <<- 1
  Ch4_count <<- 1
  Ch5_count <<- 1
  R_count <<- 1
  W_count <<- 1
  groups_count <<- 1

  desired_groups_count <<- 1

  E1_matrix <<- matrix(NA, 10, 1)
  dimnames(E1_matrix)[[2]] <<- as.list("E1")
  dimnames(E1_matrix)[[1]] <<- as.list(rep("na",dim(E1_matrix)[1]))    
  
  C_matrix <<- matrix(NA, 10, 1)
  dimnames(C_matrix)[[2]] <<- as.list("C")
  dimnames(C_matrix)[[1]] <<- as.list(rep("na",dim(C_matrix)[1]))
  
  Ch_matrix <<- matrix(NA, 300, 1)
  dimnames(Ch_matrix)[[2]] <<- as.list("Ch")
  dimnames(Ch_matrix)[[1]] <<- as.list(rep("na",dim(Ch_matrix)[1]))

  Ch1_matrix <<- matrix(NA, 10, 1)
  dimnames(Ch1_matrix)[[2]] <<- as.list("C")
  dimnames(Ch1_matrix)[[1]] <<- as.list(rep("na",dim(Ch1_matrix)[1]))

  Ch2_matrix <<- matrix(NA, 10, 1)
  dimnames(Ch2_matrix)[[2]] <<- as.list("C")
  dimnames(Ch2_matrix)[[1]] <<- as.list(rep("na",dim(Ch2_matrix)[1]))

  Ch3_matrix <<- matrix(NA, 10, 1)
  dimnames(Ch3_matrix)[[2]] <<- as.list("C")
  dimnames(Ch3_matrix)[[1]] <<- as.list(rep("na",dim(Ch3_matrix)[1]))

  Ch4_matrix <<- matrix(NA, 10, 1)
  dimnames(Ch4_matrix)[[2]] <<- as.list("C")
  dimnames(Ch4_matrix)[[1]] <<- as.list(rep("na",dim(Ch4_matrix)[1]))

  Ch5_matrix <<- matrix(NA, 10, 1)
  dimnames(Ch5_matrix)[[2]] <<- as.list("C")
  dimnames(Ch5_matrix)[[1]] <<- as.list(rep("na",dim(Ch5_matrix)[1]))

  R_matrix <<- matrix(NA, 10, 1)
  dimnames(R_matrix)[[2]] <<- as.list("R")
  dimnames(R_matrix)[[1]] <<- as.list(rep("na",dim(R_matrix)[1]))
  
  W_matrix <<- matrix(NA, 10, 1)
  dimnames(W_matrix)[[2]] <<- as.list("W")
  dimnames(W_matrix)[[1]] <<- as.list(rep("na",dim(W_matrix)[1]))
  
  groups_matrix <<- matrix(NA, 2025, 1)
  dimnames(groups_matrix)[[2]] <<- as.list("Group")
  dimnames(groups_matrix)[[1]] <<- as.list(rep("na",dim(groups_matrix)[1]))

  desired_groups_matrix <<- matrix(NA, 650, 1)
  dimnames(desired_groups_matrix)[[2]] <<- as.list("Desired Group")
  dimnames(desired_groups_matrix)[[1]] <<- as.list(rep("na",dim(desired_groups_matrix)[1]))
  
  for (i in 1:num_dists){
    
    my_dist <- distance_matrix[i,1]
    my_dist.name <- as.character(dimnames(distance_matrix)[[1]][i])
    
    #if( debug==TRUE ){ print(paste("dist: ", my_dist.name, " = ", my_dist, sep="")) }
    
    if ( grepl("^Group", my_dist.name)==TRUE ){

      groups_matrix[groups_count,1] <<- my_dist
      dimnames(groups_matrix)[[1]][groups_count] <<- my_dist.name
      groups_count <<- groups_count + 1

    }else if ( grepl("^E", my_dist.name)==TRUE ){

      #if( debug==TRUE ){ print("GOT HERE") }
      
      
      E1_matrix[E1_count,1] <<- my_dist
      dimnames(E1_matrix)[[1]][E1_count] <<- my_dist.name
      E1_count <<- E1_count + 1 
      #if( debug==TRUE ){ print(E1_matrix) }

      
    }else if ( grepl("^Ch" ,my_dist.name)==TRUE ){

      # all Ch in s single gorup
      Ch_matrix[Ch_count,1] <<- my_dist
      dimnames(Ch_matrix)[[1]][Ch_count] <<- my_dist.name
      Ch_count <<- Ch_count + 1

      # each Ch in a separate group
      if ( grepl("^Ch1" ,my_dist.name)==TRUE ){
        if( grepl("Ch2|Ch3|Ch4|Ch5", my_dist.name)==FALSE ){
          Ch1_matrix[Ch1_count,1] <<- my_dist
          dimnames(Ch1_matrix)[[1]][Ch1_count] <<- my_dist.name
          Ch1_count <<- Ch1_count + 1
        }
      }

      if ( grepl("^Ch2" ,my_dist.name)==TRUE ){
        if( grepl("Ch1|Ch3|Ch4|Ch5", my_dist.name)==FALSE ){        
          Ch2_matrix[Ch2_count,1] <<- my_dist
          dimnames(Ch2_matrix)[[1]][Ch2_count] <<- my_dist.name
          Ch2_count <<- Ch2_count + 1
        }
      }

      if ( grepl("^Ch3" ,my_dist.name)==TRUE ){
        if( grepl("Ch1|Ch2|Ch4|Ch5", my_dist.name)==FALSE ){
          Ch3_matrix[Ch3_count,1] <<- my_dist
          dimnames(Ch3_matrix)[[1]][Ch3_count] <<- my_dist.name
          Ch3_count <<- Ch3_count + 1
        }
      }

      if ( grepl("^Ch4" ,my_dist.name)==TRUE ){
        if( grepl("Ch1|Ch2|Ch3|Ch5", my_dist.name)==FALSE ){
          Ch4_matrix[Ch4_count,1] <<- my_dist
          dimnames(Ch4_matrix)[[1]][Ch4_count] <<- my_dist.name
          Ch4_count <<- Ch4_count + 1
        }
      }

      if ( grepl("^Ch5" ,my_dist.name)==TRUE ){
        if( grepl("Ch1|Ch2|Ch3|Ch4", my_dist.name)==FALSE ){
          Ch5_matrix[Ch5_count,1] <<- my_dist
          dimnames(Ch5_matrix)[[1]][Ch5_count] <<- my_dist.name
          Ch5_count <<- Ch5_count + 1
        }
      }

    }else if ( grepl("^R" ,my_dist.name)==TRUE ){

      R_matrix[R_count,1] <<- my_dist
      dimnames(R_matrix)[[1]][R_count] <<-  my_dist.name
      R_count <<- R_count + 1

    }else if ( grepl("^W" ,my_dist.name)==TRUE ){

      #if( debug==TRUE ){ print(paste("dist: ", my_dist.name, " = ", my_dist, sep="")) }
      #if( debug==TRUE ){ print(W_matrix) }
      W_matrix[W_count,1] <<- my_dist
      dimnames(W_matrix)[[1]][W_count] <<- my_dist.name
      W_count <<- W_count + 1

    }else{

      C_matrix[C_count,1] <<- my_dist
      dimnames(C_matrix)[[1]][C_count] <<- my_dist.name
      C_count <<- C_count + 1
      # ( grepl("^C") )
    }

  }


  for (j in 1:dim(groups_matrix)[1]){

    group.name <- as.character(dimnames(groups_matrix)[[1]][j])
    group.value <- groups_matrix[j,1]
    
    # This is great -- you have to escape the escape for it to work ^_^
    if ( ! grepl("Group\\(1\\)|Group\\(2\\)|Group\\(3\\)|Group\\(4\\)|Group\\(5\\)", group.name) ){

      desired_groups_matrix[desired_groups_count,1] <<- group.value
      dimnames(desired_groups_matrix)[[1]][desired_groups_count] <<- group.name  
      desired_groups_count <<- desired_groups_count + 1
      
    }
    
        
  }


  
  # First round of hists to get some values
  E1.hist <- hist(E1_matrix, plot=FALSE, breaks = num_breaks)
  C.hist <<- hist(C_matrix, plot=FALSE, breaks = num_breaks)
  Ch.hist <<- hist(Ch_matrix, plot=FALSE, breaks = num_breaks)
  R.hist <<- hist(R_matrix, plot=FALSE, breaks = num_breaks)
  W.hist <<- hist(W_matrix, plot=FALSE, breaks = num_breaks)
  Ch1.hist <<- hist(Ch1_matrix, plot=FALSE, breaks = num_breaks)
  Ch2.hist <<- hist(Ch2_matrix, plot=FALSE, breaks = num_breaks)
  Ch3.hist <<- hist(Ch3_matrix, plot=FALSE, breaks = num_breaks)
  Ch4.hist <<- hist(Ch4_matrix, plot=FALSE, breaks = num_breaks)
  Ch5.hist <<- hist(Ch5_matrix, plot=FALSE, breaks = num_breaks)

  groups.hist <<- hist(desired_groups_matrix, plot=FALSE, breaks=20)

  x_max = max(E1.hist$breaks, C.hist$breaks, Ch.hist$breaks, R.hist$breaks, W.hist$breaks, groups.hist$breaks, na.rm=TRUE)
  y_max = max(E1.hist$counts, C.hist$counts , Ch.hist$counts , R.hist$counts , W.hist$counts , groups.hist$counts, na.rm=TRUE)

  # hists second time round, using the same breaks for all -- from hist with max breaks value (x_max) from the first round
  E1.hist <- hist(E1_matrix, plot=FALSE, breaks = num_breaks)
  C.hist <<- hist(C_matrix, plot=FALSE, breaks = num_breaks)
  Ch.hist <<- hist(Ch_matrix, plot=FALSE, breaks = num_breaks)
  R.hist <<- hist(R_matrix, plot=FALSE, breaks = num_breaks)
  W.hist <<- hist(W_matrix, plot=FALSE, breaks = num_breaks)
  Ch1.hist <<- hist(Ch1_matrix, plot=FALSE, breaks = num_breaks)
  Ch2.hist <<- hist(Ch2_matrix, plot=FALSE, breaks = num_breaks)
  Ch3.hist <<- hist(Ch3_matrix, plot=FALSE, breaks = num_breaks)
  Ch4.hist <<- hist(Ch4_matrix, plot=FALSE, breaks = num_breaks)
  Ch5.hist <<- hist(Ch5_matrix, plot=FALSE, breaks = num_breaks)

  
  legend_colors <- c("blue", "green", "purple", "orange", "brown", "black", "purple", "purple", "purple", "purple", "purple")
  
  legend_text <- c(
                   paste("E1 avg=", round(mean(E1.hist$counts),digits=3), ", sd=", round(sd(E1.hist$counts),digits=3), sep=""),
                   paste("C1 avg=", round(mean(C.hist$counts),digits=3), ", sd=", round(sd(C.hist$counts),digits=3), sep=""),
                   paste("Ch(all) avg=", round(mean(Ch.hist$counts),digits=3), ", sd=", round(sd(Ch.hist$counts),digits=3), sep=""),
                   paste("R avg=", round(mean(R.hist$counts),digits=3), ", sd=", round(sd(R.hist$counts),digits=3), sep=""),
                   paste("W avg=", round(mean(W.hist$counts),digits=3), ", sd=", round(sd(W.hist$counts),digits=3), sep=""),
                   paste("Between avg=", round(mean(groups.hist$counts),digits=3), ", sd=", round(sd(groups.hist$counts),digits=3), sep=""),
                   paste("Ch(1) avg=", round(mean(Ch1.hist$counts),digits=3), ", sd=", round(sd(Ch1.hist$counts),digits=3), sep=""),
                   paste("Ch(2) avg=", round(mean(Ch2.hist$counts),digits=3), ", sd=", round(sd(Ch2.hist$counts),digits=3), sep=""),
                   paste("Ch(3) avg=", round(mean(Ch3.hist$counts),digits=3), ", sd=", round(sd(Ch3.hist$counts),digits=3), sep=""),
                   paste("Ch(4) avg=", round(mean(Ch4.hist$counts),digits=3), ", sd=", round(sd(Ch4.hist$counts),digits=3), sep=""),
                   paste("Ch(5) avg=", round(mean(Ch5.hist$counts),digits=3), ", sd=", round(sd(Ch5.hist$counts),digits=3), sep="")
                   )
  
  pdf(width=12, height=6, file = paste(file_in, ".dists.hist.pdf", sep=""))
  
  plot(
       x = E1.hist$breaks,
       y = c(E1.hist$counts, 0),
       #x,
       #y,
       ylab="abundance",
       xlab="dist",
       type="l",
       #log = "y",
       lty=3,
       col=legend_colors[1],
       xlim=c(0,x_max),
       ylim=c(0,y_max),
       main= paste("Distance comparison (within vs between groups)\n", file_in, sep="")
       )
  lines(x = E1.hist$breaks, y = c(E1.hist$counts, 0), type="l", col=legend_colors[1])
  lines(x = C.hist$breaks, y = c(C.hist$counts, 0), type="l", col=legend_colors[2])
  lines(x = Ch.hist$breaks, y = c(Ch.hist$counts, 0), type="l", col=legend_colors[3])
  lines(x = R.hist$breaks, y = c(R.hist$counts, 0), type="l", col=legend_colors[4])
  lines(x = W.hist$breaks, y = c(W.hist$counts, 0), type="l", col=legend_colors[5])
  lines(x = groups.hist$breaks, y = c(groups.hist$counts, 0), type="l", col=legend_colors[6])
  lines(x = Ch1.hist$breaks, y = c(Ch1.hist$counts, 0), type="l", lty=3, col=legend_colors[7])
  lines(x = Ch2.hist$breaks, y = c(Ch2.hist$counts, 0), type="l", lty=3, col=legend_colors[8])
  lines(x = Ch3.hist$breaks, y = c(Ch3.hist$counts, 0), type="l", lty=3, col=legend_colors[9])
  lines(x = Ch4.hist$breaks, y = c(Ch4.hist$counts, 0), type="l", lty=3, col=legend_colors[10])
  lines(x = Ch5.hist$breaks, y = c(Ch5.hist$counts, 0), type="l", lty=3, col=legend_colors[11])
  
  legend("topleft", legend = legend_text, pch=19, lty=c(3,1), col = legend_colors)
  
  dev.off()
  
}








  
  # grepl("Group\\(1\\)|Group\\(2\\)|Group\\(3\\)|Group\\(9\\)|Group\\(5\\)","Group(9)Re::Group(8)Cd")
  # create groups matrix that only has the ones you are interested in



  
  #if(debug=TRUE){"HELLO.1"}
  # hash the groups so you are left with only the unique ones
  ## library(hash)
  ## my_hash <<- hash()

  ## if(debug=TRUE){"HELLO.2"}
  
  ## for (j in 1:dim(groups_matrix)[1]){
  ##   groups_key <<- as.character(dimnames(groups_matrix)[[1]][j])
  ##   groups_value <<- groups_matrix[j,1]
  ##   my_hash[ groups_key ] <<- groups_value
  ## }

  ## if(debug=TRUE){"HELLO.3"}
  
  ## nr_groups_matrix <<- matrix(NA, length(keys(my_hash)),1)
  ## dimnames(nr_groups_matrix)[[2]] <<- as.list("NR Group")
  ## dimnames(nr_groups_matrix)[[1]] <<- as.list(rep("na",dim(nr_groups_matrix)[1]))
  
  ## if(debug=TRUE){"HELLO.4"}
  
  ## for (k in 1:length(keys(my_hash))){
  ##   dimnames(nr_groups_matrix)[[1]][k] <<- keys(my_hash)[k]
  ##   nr_groups_matrix[k,] <<- my_hash[[ keys(my_hash)[k] ]]
  ## }
  
  





#grepl
