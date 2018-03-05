#' Shiny app server function
#'
#' @param input provided by shiny
#' @param output provided by shiny
#'


# Define server logic required to draw a histogram
shinyAppServer <- function(input, output) {

  output$distPlot <- renderPlot({
    # generate bins based on input$bins from ui.R
    x    <- datasets::"faithful"[, 2]
    bins <- seq(min(x), max(x), length.out = input$bins + 1)

    # draw the histogram with the specified number of bins
    hist(x, breaks = bins, col = 'darkgray', border = 'white')
  })
}
