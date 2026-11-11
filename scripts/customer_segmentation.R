# Load required libraries
library(cluster)
library(mclust)
library(poLCA)

getwd()

# Load data
boa_data <- read.csv("data/BOA.csv")

# Summary and structure of the dataset
dim(boa_data)  # Dimensions of the dataset
str(boa_data)  # Structure of the dataset
summary(boa_data)  # Summary statistics

# Visualize PURCHASES using a histogram
hist(boa_data$PURCHASES, main = "Histogram of PURCHASES", 
     xlab = "PURCHASES", col = "blue", breaks = 30)

# Remove the first two columns (X and CUST_ID)
boa_data <- boa_data[, -c(1, 2)]

# Convert categorical variables to factors if necessary
# No categorical data explicitly mentioned; can be skipped unless required.

# Hierarchical Clustering
boa_dist <- daisy(boa_data)  # Compute distance matrix
boa_hc <- hclust(boa_dist, method = "complete")  # Hierarchical clustering
plot(boa_hc, main = "Dendrogram of BOA Data", xlab = "", sub = "")

# Cut tree into clusters and visualize
rect.hclust(boa_hc, k = 10, border = "red")  # Cut tree into 10 clusters
boa_hc_clusters <- cutree(boa_hc, k = 10)  # Cluster assignment
table(boa_hc_clusters)

# Summarize clusters
seg.summ <- function(data, groups) {
  aggregate(data, list(groups), function(x) mean(as.numeric(x), na.rm = TRUE))
}
seg.summ(boa_data, boa_hc_clusters)

# K-means Clustering
set.seed(1234)  # For reproducibility
boa_kmeans <- kmeans(boa_data, centers = 10)
seg.summ(boa_data, boa_kmeans$cluster)

# Visualize K-means clusters
clusplot(boa_data, boa_kmeans$cluster, color = TRUE, shade = TRUE, 
         labels = 4, lines = 0, main = "K-means Cluster Plot")

# Mclust (Model-based Clustering)
boa_mclust <- Mclust(boa_data)
summary(boa_mclust)

# Fit Mclust with 4 clusters
boa_mclust4 <- Mclust(boa_data, G = 4)
summary(boa_mclust4)
clusplot(boa_data, boa_mclust4$class, color = TRUE, shade = TRUE, 
         labels = 4, lines = 0, main = "Model-based Cluster Plot")

# Compare clustering solutions
adjustedRandIndex(boa_hc_clusters, boa_kmeans$cluster)
adjustedRandIndex(boa_hc_clusters, boa_mclust4$class)
