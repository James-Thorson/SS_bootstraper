###############################################################################
# Set variable inputs
###############################################################################

# Configuration settings
verbose = FALSE
Species = "arrowtooth"

# Simulation settings
inputlist = list( "SigmaR"=0.6 )
n_replicates = 5

###############################################################################
# Set working directory and folder structure
###############################################################################
if( Sys.info()["user"] == "James.Thorson" ){
  RootFile = "C:/Users/James.Thorson/Desktop/Project_git/SS_bootstraper/"
}
setwd(RootFile)
SpeciesOM = paste0(RootFile,Species,"_OM/")
SpeciesEM = paste0(RootFile,Species,"_EM/")

# Directory for results
DateFile = paste0(RootFile, Sys.Date(),"_sigmaR=0.6/")

###############################################################################
# load packages
###############################################################################
#' Load packages and R functions
#devtools::install_github("james-thorson/utilities")
library(ThorsonUtilities)
library(r4ss)
temp <- mapply(source, list.files(paste0(RootFile,"R/"), full.names=TRUE))

###############################################################################
# Run simulation
###############################################################################
set.seed(101)

# Generate dat files
for( RepI in 1:n_replicates ){
  RepFile = paste0(DateFile,"/Rep=",RepI,"/")
  dir.create(RepFile, recursive=TRUE)
  message("Starting replicate ",RepI," at ",Sys.time())

  if( !file.exists(paste0(DateFile,"/Results_",RepI,".RData")) ){
    # Generate bootstrap replicate
    Bootstrap_Sim_Fn( inputlist )

    # Move EM files to directory
    file.copy( from=paste0(SpeciesEM,list.files(SpeciesEM)), to=paste0(RepFile,list.files(SpeciesEM)), overwrite=TRUE)

    # Run MLE
    setwd( RepFile )
    shell( "ss3.exe", intern=!verbose)
    if( file.exists(paste0(RepFile,"ss3.std")) ){
      # Read MLE
      MLE = scan_admb_par( paste0(RepFile,"ss3.par"))

      # Run MCMC
      shellout = shell( "ss3 -mcscale 50000 -mcmc 100000 -mcsave 100", intern=!verbose )       # 50000/100000 -> 30 minutes on work machine
      shellout = shell( "ss3 -mceval", intern=!verbose )       # 50000/100000 -> 30 minutes on work machine
      # Read MCMC myself
      Posterior = read.table( paste0(RepFile,"posteriors.sso"), header=TRUE)
      Posterior = Posterior[ceiling(nrow(Posterior)/2):nrow(Posterior),]

      # Get estimates
      Results = list( "MLE"=MLE, "Posterior"=Posterior, "Result"=list("MLE"=MLE['# SR_parm[1]:'], "Mean"=mean(Posterior[,'SR_LN.R0.'])))
      save(Results, file=paste0(DateFile,"/Results_",RepI,".RData"))
    }else{
      Results = list( "Result"=list("MLE"=NA, "Mean"=NA) )
      save(Results, file=paste0(DateFile,"/Results_",RepI,".RData"))
    }
  }
} #end replicate loop

###############################################################################
# Compile results
###############################################################################

library(ThorsonUtilities)
ResultDF = array(NA, dim=c(4,100,2), dimnames=list(NULL,NULL,c('MLE','Bayesian')) )

# Truth
TrueVal = scan_admb_par( paste0(SpeciesOM,"ss3.par") )
TrueVal = TrueVal['# SR_parm[1]:']

# Loop through results
for( sI in 1:dim(ResultDF)[[1]] ){
  if(sI==1) DateFile = "C:/Users/James.Thorson/Desktop/Project_git/SS_bootstraper/2016-06-10/"
  if(sI==2) DateFile = "C:/Users/James.Thorson/Desktop/Project_git/SS_bootstraper/2016-06-11_sigmaR=0.2/"
  if(sI==3) DateFile = "C:/Users/James.Thorson/Desktop/Project_git/SS_bootstraper/2016-06-11_sigmaR=0.4/"
  if(sI==4) DateFile = "C:/Users/James.Thorson/Desktop/Project_git/SS_bootstraper/2016-06-11_sigmaR=0.6/"
  ResultsSet = list.files(DateFile)[grep("RData",list.files(DateFile))]
  for( rI in 1:dim(ResultDF)[[2]] ){
    if( file.exists(paste0(DateFile,ResultsSet[rI])) ){
      load( paste0(DateFile,ResultsSet[rI]) )
      if(length(Results)>1) ResultDF[sI,rI,] = unlist(Results$Result)
      if(length(Results)==1) ResultDF[sI,rI,] = unlist(Results[[1]])
    }
  }
}

# Histogram
save_fig( paste0(DateFile,"../Simulation"), width=4, height=6)
  par( mfrow=c(2,1), mar=c(1.5,1.5,1,0.5), mgp=c(1.75,0.25,0), oma=c(1,1,0,0), yaxs="i")
  Hist_Fn( ResultDF[1,,1], xlab="", ylab="", main="Maximum likelihood" )
  abline( v=TrueVal, lwd=3, lty="dotted" )
  Hist_Fn( ResultDF[1,,2], xlab="", ylab="", main="Mean Bayesian posterior" )
  abline( v=TrueVal, lwd=3, lty="dotted" )
  mtext( side=1:2, text=c("ln(R0)","Frequency"), line=c(0,0), outer=TRUE)
dev.off()

# Histogram
save_fig( paste0(DateFile,"../Simulation_panel"), width=6, height=6)
  par( mfrow=c(2,2), mar=c(1.5,1.5,1,0.5), mgp=c(1.75,0.25,0), oma=c(1,1,0,0), yaxs="i")
  for(sI in 1:dim(ResultDF)[[1]]){
    Hist = Hist_Fn( list(ResultDF[sI,,1],ResultDF[sI,,2]), xlab="", ylab="", ylim=c(0,dim(ResultDF)[[2]]*1.05), main=paste0("SigmaR=",c(0.01,0.2,0.4,0.6)[sI]), col=c(rgb(0,0,0,0.2),rgb(1,0,0,0.2)), breaks=seq(10,ceiling(max(ResultDF,na.rm=TRUE)),by=1.0) )
    abline( v=TrueVal, lwd=3, lty="dotted" )
  }
  mtext( side=1:2, text=c("Estimate of average log-recruitment without fishing","Frequency"), line=c(0,0), outer=TRUE)
dev.off()


