library(mariokart)
library(ggplot2)
library(dplyr)

data(mkwii_characters)
data(mk8_vehicles)

mk8_characters %>% 
  group_by(speed_normal, handling_normal, weight_class) %>% 
  slice(1) %>% 
  ggplot() +
  aes(x = speed_normal, y = handling_normal, color = weight_class, label = character) +
  ggrepel::geom_label_repel(seed = 1, show.legend = FALSE) +
  geom_point() +
  scale_x_continuous(breaks = seq(2, 5, 0.5)) +
  labs(
    title = "Character speed vs handling combinations in Mario Kart 8",
    x = "Normal speed",
    y = "Normal handling",
    color = "Weight class"
  ) 

