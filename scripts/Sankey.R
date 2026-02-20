# R Logic for Sankey (using networkD3 or ggsankey)

if (!require("remotes")) install.packages("remotes")

# Install ggsankey from GitHub
remotes::install_github("davidsjoberg/ggsankey")



library(ggsankey)

sankey_df <- final_dataset %>%
  make_long(primary_theme, secondary_theme)

ggplot(sankey_df, aes(x = x, next_x = next_x, node = node, next_node = next_node, fill = factor(node))) +
  geom_sankey(flow.alpha = 0.6) +
  theme_sankey(base_size = 18) +
  labs(title = "The Strategic Vehicle: Primary to Secondary Flow")
