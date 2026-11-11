# =============================================================================
# Customer segmentation: hierarchical, k-means and model-based clustering
# -----------------------------------------------------------------------------
# Goal  : Split customers into behavioural segments and check how stable the
#         segments are across three clustering methods.
# Data  : data/BOA.csv  (not included; see data/README.md)
#         Layout: a row-index column, a CUST_ID column, then numeric behaviour
#         variables (e.g. BALANCE, PURCHASES, CREDIT_LIMIT, PAYMENTS ...).
# Run   : from the repository root ->  Rscript scripts/customer_segmentation.R
# Output: figures/*.png and results/*.csv
#
# Choices that matter (and differ from a naive run):
#   * Variables are standardised first. Without this, variables measured in
#     large units (balances, purchases) dominate every distance calculation.
#   * Rows with missing values are dropped and the number dropped is reported.
#   * The number of segments K is chosen from the data (average silhouette width)
#     and the SAME K is used for all three methods, so the Adjusted Rand Index
#     compares like with like. Override with:  K=6 Rscript scripts/...
# =============================================================================

suppressPackageStartupMessages({
  library(cluster)   # daisy, silhouette, clusplot
  library(mclust)    # model-based clustering, adjustedRandIndex
})

dir.create("figures", showWarnings = FALSE)
dir.create("results", showWarnings = FALSE)

data_file <- "data/BOA.csv"
if (!file.exists(data_file)) {
  stop("Data file not found: ", data_file, "\nSee data/README.md for the expected layout.")
}

# -----------------------------------------------------------------------------
# 1. Load and prepare
# -----------------------------------------------------------------------------
boa_raw <- read.csv(data_file, stringsAsFactors = FALSE)
cat("Rows:", nrow(boa_raw), " Columns:", ncol(boa_raw), "\n")

# Drop the row-index and customer-id columns (by name; fall back to the first two)
id_cols <- intersect(c("X", "CUST_ID"), names(boa_raw))
if (length(id_cols) == 0) id_cols <- names(boa_raw)[1:2]
boa_data <- boa_raw[, setdiff(names(boa_raw), id_cols), drop = FALSE]
boa_data <- boa_data[, sapply(boa_data, is.numeric), drop = FALSE]
n_before <- nrow(boa_data)
boa_data <- na.omit(boa_data)
cat("Numeric variables used:", ncol(boa_data), "\n")
cat("Rows dropped for missing values:", n_before - nrow(boa_data), "\n")
summary(boa_data)

if ("PURCHASES" %in% names(boa_data)) {
  png("figures/purchases_histogram.png", width = 1200, height = 800, res = 150)
  hist(boa_data$PURCHASES, breaks = 40, col = "#2b6cb0", border = "white",
       main = "Distribution of PURCHASES (heavily right-skewed)", xlab = "PURCHASES")
  dev.off()
}

boa_scaled <- scale(boa_data)

# -----------------------------------------------------------------------------
# 2. Choose the number of segments (K)
# -----------------------------------------------------------------------------
set.seed(1234)
dist_mat <- dist(boa_scaled)
k_grid   <- 2:10
ss <- sapply(k_grid, function(k) {
  km  <- kmeans(boa_scaled, centers = k, nstart = 10)
  sil <- mean(silhouette(km$cluster, dist_mat)[, "sil_width"])
  c(tot_withinss = km$tot.withinss, avg_silhouette = sil)
})
k_sel <- data.frame(K = k_grid, t(ss))
write.csv(k_sel, "results/choosing_k.csv", row.names = FALSE)

K <- as.integer(Sys.getenv("K", NA))
if (is.na(K)) K <- k_sel$K[which.max(k_sel$avg_silhouette)]
cat("\nSegments chosen (K):", K, "\n")

png("figures/choosing_k.png", width = 1600, height = 700, res = 150)
par(mfrow = c(1, 2))
plot(k_sel$K, k_sel$tot_withinss, type = "b", pch = 19, col = "#2b6cb0",
     xlab = "Number of clusters (K)", ylab = "Total within-cluster sum of squares",
     main = "Elbow plot")
plot(k_sel$K, k_sel$avg_silhouette, type = "b", pch = 19, col = "#dd6b20",
     xlab = "Number of clusters (K)", ylab = "Average silhouette width",
     main = "Silhouette width")
