#!/bin/env R

library(tidyverse)
library(dplyr)
library(RColorBrewer)
library(reshape2)
library(ggtext)

args <- commandArgs(trailingOnly=TRUE)

# load arguments
print(args)
setwd(args[1])

# Arguments
sample_name <- args[2]
sample_Q_file <- args[3]
sample_fam_file <-args[4]
reference_data <- args[5]
reference_indicator <- args[6]
configuration <- args[7]

# load sample data
results <- read.table(sample_Q_file)
fam <- read.table(sample_fam_file)


# add fam ID to each row for matching with HapMap3 Pop
results <- data.frame(results)
results$name <- fam$V2
rm(fam)
gc()

# determine HAPMAP3 or 1000 Genomes
if (reference_indicator == "HapMap3"){
  # load reference data
  full_name_reference_3 <- paste0(configuration, "/hapmap3.csv")
  reference <- read.table(reference_data, header = TRUE)

  # match reference data to fam
  results["Region"] <- lapply(results["name"], function(col) reference$Pop[match(col, reference$IID)])
  results <- results[order(results$Region),]

  ### colors
  coul <- brewer.pal(11, "Set3")
  print(full_name_reference_3)
  full_name_reference <- read.table(full_name_reference_3, sep=",", header=TRUE)

  # put region
  regions <- full_name_reference$Region
  w <- 180
  h <- 280

}else if (reference_indicator == "1000Genomes"){
  # load reference data
  full_name_reference_3 <- paste0(configuration, "/1kgenomes.csv")
  reference <- read.table(reference_data, header = TRUE)

  # match reference data to fam
  results["Region"] <- lapply(results["name"], function(col) reference$Pop[match(col, reference$IID)])
  results <- results[order(results$Region),]


  ### colors
  coul1 <- brewer.pal(11, "Set3")
  coul2 <- brewer.pal(8, "Pastel1")
  coul3 <- brewer.pal(7, "Pastel2")
  coul <- c(coul1, coul2, coul3)

  full_name_reference <- read.table(full_name_reference_3, sep=",", header=TRUE)

  # region
  regions <- full_name_reference$Region
  full_regions <- full_name_reference$Description

  w <- 180
  h <- 350

}else {
  # load reference data
  reference <- read.table(reference_data, header = FALSE)

  # match reference data to fam
  results["Region"] <- lapply(results["name"], function(col) reference$V5[match(col, reference$V1)])
  results <- results[order(results$Region),]

  ### colors
  coul <- brewer.pal(5, "Set3")

  full_name_reference <- read.table(full_name_reference_2, sep="\t", header=TRUE)

  # region
  regions <- full_name_reference$Region
  full_regions <- full_name_reference$Description
  w <- 180
  h <- 280
}

### rename columns
for (region in regions){
  r <- results %>% filter (Region == region)
  r <- data.frame(t(colSums(Filter(is.numeric, r))))
  name <- colnames(r)[max.col(r, ties.method = "first")]
  colnames(results)[which(names(results) == name)] <- region
}

## graph patient sample
patient <- results[is.na(results$Region),]
dat <- melt(patient, id=c("Region", "name"))
dat$value <- signif(dat$value * 100, digits=3)
dat$Labels <- sapply(dat$value, function(x){
  if (x>= 3){
    return(round(x, digits = 3))
  }
  else{
    return("")
  }
})

dat

### top 3
top3 <- dat %>% slice_max(value, n = 3)
top3 <- top3 %>% top_n(-1)
dat$Labels2 <- sapply(dat$value, function(x){
  if (x>= top3$value){
    return(round(x, digits = 3))
  }
  else{
    return("")
  }
})

dat
dat <- merge(dat, full_name_reference, by.x="variable", by.y="Region", all.x=TRUE)
### pie chart with percentages at the legend
for(i in 1:nrow(dat)) {       # for-loop over rows
  dat[i,8] <- paste0(dat[i, 7]," - ",dat[i,4], "%")
}


dat$V8<- with(dat, reorder(V8,-value))
top10 <- dat %>% slice_max(value, n = 10)
top10 <- top10$V8

ggplot(dat, aes(name, value, fill = factor(V8))) + theme_void() +
  geom_bar(stat="identity", width=1) +
  coord_polar("y", start=0) +
  geom_text(size=6, aes(x=1.65, label=Labels),
            position = position_stack(vjust=0.5)) +
  theme(panel.background = element_blank(),
        axis.line = element_blank(),
        axis.text = element_blank(),
        axis.ticks = element_blank(),
        axis.title = element_blank(),
        legend.key.height = unit(0.75, 'cm'), #change legend key height
        legend.key.width = unit(0.75, 'cm'), #change legend key width
        legend.title = element_text(size=14), #change legend title font size
        legend.text = element_text(size=13),
        legend.position = "bottom",
        legend.direction = "vertical",
        legend.box.margin=margin(0,0,20,0)) +
  guides(fill=guide_legend(ncol=1)) +
  scale_fill_manual(values=coul, name="Ancestry",breaks=top10)

ggsave(paste0(sample_name, ".png"),
       width = 180,
       height = 280,
       bg = "white",
       units="mm"
)
