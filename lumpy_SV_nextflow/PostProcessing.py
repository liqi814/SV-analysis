import os
import pandas as pd
os.chdir("D:/All_IPF_lumpy_analysis/lumpyCNV")

AnnotDataFrame = pd.read_csv("IPF3170.197154/AnnotSV_IPF3170.197154.tsv", sep="\t")
AnnotDataFrame = AnnotDataFrame[AnnotDataFrame.SV_chrom.isin([str(i) for i in range(23)])]
AnnotDataFrame = AnnotDataFrame[AnnotDataFrame.IPF3170.str.contains("/1")]
AnnotDataFrame = AnnotDataFrame[AnnotDataFrame.SV_type.isin(['DUP', 'DEL'])]
AnnotDataFrame = AnnotDataFrame[AnnotDataFrame.ACMG_class.isin(['4', '5', 'full=5', 'full=4'])]