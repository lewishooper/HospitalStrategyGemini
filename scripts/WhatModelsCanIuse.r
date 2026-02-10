library(httr2)
library(purrr)

# Ask Google: "What models can I use?"
request("https://generativelanguage.googleapis.com/v1beta/models") %>% 
  req_url_query(key = Sys.getenv("GEMINI_API_KEY")) %>% 
  req_perform() %>% 
  resp_body_json() %>% 
  .$models %>% 
  map_chr("name") %>% 
  print()
