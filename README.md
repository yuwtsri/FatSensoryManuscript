# FatSensoryManuscript
Codes associated with fat sensory manuscript

- bulkRNAseq_salmon_deseq2_nested_updated.Rmd: 
  - raw R file analyzing bulk-RNA seq data
  - Use Salmon to align raw sequencing reads, and use DESeq2 to perform differential expression analysis
- nerve_density_quant.ijm:
  - customized FIJI script to quantify nerve density in multiple ROIs in a given stack image.
  - users choose the center of roi containing nerve signals, then roi of 80 um (x) x 80 um (y) x 20 um will be created.
  - maximum projection will be performed, nerve signals will be extracted by auto threshold.
  - nerve density is defined as total_pixels(signal)/total_pixels(background)
