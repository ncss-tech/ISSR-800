
library(tricolore)
library(raster)
library(colorspace)
library(sp)
library(ggtern)

# monthly mm of PPT - PET, multipled by 100 and saved as integers
x <- brick(list(
  sand=raster('E:/gis_data/FY2019-800m-rasters/rasters/sand.tif'),
  silt=raster('E:/gis_data/FY2019-800m-rasters/rasters/silt.tif'),
  clay=raster('E:/gis_data/FY2019-800m-rasters/rasters/clay.tif')
)
)


hist(x)

# sampling of source data
s <- na.omit(sample(x, 10000))
dimnames(s)[[2]] <- names(x)
head(s)
nrow(s)

# all data, bands are columns
spdf <- as(x, 'SpatialPixelsDataFrame')


# https://en.wikipedia.org/wiki/Histogram_equalization
# this is the same as GRASS: r.colors -e + d.rgb | r.composite
# equally weight via quantile-transform
f <- function(i) {
  e <- ecdf(i)
  return(e(i))
}

# weight samples
s <- apply(s, 2, f)
s <- as.data.frame(s)

# weight full grid
spdf$sand <- f(spdf$sand)
spdf$silt <- f(spdf$silt)
spdf$clay <- f(spdf$clay)


# generate colors as mixture of sRGB coordinates
s$sRGBcolor <- rgb(red = s$sand, green = s$silt, blue = s$clay, maxColorValue = 1)

# hmm.. not mixed in the same way as r.composite
plot(s[, 1:3], col=s$sRGBcolor, pch=15)

## Another idea: http://www.ggtern.com/
# http://www.ggtern.com/docs/

## hmm.. not quite there
ggtern(s, aes(clay, silt, sand)) + geom_point()




## TODO: contact author for additional ideas on color-mixing
# https://github.com/jschoeley/tricolore


# generate new tri-hue color scheme
colors_and_legend <- Tricolore(s, 'clay', 'silt', 'sand', hue=0, chroma=1, lightness=0.75, center=NA, contrast=0)
colors_and_legend <- Tricolore(s, 'clay', 'silt', 'sand', hue=0, chroma=1, lightness=0.75, contrast=0, crop=TRUE)
colors_and_legend <- Tricolore(s, 'clay', 'silt', 'sand', hue=0, chroma=1, lightness=0.75, contrast=0, crop=FALSE)

colors_and_legend$key + ggtern::theme_clockwise()
plot(s[, 1:3], col=colors_and_legend$rgb, pch=15)


## now apply to full data
## this takes a while

# consider lowering chroma
# darker colors help with contrast
# no-centering = categories
colors_and_legend.cat <- Tricolore(spdf@data, 'clay', 'silt', 'sand', hue=0, chroma=1, lightness=0.5, contrast=0, show_data=FALSE)

# centering = continuous
colors_and_legend <- Tricolore(spdf@data, 'clay', 'silt', 'sand', hue=0, chroma=1, lightness=0.5, contrast=0, center=NA, show_data=FALSE)

# extract new colors for each pixel
cols.cat <- cols <- t(col2rgb(colors_and_legend.cat$rgb))
cols <- t(col2rgb(colors_and_legend$rgb))

spdf$r <- cols[, 1]
spdf$g <- cols[, 2]
spdf$b <- cols[, 3]

spdf$r.cat <- cols.cat[, 1]
spdf$g.cat <- cols.cat[, 2]
spdf$b.cat <- cols.cat[, 3]

# back to brick for simpler plotting
r <- brick(spdf)

# this is the same as GRASS: r.colors -e + d.rgb | r.composite
plotRGB(r[[c('clay', 'silt', 'sand')]], stretch='lin')

plotRGB(r[[c('r', 'g', 'b')]], stretch='lin')

plotRGB(r[[c('r.cat', 'g.cat', 'b.cat')]], stretch='lin')


# save composte as RGBA tiff, alpha channel contains no-data values

# 
# ## combine figures via cowplot
# # https://cran.r-project.org/web/packages/cowplot/vignettes/introduction.html
# library(cowplot)
# 
# plotRGB(r[[c('r', 'g', 'b')]], stretch='lin')
# p <- recordPlot()
# dev.off()
# 
# # note hack requires to suppress misleading x/y axis labels
# plot_grid(p, colors_and_legend$key + xlab('') + ylab(''))
#   
# 
# plotRGB(r[[c('r.cat', 'g.cat', 'b.cat')]], stretch='lin')
# p <- recordPlot()
# dev.off()
# 
# # note hack requires to suppress misleading x/y axis labels
# plot_grid(p, colors_and_legend.cat$key + xlab('') + ylab(''))



## further ideas here
# https://github.com/jschoeley/tricolore
# https://stackoverflow.com/questions/33227182/how-to-set-use-ggplot2-to-map-a-raster

# library(ggplot2)
# library(rasterVis)
# library(ggthemes) # theme_map()
# 
# x <- as.data.frame(spdf)
# x$color <- colors_and_legend$rgb
# 
# 
# ggplot() +  
#   geom_tile(data=x, aes(x=x, y=y, fill=color)) + 
#   scale_fill_identity() +
#   coord_equal() +
#   theme_map() +
#   annotation_custom(
#     ggplotGrob(
#       colors_and_legend$key +
#         labs(L = '0-2', T = '3-4', R = '5-8')),
#     xmin = 55e5, xmax = 75e5, ymin = 8e5, ymax = 80e5
#   )
#   theme(legend.position="bottom") +
#   theme(legend.key.width=unit(2, "cm"))
# 


# 
# ggplot(euro_example) +
#   geom_sf(aes(fill = educ_rgb_disc), size = 0.1) +
#   scale_fill_identity() +
#   annotation_custom(
#     ggplotGrob(
#       tric_educ_disc$key +
#         labs(L = '0-2', T = '3-4', R = '5-8')),
#     xmin = 55e5, xmax = 75e5, ymin = 8e5, ymax = 80e5
#   ) +
#   theme_void() +
#   coord_sf(datum = NA) +
#   labs(title = 'European inequalities in educational attainment',
#        subtitle = 'Regional distribution of ISCED education levels for people aged 25-64 in 2016.',
#        caption = 'Data by eurostat (edat_lfse_04).')
# 
# 





