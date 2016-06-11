Bootstrap_Sim_Fn = function( inputlist ){
  # inputs
  if(!exists("verbose")) verbose <- FALSE
  attach( inputlist, warn.conflicts=verbose )
  on.exit( detach(inputlist) )

  # Move files to new directory
  file.copy( from=paste0(SpeciesOM,list.files(SpeciesOM)), to=paste0(RepFile,list.files(SpeciesOM)), overwrite=TRUE)

  # Modify par file
  Par = scan_admb_par( paste0(RepFile,"ss3.par"))
  # Generate and write rec-devs to par file
  if( "SigmaR" %in% names(inputlist)){
    Which = union( grep("recdev",names(Par)), grep("recruitment",names(Par)))
    Par[Which] = rnorm( length(Which), mean=-SigmaR^2/2, sd=SigmaR)
  }
  # Generate and write new F trajectory
  if( "Framp" %in% names(inputlist)){
    Which = grep("F_rate",names(Par))
    Par[Which] = seq( from=Framp['min'], to=Framp['max'], length=length(Which))
  }
  # Write par file
  write.table( Par, file=paste0(RepFile,"ss3.par"), row.names=FALSE, col.names=FALSE)

  # Change starter file
  Starter = SS_readstarter( file=paste0(RepFile,"starter.ss"), verbose=verbose)
  Starter[['init_values_src']] = 1
  Starter[['N_bootstraps']] = 3
  SS_writestarter( mylist=Starter, dir=RepFile, overwrite=TRUE, verbose=verbose, warn=verbose)

  # Run first time
  setwd( RepFile )
  shellout = shell( "ss3.exe -maxfn 0 -nohess", intern=!verbose)
  if(verbose==TRUE) print(shellout); flush.console()

  # Write bootstrap simulation to data file
  Lines = readLines( paste0(RepFile,"data.ss_new") )
  Lines = Lines[(grep("#_bootstrap file: 1",Lines)+1):grep("ENDDATA",Lines)]
  writeLines(text=Lines, con=paste0(RepFile,Starter[['datfile']]))

  # Return stuff
  Return = list( "Success"=1, "TruePar"=Par )
  invisible(Return)
}
