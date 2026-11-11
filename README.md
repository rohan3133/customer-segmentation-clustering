# Customer Segmentation with Clustering (R)

A reproducible R workflow that segments customers from their behavioral data with three clustering methods and checks how stable the segments are across methods.

> **Status:** the dataset (`BOA.csv`) is not included in this repository, so no segment results are reported here. The pipeline has been tested end to end on synthetic data with the same layout. Add the CSV to `data/` and one command regenerates every figure and table.

## What the pipeline does

| Step | Approach |
|---|---|
| **Prepare** | Drop ID columns, keep numeric behavior variables, drop incomplete rows (the count is reported), **standardize every variable** |
| **Choose K** | Elbow plot and **average silhouette width** over K = 2 to 10; K is picked from the data (or set with `K=6`) |
| **Hierarchical** | Euclidean distance, complete linkage, dendrogram cut at K |
| **K-means** | `nstart = 25` for stable solutions, segments plotted on the first two principal components |
| **Model-based** | `mclust::Mclust`, both BIC-selected and fixed at the same K |
| **Profile** | Segment sizes, mean of every variable per segment, and an **index versus the average customer (100 = average)** so segments are easy to describe to a marketer |
| **Compare** | Adjusted Rand Index between the methods, all using the same K so the comparison is like for like |

### Why these choices

- **Standardizing matters.** Behavioral data mixes variables in very different units (balances and purchases in the thousands, frequencies between 0 and 1). Unscaled, the large-unit variables dominate every distance and the segments mostly reflect them.
- **One K for all methods.** Comparing a 10-cluster solution with a 4-cluster one gives an Adjusted Rand Index that says little about stability.
- **Silhouette, not a guess.** The number of segments comes from the data instead of being fixed in advance.

## Outputs (written by the script)

```
figures/   purchases_histogram.png  choosing_k.png  dendrogram.png
           kmeans_clusplot.png      mclust_clusplot.png
results/   choosing_k.csv           segment_profiles_kmeans.csv   segment_index_kmeans.csv
           cluster_sizes_*.csv      ari_comparison.csv
```

## Repository structure

```
customer-segmentation-clustering/
├── data/                       # place BOA.csv here (see data/README.md)
└── scripts/
    └── customer_segmentation.R
```

## How to run

Install the R packages `cluster` and `mclust`, add `data/BOA.csv`, then from the repository root:

```bash
Rscript scripts/customer_segmentation.R
# optional: force the number of segments
K=6 Rscript scripts/customer_segmentation.R
```

## Data

`data/BOA.csv` is expected to contain a row-index column, a `CUST_ID` identifier column, and numeric customer behavior variables (including `PURCHASES`). See [`data/README.md`](data/README.md).

## Author

Rohan Satishkumar, MS Marketing Analytics, Illinois Institute of Technology
