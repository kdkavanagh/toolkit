#EXPECTS:
# 1. CSV file path
# 2. Column to generate the distribution for
# 3. Title for the graph
# 4. Png filename 
# 5. Column to split the distributions by (Optional)

for (package in c('data.table', 'ggplot2', 'scales', 'grid', 'RColorBrewer')) {
  if (!require(package, character.only=T, quietly=T)) {
    install.packages(package)
    library(package, character.only=T)
  }
}

require(data.table)
require(ggplot2)
require(scales)
number_ticks = function (n) { function(limits) pretty(limits, n) }

gtheme<- function() {
  require(scales); require(grid); require(RColorBrewer)
  # Generate the colors for the chart procedurally with RColorBrewer
  palette <- brewer.pal("Greys", n=9)
  color.background = "white"#palette[2]
  color.grid.major = palette[3]
  color.axis.text = palette[6]
  color.axis.title = palette[7]
  color.title = palette[9]
  
  # Begin construction of chart
  theme_bw(base_size=9) +
    
    # Set the entire chart region to a light gray color
    theme(panel.background=element_rect(fill=color.background, color=color.background)) +
    theme(plot.background=element_rect(fill=color.background, color=color.background)) +
    theme(panel.border=element_rect(color=color.background)) +
    
    # Format the grid
    theme(panel.grid.major=element_line(color=color.grid.major,size=.25)) +
    theme(panel.grid.minor=element_blank()) +
    theme(axis.ticks=element_blank()) +
    
    # Format the legend, but hide by default
    #theme(legend.position="none") +
    theme(legend.background = element_rect(fill=color.background)) +
    theme(legend.text = element_text(size=14,color=color.axis.title)) +
    
    # Set title and axis labels, and format these and tick marks
    theme(plot.title=element_text(color=color.title, size=16, vjust=1.25)) +
    theme(axis.text.x=element_text(size=12,color=color.axis.text)) +
    theme(axis.text.y=element_text(size=12,color=color.axis.text)) +
    theme(axis.title.x=element_text(size=14,color=color.axis.title, vjust=0)) +
    theme(axis.title.y=element_text(size=14,color=color.axis.title, vjust=1.25)) +
    
    # Plot margins
    theme(plot.margin = unit(c(0.5, 0.2, 0.4, 0.4), "cm"))
}


ca = commandArgs(trailingOnly=TRUE)
fileName = ca[1]
column = ca[2]
splitField=ca[5]
graphTitle=ca[4]
pngFile=ca[3]


if(is.na(splitField)) {
  splitField=NULL
}
 
t= fread(fileName)
if(!is.null(splitField)) {
  t[,eval(splitField):=as.factor(get(splitField))]
}

highestPercentile=0.99999
m = 1/(1-highestPercentile)
x=data.table(inverse=seq(1,1/(1-highestPercentile), by=0.333))
x$percentiles=1-(1/x$inverse)


g=ggplot(t[,list(
  percentile=x$percentiles, 
  inverse=x$inverse, 
  value=quantile(get(column), x$percentiles, na.rm=T)
),by=splitField], aes(x=inverse, y=value))

if(is.null(splitField)) {
  g=g+geom_line()
} else {
  g=g+geom_line(aes_string(color=splitField))
}

g=g+
  scale_x_log10(limits=c(10,100000),
                breaks=c(10,100,1000,10000,100000), 
                label=c( "90th", "99th", "99.9th", "99.99th", "99.999th"))+
  scale_y_continuous(labels=comma, breaks=number_ticks(10))+
  xlab("Percentile")+
  ylab(column)+
  gtheme()+
  ggtitle(graphTitle)

if(!is.na(pngFile)) {
  ggsave(g, file=pngFile, height=5, width=8)
}