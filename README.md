# Customer Segmentation with Clustering (R)

Segmenting customers with three clustering approaches and comparing how well the resulting segments agree.

## Methods

| Method | Details |
|---|---|
| **Hierarchical clustering** | Dissimilarity matrix with `cluster::daisy`, complete linkage, dendrogram, tree cut at k = 10 |
| **K-means** | k = 10, with segments visualized using `clusplot` |
| **Model-based clustering** | `mclust::Mclust`: BIC-selected model and a fixed 4-cluster solution |
| **Comparison** | Adjusted Rand Index between hierarchical, k-means and model-based solutions |

Each solution is profiled by computing the mean of every variable per segment (`seg.summ()`), which makes it easy to describe what distinguishes each customer group.

## Data

The dataset is **not included** in this repository. The script expects a file at `data/BOA.csv` with a row-index column, a `CUST_ID` identifier column, and numeric customer behavior variables (including `PURCHASES`). The first two columns are dropped before clustering.

## Repository structure

```
customer-segmentation-clustering/
├── data/                       # place BOA.csv here
└── scripts/
    └── customer_segmentation.R
```

## How to run

1. Install R packages: `cluster`, `mclust`, `poLCA`.
2. Add `BOA.csv` to `data/`.
3. Set the working directory to the repository root and run:

```r
source("scripts/customer_segmentation.R")
```

## Author

Rohan Satishkumar, MS Marketing Analytics, Illinois Institute of Technology
