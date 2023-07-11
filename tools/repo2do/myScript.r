library(readr)
library(dplyr)
library(ggplot2)
library(forcats)

# import dataframe
df <- read_csv("us-500.csv")

# manipulate data
plot_data <- df %>%
  group_by(state) %>%
  count()

# save manipulated data to output folder
write_csv(plot_data, "plot_data.csv")

# create plot based on manipulated data
plot <- plot_data %>% 
  ggplot()+
  geom_col(aes(fct_reorder(state, n), 
               n, 
               fill = n))+
  coord_flip()+
  labs(
    title = "Number of people by state",
    subtitle = "From US-500 dataset",
    x = "State",
    y = "Number of people"
  )+ 
  theme_bw()

ggsave("myplot.png", width = 10, height = 8, dpi = 100)