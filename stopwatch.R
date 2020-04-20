.interactive <- function(){
  pres_name <- "test1"
  pres_name <- "wutzler20_egu_agg_inla"
  pres_title <- pres_name
  # copy your pdf of the presentation into <pres_name>/slideshow.pdf
  # and copy your audio to <pres_name>/audio.m4a and <pres_name>/audio.ogg
  burst_slides(pres_name) 
  durations <- time_durations(pres_name)
  saveRDS(durations, file = file.path(pres_name,"durations.rds"))
  slidecast <- gen_slides(durations, pres_name, pres_title)
  writeLines(slidecast, file.path(pres_name, paste0("slidecast.html")))
  cat("\n") # line feed
  message("slides written to ",file.path("pres_name","slidecast.html"))
  write_selfcontained_html(slidecast, pres_name)
  message("slides written to ",file.path("pres_name",paste0(pres_name,".html")))
}

#burst_slides <- function(pres_name, widht = 1920, height = 1200) {
burst_slides <- function(pres_name, width = 1280, height = 800) {
  prevwd <- setwd(pres_name)
  on.exit(setwd(prevwd))
  unlink(paste0("slideshow-*.jpg"))
  system(sprintf("slidecrunch burst slideshow.pdf --width %d --height %d", width, height))
}

time_durations <- function(pres_name){
  nSlides <- length(dir(file.path(pres_name), "^slideshow-.*\\.jpg"))
  try(system(paste0("audacity ", file.path(pres_name,"audio.m4a"), " &")))
  try(system(paste0("FoxitReader ", file.path(pres_name,"slideshow.pdf"), " &")))
  cat("Keep your presentation slides before you,",
      " start the audio after the countdown, and a the R-Shell hit ",
      "<ENTER> at times of slide transition.")
  cat("First <ENTER> starts the countdown.")
  pause()
  countdown(4L)
  durations <- stopwatch(nSlides)
}

gen_slides <- function(durations, pres_name, pres_title = pres_name){
  nSlidesTimed <- length(durations)
  output <- gen_slides_sections(durations)
  slidecast_head <- readLines("template/slidecast_head.html")
  slidecast_head <- sub("Presentation Title",pres_title, slidecast_head)
  slidecast_tail <- readLines("template/slidecast_tail.html")
  slidecast <- c(slidecast_head , output, slidecast_tail )
}

pause = function(prompt = "Press <Enter> to continue...") {
  if (interactive()) {
    invisible(readline(prompt = prompt))
  } else {
    cat(prompt)
    invisible(readLines(file("stdin"), 1))
  }
}

countdown <- function(n){
  for (i in rev(seq_len(n))) {
    cat(i)
    Sys.sleep(1)
  }
  cat(0)
}

stopwatch <- function(maxSlides = 80L){
  print("Press <Enter> to continue... or any other + <Enter> to quit.")
  input <- ""
  slide <- 1L 
  #maxSlides <- 80L
  durations <- numeric(maxSlides)
  start_time = Sys.time()
  while (!nzchar(input) & slide < maxSlides) {
    input <- pause(paste0("slide ",slide,": "))
    end_time = Sys.time()
    durations[slide] <- duration <- as.numeric(end_time - start_time)
    start_time = Sys.time()
    cat(duration)
    slide <- slide + 1L
  }
  durations[seq_len(slide - 1L)]
}

gen_slides_sections <- function(durations){
  do.call(c, lapply(seq_along(durations), function(i){
    sprintf('<section class="slide" data-narrator-duration="%f" data-duration="%f">
      <img src="slideshow-%d.jpg" />
</section>
',durations[i], durations[i]*1000, i - 1) # starts at slide 0
  }))
}

write_selfcontained_html <- function(slidecast, pres_name){
  slidecast_audio <- embed_audio(slidecast, pres_name)
  writeLines(slidecast_audio, file.path(pres_name, paste0("slidecast_audio.html")))
  # https://github.com/BitLooter/htmlark
  system(paste0("htmlark ", file.path(pres_name,"slidecast_audio.html")," -o ", pres_name, ".html"))
}

embed_audio <- function(slidecast, pres_name){
  prevwd <- setwd(pres_name)
  on.exit(setwd(prevwd))
  # https://github.com/BitLooter/htmlark, does not embed audio, need manually
  # need to convert audio to data tag
  system("base64 -w0 audio.ogg > audio_ogg.txt")
  audio_str <- suppressWarnings(readLines("audio_ogg.txt"))
  #writeLines(audio_str,"audio_ogg2.txt", sep = "")
  slidecast <- sub('src="audio.ogg">', paste0('src="data:audio/ogg;base64,',audio_str,'">'), slidecast)
}

