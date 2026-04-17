# =============================================================================
# Medicaid Expansion Dashboard
# app.R — shinyapps.io deployment
#
# Required file structure:
#   app.R
#   data/
#     map_summary.rds
#     fpl_coverage_df.rds
#     avg_df.rds
# =============================================================================

# =============================================================================
# Libraries
# =============================================================================
library(shiny)
library(shinyjs)
library(leaflet)
library(tidyverse)
library(scales)
library(bslib)
library(plotly)

# =============================================================================
# Data
# =============================================================================

map_summary     <- readRDS("data/map_summary.rds")
fpl_coverage_df <- readRDS("data/fpl_coverage_df.rds")
avg_df          <- readRDS("data/avg_df.rds")
map_sf <- readRDS("data/map_sf.rds")

# =============================================================================
# Constants
# =============================================================================

EXPANSION_COLORS <- c(
  "Expansion"     = "#0342A1",
  "Non-Expansion" = "#C6010B"
)

COVERAGE_COLORS <- c(
  insured   = "#2c7bb6",
  private   = "#74add1",
  public    = "#abd9e9",
  uninsured = "#d7191c"
)

PLOT_TEXT  <- "#000000"
GRID_COLOR <- "#cccccc"

exp_pal <- colorFactor(
  palette = EXPANSION_COLORS,
  levels  = names(EXPANSION_COLORS)
)

# =============================================================================
# Helper Functions
# =============================================================================

dark_axis <- function(title = "", tickformat = NULL, range = NULL, suffix = NULL) {
  ax <- list(
    title     = title,
    gridcolor = GRID_COLOR,
    tickfont  = list(color = PLOT_TEXT)
  )
  if (!is.null(tickformat)) ax$tickformat <- tickformat
  if (!is.null(range))      ax$range      <- range
  if (!is.null(suffix))     ax$ticksuffix <- suffix
  ax
}

state_expansion_color <- function(expansion) {
  if (expansion == 1) EXPANSION_COLORS["Expansion"] else EXPANSION_COLORS["Non-Expansion"]
}

# =============================================================================
# CSS
# =============================================================================

