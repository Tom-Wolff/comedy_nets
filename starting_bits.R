# SPOTIFY API SETUP

devtools::install_github('charlie86/spotifyr')

Sys.setenv(SPOTIFY_CLIENT_ID = "CLIENT_ID_HERE")
Sys.setenv(SPOTIFY_CLIENT_SECRET = "CLIENT_SECRET_HERE")

access_token <- spotifyr::get_spotify_access_token()
auth_object <- spotifyr::get_spotify_authorization_code(scope = spotifyr::scopes()[c(7,8,9,10,14,15)])


# READ IN LIST OF PODCAST IDS (NOT SURE IF THERE'S A GOOD WAY TO AUTOMATICALLY GENERATE)


# WORKFLOW FOR GETTING ALL EPISODES OF A SINGLE PODCAST

### Get overall info for show
pod_info <- spotifyr::get_show("3kDS5MRlBl53tA3MRGqLzx", authorization = auth_object)

### Generate sequence for iteratively scraping episodes in batches of 50
pod_seq <- seq(from = 1, to = pod_info$total_episodes, by = 50)


### Loop over `pod_seq` to get all
for (i in 1:length(pod_seq)) {

  print(i)

  these_eps <- spotifyr::get_show_episodes(id = "3kDS5MRlBl53tA3MRGqLzx", limit = 50,
                                           offset = (pod_seq[[i]] - 1),
                                           authorization = auth_object)

  if (i == 1) {
    pod_eps <- these_eps
  } else {
    pod_eps <- dplyr::bind_rows(pod_eps, these_eps)
  }
}


# EXTRACT NAMES FROM EPISODE INFO

# remotes::install_github("quanteda/spacyr")

stav_eps$words_only <- stringr::str_replace_all(stav_eps$name, " - ", " ")
stav_eps$words_only <- stringr::str_replace_all(stav_eps$words_only, "\\d", " ")
stav_eps$words_only <- stringr::str_replace_all(stav_eps$words_only, "&", "and")

# Remove

test <- spacyr::spacy_parse(stav_eps$words_only)
test2 <- spacyr::spacy_parse(stav_eps$description[[1]])

spacyr::get_named_entities(test)
spacyr::entity_consolidate(test)
spacyr::entity_consolidate(test) %>% dplyr::filter(entity_type != "")

# Regex for full name extraction
"^[A-Z][a-z]*_[A-Z][a-z]*$"