abline(v = K, lty = 2, col = "grey40")
dev.off()

# -----------------------------------------------------------------------------
# 3. Three clustering methods, all with the same K
# -----------------------------------------------------------------------------
# 3a. Hierarchical (Euclidean distance on standardised data, complete linkage)
boa_hc <- hclust(dist_mat, method = "complete")
hc_cl  <- cutree(boa_hc, k = K)
png("figures/dendrogram.png", width = 1600, height = 800, res = 150)
plot(boa_hc, labels = FALSE, hang = -1, main = "Hierarchical clustering (complete linkage)",
     xlab = "", sub = "")
rect.hclust(boa_hc, k = K, border = "red")
dev.off()

# 3b. K-means
set.seed(1234)
km    <- kmeans(boa_scaled, centers = K, nstart = 25)
km_cl <- km$cluster

# 3c. Model-based clustering: BIC-selected model, and a fixed-K solution
mc_auto <- Mclust(boa_scaled)
mc_k    <- Mclust(boa_scaled, G = K)
cat("\nMclust BIC-selected model:", mc_auto$modelName, "with", mc_auto$G, "clusters\n")

png("figures/kmeans_clusplot.png", width = 1400, height = 1100, res = 150)
clusplot(boa_scaled, km_cl, color = TRUE, shade = TRUE, labels = 4, lines = 0,
         main = paste0("K-means segments (K = ", K, ") on the first two principal components"))
dev.off()
png("figures/mclust_clusplot.png", width = 1400, height = 1100, res = 150)
clusplot(boa_scaled, mc_k$classification, color = TRUE, shade = TRUE, labels = 4, lines = 0,
         main = paste0("Model-based segments (G = ", K, ") on the first two principal components"))
dev.off()

# -----------------------------------------------------------------------------
# 4. Profile the segments (in ORIGINAL units so they can be read by a marketer)
# -----------------------------------------------------------------------------
seg_summ <- function(data, groups) {
  out <- aggregate(data, list(Segment = groups), function(x) mean(as.numeric(x), na.rm = TRUE))
  cbind(out[1], Size = as.integer(table(groups)),
        Share = round(as.numeric(table(groups)) / nrow(data), 3), out[-1])
}
profile_km <- seg_summ(boa_data, km_cl)
write.csv(profile_km, "results/segment_profiles_kmeans.csv", row.names = FALSE)

# Index vs the overall average (100 = average customer): easier to read than raw means
overall    <- colMeans(boa_data)
index_km   <- profile_km
vars       <- names(boa_data)
index_km[vars] <- round(sweep(as.matrix(profile_km[vars]), 2, overall, "/") * 100)
write.csv(index_km, "results/segment_index_kmeans.csv", row.names = FALSE)
cat("\nK-means segment profiles (index vs average customer = 100):\n")
print(index_km)

write.csv(as.data.frame(table(hierarchical = hc_cl)), "results/cluster_sizes_hierarchical.csv", row.names = FALSE)
write.csv(as.data.frame(table(kmeans = km_cl)),       "results/cluster_sizes_kmeans.csv",       row.names = FALSE)
write.csv(as.data.frame(table(mclust = mc_k$classification)), "results/cluster_sizes_mclust.csv", row.names = FALSE)

# -----------------------------------------------------------------------------
# 5. How much do the methods agree?  (Adjusted Rand Index: 1 = identical, 0 = chance)
# -----------------------------------------------------------------------------
ari <- data.frame(
  Comparison = c("Hierarchical vs K-means", "Hierarchical vs Model-based",
                 "K-means vs Model-based", "K-means vs Model-based (BIC-selected G)"),
  ARI = c(adjustedRandIndex(hc_cl, km_cl),
          adjustedRandIndex(hc_cl, mc_k$classification),
          adjustedRandIndex(km_cl, mc_k$classification),
          adjustedRandIndex(km_cl, mc_auto$classification))
)
write.csv(ari, "results/ari_comparison.csv", row.names = FALSE)
cat("\nAdjusted Rand Index between methods:\n"); print(ari, digits = 3)

cat("\nDone. See figures/ and results/.\n")
