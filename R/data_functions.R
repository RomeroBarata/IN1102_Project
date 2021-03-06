# Function to read the desired data sets into the workspace.
readDataSets <- function(data_path, files_names){
    lapply(files_names, function(file_name, data_path){
        read.table(file.path(data_path, file_name), header = FALSE)
    }, data_path = data_path)
}

# This function generates the dissimilarity matrices. If any matrix
# was not generated, it will generate all of them and save into a
# file.'data_files' and 'diss_data_files' must have the same length.
genDissMtcs <- function(data_path, data_files, diss_data_files) {
    input_files <- data_files

    output_files <- diss_data_files

    # Gets only those whose dissimilarity matrix does not exist
    if(sum(!sapply(output_files, file.exists))) {
        # Read the data sets
        data_sets_list <- readDataSets(data_path, input_files)

        # Compute the dissimilarity matrix for each data set
        diss_matrix_list <- lapply(data_sets_list, function(data_set){
            as.matrix(cluster::daisy(data_set, metric = "euclidean"))
        })

        apply(rbind(output_files, diss_matrix_list), 2,
              function(tuple, data_path){
                  filename <- file.path(data_path, tuple[1])
                  if(!file.exists(filename)) {
                      print(filename)
                      write.table(tuple[2], file = filename,
                                  quote = FALSE, row.names = FALSE,
                                  col.names = FALSE)
                  }
              }, data_path = data_path)
    }
    return("Done")
}

# Function to add a class column to the data sets.
addClasses <- function(data_sets_list){
    lapply(data_sets_list, transform, Class = factor(rep(0:9, each = 200)))
}

# Function to remove repeated and inconsistent examples.
cleanDataSets <- function(data_sets_list){
    lapply(data_sets_list, function(data) removeInconsistencies(unique(data)))
}

# Function to remove inconsistent examples.
removeInconsistencies <- function(data){
    idx <- rep(FALSE, nrow(data))
    data_atts <- data[, -ncol(data)]
    hashs <- as.character(apply(data_atts, 1, digest::digest))
    duplicated_hashs <- hashs[duplicated(hashs)]
    for (dhash in duplicated_hashs){
        idx <- idx | (dhash == hashs) 
    }
    data[!idx, ]
}

# Function to pre-process a data set.
# Currently the user can only choose to center and scale.
preProcessTraining <- function(training, pre_process = NULL){
    if (is.null(pre_process)) return(list(training = training))
    
    training_class <- training[, ncol(training), drop = FALSE]
    training <- training[, -ncol(training), drop = FALSE]
    
    center <- scale_factor <- NULL
    if ("center" %in% pre_process){
        training <- scale(training, center = TRUE, scale = FALSE)
        center <- attributes(training)$`scaled:center`
        attributes(training)$`scaled:center` <- NULL
    }
    if ("scale" %in% pre_process){
        training <- scale(training, center = FALSE, 
                          scale = apply(training, 2, function(x) sqrt(sum(x^2))))
        scale_factor <- attributes(training)$`scaled:scale`
        attributes(training)$`scaled:scale` <- NULL
    }
    
    result <- list()
    result$training <- cbind(training, training_class)
    result$center <- center
    result$scale_factor <- scale_factor
    result
}

# Auxiliary function to extract the training sets pre-processed by
# the preProcessTraining function.
extractTrainingSets <- function(pre_processed_training_list){
    lapply(pre_processed_training_list, function(x) x$training)
}

# Auxiliary function to extract the center and scale args from the
# training set pre-processed by the preProcessTraining function.
extractPreProcessArgs <- function(pre_processed_training_list){
    lapply(pre_processed_training_list, 
           function(x) list(center = x$center, scale_factor = x$scale_factor))
}

# Function to pre-process the testing set based on the center and scale 
# args from the training sets.
preProcessTesting <- function(testing, pre_processed_args, pre_process = NULL){
    if (is.null(pre_process)) return(testing)
    
    if ("center" %in% pre_process){
        center <- pre_processed_args$center
        testing <- t(apply(testing, 1, 
                           function(x, center) x - center, 
                           center = center))
    }
    if ("scale" %in% pre_process){
        scale_factor <- pre_processed_args$scale_factor
        testing <- t(apply(testing, 1, 
                           function(x, scale_factor) x / scale_factor, 
                           scale_factor = scale_factor))
    }
    
    testing
}
