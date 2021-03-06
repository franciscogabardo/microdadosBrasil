


#' @export
download_sourceData <- function(dataset, i, unzip=T, ft=NULL, dest = NULL, replace = FALSE){
  dataset_list<- system.file("extdata", package = "microdadosBrasil") %>%
    list.files(pattern = "files") %>%
    gsub(pattern = "_.+", replacement = "")




  #Test if parameters are valid

  if( !(dataset %in% dataset_list ) ) {
    stop(paste0("Invalid dataset. Must be one of the following: ",paste(dataset_list, collapse=", ")) ) }

  metadata <-  read_metadata(dataset)
  ft_list  <- names(metadata)[grep("ft_", names(metadata))]
  data_file_names<- metadata %>% filter(period == i ) %>% select_(.dots =c(ft_list)) %>% unlist(use.names = FALSE) %>% gsub(pattern = ".+?&", replacement = "")

  if (!replace) {
    if(any(grepl(pattern = paste0(data_file_names,collapse = "|"), x = list.files(recursive = TRUE, path = ifelse(is.null(dest), ".", dest))))) {
      stop(paste0("This data was already downloaded.(check:\n",
                  paste(list.files(pattern = paste0(data_file_names,collapse = "|"),
                             recursive = TRUE,path = ifelse(is.null(dest), ".", dest), full.names = TRUE), collapse = "\n"),
                  ")\n\nIf you want to overwrite the previous files add replace=T to the function call."))

    }
  }


  i_min    <- min(metadata$period)
  i_max    <- max(metadata$period)

  if (!(i %in% metadata$period)) { stop(paste0("period must be between ", i_min," and ", i_max )) }


  md <- metadata %>% filter(period==i)

  link <- md$download_path
  data_file_names<- md
  if(is.na(link)){stop("Can't download dataset, there are no information about the source")}



  if(!is.null(dest)){
    if(!file.exists(dest)){
      stop(paste0("Can't find ",dest))
    }}

  if(md$download_mode == "ftp"){

    filenames <- RCurl::getURL(link, ftp.use.epsv = FALSE, ftplistonly = TRUE,
                        crlf = TRUE)
    file_dir<- gsub(link, pattern = "/+$", replacement = "", perl = TRUE) %>% gsub(pattern = ".+/", replacement = "")
    dir.create(paste(c(dest,file_dir), collapse = "/"))
    filenames<- strsplit(filenames, "\r*\n")[[1]]
    file_links <- paste(link, filenames, sep = "")

    download_sucess <- rep(FALSE, length(filenames))

    max_loops  = 20
    loop_counter = 1

    while(!all(download_sucess) & loop_counter< max_loops){


    for(y in seq_along(filenames)[!download_sucess]){

      print(paste(c(dest,file_dir,filenames[y]),collapse = "/"))
      print(file_links[y])
      download_sucess[y] = FALSE
      try({
          download.file(file_links[y],destfile = paste(c(dest,file_dir, filenames[y]),collapse = "/"))
          download_sucess[y] = TRUE


        })
    }

      loop_counter = loop_counter + 1
    }

    if(!all(download_sucess)){ message(paste0("The download of the following files failed:\n"),
                                       paste(filenames[!download_sucess], collapse = "\n"))}

  }else{

    filename <- link %>% gsub(pattern = ".+/", replacement = "")
    file_dir <- filename %>% gsub( pattern = "\\.zip", replacement = "")

    print(link)
    print(filename)
    print(file_dir)

    try(download.file(link,destfile = paste(c(dest,filename),collapse = "/")))

    if (unzip==T){
      #Unzipping main source file:
      unzip(paste(c(dest,filename),collapse = "/") ,exdir = paste(c(dest,file_dir),collapse = "/"))
    }
  }
    if (unzip==T){
    # #unzipping the data files (in case not unziped above)
    intern_files<- list.files(paste(c(dest,file_dir),collapse = "/"), recursive = TRUE,all.files = TRUE, full.names = TRUE)
    zip_files<- intern_files[grepl(pattern = "\\.zip$",x = intern_files)]
    rar_files<- intern_files[grepl(pattern = "\\.rar$",x = intern_files)]
    r7z_files<- intern_files[grepl(pattern = "\\.7z$",x = intern_files)]
    if(length(r7z_files)>0){warning(paste0("There are files in .7z format inside the main folder, please unzip manually: ",paste(r7z_files,collapse = ", ")))}
    if(length(rar_files)>0){warning(paste0("There are files in .rar format inside the main folder, please unzip manually: ",paste(r7z_files,collapse = ", ")))}
    for(zip_file in zip_files){
      exdir<- zip_file %>% gsub(pattern = "\\.zip", replacement = "")
      unzip(zipfile = zip_file,exdir = exdir )
    }

}
    # check data_path for compressed files: .zip, .7z , .rar
    # Unzip the .zip ones
    # Issue warning for unzipping manually the .7z and .rar files
    #
    # }
  }




