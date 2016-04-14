# Define constants
R_PATH <- "R"
DATA_PATH <- "data"
FILES_NAMES <- c("mfeat-fac", "mfeat-fou", "mfeat-kar")

# Source files
source(file.path(R_PATH, "data_functions.R"))

# Read the data sets
data_sets_list <- readDataSets(DATA_PATH, FILES_NAMES)

# Compute the dissimilarity matrix for each data set
diss_matrix_list <- lapply(data_sets_list, function(data_set){
    as.matrix(cluster::daisy(data_set, metric = "euclidean"))
})