value_box_css <- HTML("
  .bslib-value-box                 { background-color: transparent !important; }
  .bslib-value-box .value-box-grid { background-color: transparent !important; }
  .bslib-value-box.bg-danger       { background-color: transparent !important; border: 1px solid #dc3545; }
  .bslib-value-box.bg-warning      { background-color: transparent !important; border: 1px solid #ffc107; }
  .bslib-value-box.bg-info         { background-color: transparent !important; border: 1px solid #0dcaf0; }
  .bslib-value-box.bg-primary      { background-color: transparent !important; border: 1px solid #0d6efd; }
  .bslib-value-box .value-box-title,
  .bslib-value-box .value-box-value { color: #000000 !important; }
")

# =============================================================================
# UI
# =============================================================================

ui <- fluidPage(
  theme = bs_theme(bootswatch = "morph"),
  tags$style(value_box_css),
  useShinyjs(),
  tags$h2(
    "Medicaid Expansion & Insurance Coverage in the United States",
    style = "padding: 15px 0px 10px 15px; font-weight: 600;"
  ),
  
  # Map
  leafletOutput("state_map", height = "750px"),
  br(),
  
  # Prompt shown when no state is selected
  div(id = "no_selection",
      p("Click a state on the map to view insurance coverage statistics.",
        style = "color: #888; font-style: italic; text-align: center; padding: 20px;")
  ),
  
  # State detail panel — hidden until a state is clicked
  hidden(
    div(id = "state_detail",
        
        uiOutput("sidebar_title"),
        br(),
        
        # Summary value boxes
        fluidRow(
          column(3, uiOutput("box_uninsured")),
          column(3, uiOutput("box_uninsured_li")),
          column(3, uiOutput("box_pubcov")),
          column(3, uiOutput("box_privcov"))
        ),
        br(),
        
        # Coverage breakdown + all vs low income
        fluidRow(
          column(6, plotlyOutput("coverage_bar", height = "280px")),
          column(6, plotlyOutput("income_plot",  height = "280px"))
        ),
        br(),
        
        # Uninsured rate by FPL
        fluidRow(
          column(12, plotlyOutput("poverty_plot", height = "350px"))
        ),
        br(),
        
        actionButton("clear", "← Clear")
    )
  )
)

# =============================================================================
# Server
# =============================================================================

server <- function(input, output, session) {
  
  # --- State selection --------------------------------------------------------
  
  selected_state <- reactiveVal(NULL)
  
  observeEvent(input$state_map_shape_click, {
    selected_state(input$state_map_shape_click$id)
    hideElement("no_selection")
    showElement("state_detail")
  })
  
  observeEvent(input$clear, {
    selected_state(NULL)
    hideElement("state_detail")
    showElement("no_selection")
  })
  
  # Filtered map_summary row for selected state
  selected_row <- reactive({
    req(selected_state())
    map_summary |> filter(STATE == selected_state())
  })
  
  # --- Map --------------------------------------------------------------------
  
  output$state_map <- renderLeaflet({
    leaflet(map_sf) |>
      addProviderTiles(providers$CartoDB.VoyagerNoLabels) |>
      setView(lng = -96, lat = 37.8, zoom = 4) |>
      addPolygons(
        fillColor        = ~exp_pal(expansion_name),
        fillOpacity      = 0.7,
        color            = "#000000",
        weight           = 1.5,
        highlightOptions = highlightOptions(
          weight = 3, color = "#ffffff", fillOpacity = 0.9, bringToFront = TRUE
        ),
        label   = ~paste0(state_name, " — ", expansion_name,
                          " | Uninsured: ", percent(uninsured_rate, accuracy = 0.1)),
        layerId = ~STATEFP
      ) |>
      addLegend(
        position = "bottomright",
        pal      = exp_pal,
        values   = ~expansion_name,
        title    = "Expansion Status"
      )
  })
  
  # --- Header -----------------------------------------------------------------
  
  output$sidebar_title <- renderUI({
    row <- selected_row()
    h4(row$state_name, " — ", row$expansion_name)
  })
  
  # --- Value boxes ------------------------------------------------------------
  
  output$box_uninsured <- renderUI({
    row <- selected_row()
    value_box("Uninsured Rate (Total)", percent(row$uninsured_rate, accuracy = 0.1),
              theme = "danger", height = "100px")
  })
  
  output$box_uninsured_li <- renderUI({
    row <- selected_row()
    value_box("Uninsured (Low Income)", percent(row$uninsured_rate_li, accuracy = 0.1),
              theme = "warning", height = "100px")
  })
  
  output$box_pubcov <- renderUI({
    row <- selected_row()
    value_box("Public Coverage", percent(row$pubcov_rate, accuracy = 0.1),
              theme = "info", height = "100px")
  })
  
  output$box_privcov <- renderUI({
    row <- selected_row()
    value_box("Private Coverage", percent(row$privcov_rate, accuracy = 0.1),
              theme = "primary", height = "100px")
  })
  
  # --- Coverage breakdown bar chart -------------------------------------------
  
  output$coverage_bar <- renderPlotly({
    row <- selected_row()
    
    tibble(
      category = c("Insured", "Private", "Public", "Uninsured"),
      rate     = c(row$insured_rate, row$privcov_rate, row$pubcov_rate, row$uninsured_rate),
      color    = unname(COVERAGE_COLORS)
    ) |>
      plot_ly(
        x            = ~rate,
        y            = ~category,
        type         = "bar",
        orientation  = "h",
        marker       = list(color = ~color),
        text         = ~percent(rate, accuracy = 0.1),
        textposition = "outside",
        hoverinfo    = "none"
      ) |>
      layout(
        paper_bgcolor = "transparent",
        plot_bgcolor  = "transparent",
        font          = list(color = PLOT_TEXT),
        title         = list(text = "Coverage Breakdown",
                             font = list(size = 13, color = PLOT_TEXT)),
        xaxis         = dark_axis(tickformat = ".0%", range = c(0, 1.15)),
        yaxis         = dark_axis(),
        showlegend    = FALSE,
        margin        = list(l = 10, r = 40, t = 30, b = 10)
      )
  })
  
  # --- Uninsured: all vs low income -------------------------------------------
  
  output$income_plot <- renderPlotly({
    row <- selected_row()
    
    tibble(
      group = c("All Residents", "Low Income"),
      rate  = c(row$uninsured_rate, row$uninsured_rate_li),
      color = c(COVERAGE_COLORS["private"], COVERAGE_COLORS["uninsured"])
    ) |>
      plot_ly(
        x            = ~group,
        y            = ~rate,
        type         = "bar",
        marker       = list(color = ~color),
        text         = ~percent(rate, accuracy = 0.1),
        textposition = "outside",
        hoverinfo    = "none"
      ) |>
      layout(
        paper_bgcolor = "transparent",
        plot_bgcolor  = "transparent",
        font          = list(color = PLOT_TEXT),
        title         = list(text = "Uninsured: All vs Low Income",
                             font = list(size = 13, color = PLOT_TEXT)),
        xaxis         = dark_axis(),
        yaxis         = dark_axis(
          title      = "Uninsured Rate",
          tickformat = ".0%",
          range      = c(0, max(row$uninsured_rate_li, row$uninsured_rate) * 1.3)
        ),
        showlegend    = FALSE,
        margin        = list(l = 10, r = 10, t = 30, b = 10)
      )
  })
  
  # --- Uninsured rate by FPL --------------------------------------------------
  
  output$poverty_plot <- renderPlotly({
    row        <- selected_row()
    state_data <- fpl_coverage_df |> filter(STATE == selected_state())
    
    plot_ly() |>
      add_lines(
        data          = avg_df,
        x             = ~bin_mid,
        y             = ~avg_uninsured,
        line          = list(color = "rgba(100,100,100,0.5)", width = 2, dash = "dot"),
        name          = "National Average",
        hovertemplate = "FPL: %{x}%<br>National Avg: %{y:.1%}<extra></extra>"
      ) |>
      add_lines(
        data          = state_data,
        x             = ~bin_mid,
        y             = ~uninsured_rate,
        line          = list(color = state_expansion_color(row$expansion), width = 3),
        name          = row$state_name,
        hovertemplate = "FPL: %{x}%<br>Uninsured Rate: %{y:.1%}<extra></extra>"
      ) |>
      add_segments(
        x         = 138, xend = 138,
        y         = 0,   yend = 1,
        line      = list(color = "#555555", dash = "dash", width = 1),
        name      = "Medicaid Cutoff (138% FPL)",
        hoverinfo = "none"
      ) |>
      layout(
        paper_bgcolor = "transparent",
        plot_bgcolor  = "transparent",
        font          = list(color = PLOT_TEXT),
        title         = list(text = paste0("Uninsured Rate by Poverty Level — ", row$state_name),
                             font = list(size = 13, color = PLOT_TEXT)),
        xaxis         = dark_axis(title = "Federal Poverty Level (%)", range = c(0, 500), suffix = "%"),
        yaxis         = dark_axis(title = "Uninsured Rate", tickformat = ".0%", range = c(0, 1)),
        legend        = list(orientation = "h", y = -0.2, font = list(color = PLOT_TEXT)),
        margin        = list(l = 10, r = 10, t = 40, b = 10)
      )
  })
}

# =============================================================================
# Run
# =============================================================================

shinyApp(ui, server)