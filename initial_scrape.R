library(tidyverse)

# iTunes Top 250 (Needs Manual Download of HTML)

itunes1 <- rvest::read_html("./chartable_html/itunes_html1.html") %>%
  rvest::html_nodes(".f3") %>%
  rvest::html_text(trim = TRUE)

itunes2 <- rvest::read_html("./chartable_html/itunes_html2.html") %>%
  rvest::html_nodes(".f3") %>%
  rvest::html_text(trim = TRUE)

itunes3 <- rvest::read_html("./chartable_html/itunes_html3.html") %>%
  rvest::html_nodes(".f3") %>%
  rvest::html_text(trim = TRUE)

itunes250 <- c(itunes1[2:101],
                  itunes2[2:101],
                  itunes3[2:51])

# Chartable Top 200

chartable200 <- rvest::read_html("https://chartable.com/charts/chartable/podcasts-global-comedy-reach") %>%
  rvest::html_nodes(".f3") %>%
  rvest::html_text(trim = TRUE)
chartable200 <- chartable200[2:201]

# Spotify Top 50

spotify50 <- rvest::read_html("https://chartable.com/charts/spotify/united-states-of-america-comedy") %>%
  rvest::html_nodes(".title , .f3 .blue") %>%
  rvest::html_text(trim = TRUE)
spotify50 <- unique(spotify50)

# Merge for Full Initial Sampling Frame
full_initial_sample <- unique(c(itunes250, chartable200, spotify50))

################################################################################
# Spotify Setup

Sys.setenv(SPOTIFY_CLIENT_ID = "CLIENT_ID_HERE")
Sys.setenv(SPOTIFY_CLIENT_SECRET = "CLIENT_SECRET_HERE")

access_token <- spotifyr::get_spotify_access_token()
auth_object <- spotifyr::get_spotify_authorization_code(scope = spotifyr::scopes()[c(7,8,9,10,14,15)])


################################################################################
# Search Spotify for Top Podcasts

for (i in 1:length(full_initial_sample)) {

  print(i)

  this_pod <- spotifyr::search_spotify(full_initial_sample[[i]], type = "show", limit = 1,
                                       authorization = auth_object[["credentials"]][['access_token']])
  this_pod$search_name <- full_initial_sample[[i]]

  this_pod <- this_pod %>%
    dplyr::select(search_name, name, id, dplyr::everything())

  if (i == 1) {
    podcasts1 <- this_pod
  } else {
    podcasts1 <- dplyr::bind_rows(podcasts1, this_pod)
  }
}

### Save Data Collected Here
saveRDS(podcasts1, "./data/initial_podcast_list.rds")

################################################################################
# Search Spotify for Top Podcasts

for (i in 1:nrow(podcasts1)) {

  print(i)

  this_show <- spotifyr::get_show(id = podcasts1$id[[i]],
                                  authorization = auth_object)

  this_df <- data.frame(id = this_show$id,
                        name = this_show$name,
                        publisher = this_show$publisher,
                        description = this_show$description,
                        total_episodes = this_show$total_episodes,
                        languages = this_show$languages,
                        explicit = this_show$explicit)

  if (i == 1) {
    podcasts2 <- this_df
  } else {
    podcasts2 <- dplyr::bind_rows(podcasts2, this_df)
  }
}

### Save Data Collected Here
saveRDS(podcasts2, "./data/detailed_podcast_list.rds")


################################################################################
# Get Episodes

### To forgo some querying burden, let's keep only English language podcasts
podcasts3 <- podcasts2[stringr::str_detect(podcasts2$language, "en"),]


episodes_list <- list()

for (i in 1:nrow(podcasts3)) {

  print(i)

  pod_seq <- seq(from = 1, to = podcasts3$total_episodes[[i]], by = 50) - 1

  for (j in 1:length(pod_seq)) {

    these_eps <- spotifyr::get_show_episodes(id = podcasts3$id[[i]], limit = 50,
                                             offset = pod_seq[[j]],
                                             authorization = auth_object)

    if (j == 1) {
      show_eps <- these_eps
    } else {
      show_eps <- dplyr::bind_rows(show_eps, these_eps)
    }

  }

  episodes_list[[i]] <- show_eps
}

names(episodes_list) <- podcasts3$name

View(episodes_list[["The Breakfast Club"]])

### Save Data Collected Here
saveRDS(episodes_list, "./data/core_sample_all_episodes_jan7.rds")

