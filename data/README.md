# Data

Place `BOA.csv` in this folder. The file is not included in the repository.

Expected layout (one row per customer):

| Column | Description |
|---|---|
| `X` | Row index (dropped before clustering) |
| `CUST_ID` | Customer identifier (dropped before clustering) |
| numeric columns | Customer behavior variables, including `PURCHASES`; all numeric columns are used |

Rows with missing values are dropped, and the script prints how many.
