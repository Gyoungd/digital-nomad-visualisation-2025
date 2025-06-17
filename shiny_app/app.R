
# 1. Load Required Libraries
library(shiny)
library(dplyr) # For data manipulation
library(readr) # For Load Data

## Required for Choropleth Map Implementation
library(leaflet) # For interactive maps
library(sf) # For Choropleth Map (Spatial Features)

## Required for Bubble Plot
library(ggplot2)
library(plotly) # For interactive plots
library(RColorBrewer) # For using color palettes

## For Radar Chart 
library(fmsb)

## For Data Table
library(stringr) # For string manipulation to generate descriptive summary
library(DT)      # For interactive table

# 2. Load Data
# Main Dataset: Main Information per Country
df <- readRDS("final_dvp_dataset.rds")%>%
  mutate(across(where(is.numeric), ~ round(.x, 2))) # Round numeric values to 2 decimal places

# Region Summary Dataset for Choropleth Map Description
region_info <- read_csv("region_summary.csv")

# Feature Table Description for Interactive Table Summary
sentence_templates <- read_csv("feature_table_templates.csv", show_col_types = F)

# Set All Regions
all_regions <- unique(df$Region)

# 3. Define UI (CSS, Layout and Components)
ui <- fluidPage(
  # ------- Common Font/Background Styles -------
  tags$head(
    tags$script(src = "scroll.js"), # JavaScript for extra Side Navigation functionality
    tags$style(HTML("

      /* Font and Background */
      body {
        background-color: #0C3B2E;
        font-family: 'Roboto', sans-serif;
        font-size: 15px;
        line-height: 1.6;
        color: #FFFFFF;
      }
      h2, h3, h4 {
        font-family: 'Poppins', sans-serif;
        font-weight: 600;
        text-align: center;
        margin-top: 20px; 
        margin-bottom: 15px;
      }
      h2 { font-size: 32px; color: #FFBA00;}
      h3 { font-size: 25px; color: #FFFFFF;}
      h4 { font-size: 20px; color: #664a2d;}
      p { margin-bottom: 15px; }
      .container-fluid { padding-left: 30px; padding-right: 30px; }

      /* Info-block & Plot Style */
      .info-block {
        background-color: #F9F9F9;
        border-radius: 10px;
        padding: 15px;
        margin-bottom: 10px;
        color: #33343B;
        max-width: 1400px;
        box-shadow: 0 4px 10px rgba(71, 65, 88, 0.1);
      }
      .plot-container {
        background-color: #F9F9F9;
        border-radius: 10px;
        padding: 15px;
        max-height: 600px;
        margin: auto;
        box-shadow: 0 4px 10px rgba(71, 65, 88, 0.1);
      }

      /* DataTable */
      table.dataTable {
        background-color: #FFFFFF; color: #33343B; width: 100% !important;
      }
      table.dataTable th {
        background-color: #BDB1A3;
        color: #33343B; border-bottom: 2px solid #A77E56;
      }
      table.dataTable td {
        border-bottom: 1px solid #BDB1A3;
      }

      /* Table Description Highlight Style */
      .highlight { font-weight: bold; color: #0C3B2E; }
      .num { font-weight: bold; color: #C27446; }
      .cluster { font-style: italic; color: #8a6847; }

      /* Button Style */
      .btn { background-color: #FFBA00; color: #0C3B2E; border: none; font-weight: bold;}
      .btn:hover { background-color: #8a6847; color: #FFFFFF; }

      /* Select box/checkbox */
      .selectize-input, .selectize-dropdown { background-color: #FFFFFF; color: #33343B; border: 1px solid #BDB1A3;}
      .selectize-input.focus { border-color: #A4D4D4; }
       
       /* Feature Table Checkbox: White & Bold */
        .checkbox-feature-white .checkbox-inline,
        .checkbox-feature-white label.checkbox-inline {
          color: #FFF !important;
          font-weight: bold !important;
          display: inline-block !important;
          vertical-align: middle !important;
          margin-right: 15px;
          font-size: 16px;
        }
        .checkbox-feature-white input[type='checkbox']{
         margin-right: 7px !important;
         transform: scale(1.1);
        }
        .checkbox-feature-white{
         width: auto;
         display: flex !important;
         align-items: center !important;
         justify-content: flex-start !important;
        }


      /* Comparison summary */
      .comparison-summary-placeholder { font-size: 16px; font-weight: bold; color: #33343B; padding: 20px; }

      /* Side Navigation */
      #side-nav {
         position: fixed;
         top: 120px;  
         right: 0;
         width: 180px;
         background-color: #F9F9F9;
         color: #33343B;
         border-radius: 10px 0 0 10px;
         padding: 12px 10px;
         box-shadow: -3px 4px 8px rgba(0,0,0,0.15);
         z-index: 9999;
         transition: right 0.3s ease;
      }
      .nav-hidden{
        right: -160px !important;
      }
                          
      #nav-toggle {
        position: fixed;
        top: 120px;
        right:0;
        width: 24px;
        height:60px;
        background-color: #FFBA00;
        color: #0C3B2E;
        font-weight: bold;
        font-size: 18px;
        line-height: 60px;
        text-align: center;
        border-radius: 10px 0 0 10px;
        z-index: 10000;
        cursor: pointer;
        box-shadow: -2px 3px 6px rgba(0,0,0,0.2);
      }         
         
    "))
  ),
  
  # ------- Application Title -------
  div(class = "container-fluid",
      # Center-align of the page
      div(
        br(),
        h2("Explore and Compare Digital Nomad Destinations")
      ),
      
  # ------- Region Checkbox & Buttons -------
  fluidRow(
    
    column(12,
           # Title for Choropleth Map and Assign ID for Scrolling Bookmark
           div(id = "section1",
               h3("Worldwide Living Condition Overview"),
               style = "text-align: center; margin-bottom: 20px;"),
           
           div(
             style = "display: flex; align-items: center;
                      justify-content: center; gap:20px; margin-bottom:15px;
                      flex-wrap: wrap;",
             
             # Select Region Label
             tags$label("Select Region", style = "color: #FFFFF; font-weight: bold;
                        font-size: 20px; margin-right: 20px;"),
             # Checkbox
             div(
               class = "checkbox-feature-white",
               checkboxGroupInput(
                 "region_filter",
                 label = NULL,
                 choices = all_regions,
                 selected = all_regions,
                 inline =T
               ), style = "margin-top: 15px;"
             ),
             
             # Action Buttons
             actionButton("select_all_region", "Select All"),
             actionButton("clear_all_region", "Clear All Selection")
           )
        )
    ),
  
    # Render the Choropleth Map + Description
    fluidRow(
      # Mention about LCI Condition (Narrative Information)
      column(12,
             div(p(HTML("
               <p style = 'margin-top: 15px; margin-bottom:10px;'>
               * <b>Living Condition Index</b> represents a country's short-term living condition score
                     for digital nomads, combining internet speed, number of hotels and average hotel rates.</p>"))
             )
        ),
    
      # CHoropleth Map Output
      column(8, 
             div(leafletOutput("choropleth_map" , height = "480px"),
                 class = "plot-container")
        ),
    
      # Map Description Output
      column(4, div(uiOutput("map_desc"),
                    class = "info-block",
                    style = "
                          height: 480px;
                          overflow-y: auto;
                          display: flex;
                          flex-direction: column;
                          justify-content: flex-start;
                          margin-left: auto;
                          margin-right: auto;
                        "),
             
             # Scroll Function Instruction for User
             tags$p("↓ scroll for more information",
                    style = "
                      text-align: center;
                      font-size: 13px;
                      margin:0;
                      color: white;")
      ),
  
    # Data Sources used in the choropleth map    
    column(12,
           div(
             HTML("
                  <p style='font-size: 12px; margin-top: 10px;'>
                    <b>Data Source: </b>
                    Das, A. (n.d.). <i>Hotels Dataset</i>. Kaggle. Retrieved March 21, 2025, from <a href='https://www.kaggle.com/datasets/raj713335/tbo-hotels-dataset' target='_blank'>https://www.kaggle.com/datasets/raj713335/tbo-hotels-dataset</a><br>
                    <i>Ookla Speedtest Global Index (2017–2024)</i>. (n.d.). DataHub Cloud. Retrieved March 15, 2025, from 
        <a href='https://datahub.io/cheredia19/ookla-speedtest-global-index-fixed-broadband-2017-2024' target='_blank'>https://datahub.io/cheredia19/ookla-speedtest-global-index-fixed-broadband-2017-2024</a>
                  </p>
                ")
           )
         )
    ),
    
    fluidRow(column(12, br())),
  
    # ------- Bubble Plot + Radar Chart  -------
    
    # Title for Bubble Plot & Radar Chart and assign ID for Scrolling Bookmark
    fluidRow(
      column(7, id = "section2",
             div(h3("Compare Cost vs Living Feature Across Countries"),
                 style = "margin-left: 30px;")),
      column(5,
             div(h3("Detailed Feature Profile of Selected Country"),
                 style = "margin-right: 30px;"))
    ),
    
    # Filter for Bubble Plot/Radar Chart + Description
    fluidRow(
      column(7,
             div(style = "display: flex; align-items: center; margin-left: 155px;",
                 tags$label("Select Feature: ", style = "margin-right: 15px; color: #FFBA00; font-size: 20px;"),
                 div(selectInput("x_feature", label = NULL,
                                 choices = c("Internet Speed" = "Internet_Speed",
                                             "Hotel Rate" = "Hotel_Rate",
                                             "Temperature" = "Temperature",
                                             "Precipitation" = "Precipitation"),
                                 selected = "Internet_Speed",
                                 width = "200px"), style = "margin-top: 10px;"),
                 div(actionButton("reset_region", "Reset Region Filter"), style = "margin-left: 10px; margin-bottom: 5px;")
             )
      ),
      column(5,
             p("* Click a bubble in the bubble plot to explore the selected country's profile.",
               style = "font-style: italic;
                          margin-top: 20px;"))
      ),
    
    fluidRow(         
      # Render Bubble Plot  
      column(7,
             div(plotlyOutput("bubble_plot", height = "520px"),
                 class = "plot-container")
             
      ),
      
      # Render Radar Chart
      column(5,
             div(plotOutput("radar_chart", height = "520px"),
                 class = "plot-container")
      ),
      
      # Data Source used in Bubble plot and Radar Chart
      column(12,
             tags$details(
               tags$summary("⏵ Show Data Sources", style = "cursor: pointer; font-weight: bold; color: #FFDD00; margin-top: 10px;"),
               HTML("
                <p style='font-size: 12px; color: white; margin-top: 10px;'>
                  <b>Data Sources:</b><br>
                  Das, A. (n.d.). <i>Hotels Dataset</i>. Kaggle. Retrieved March 21, 2025, from 
                  <a href='https://www.kaggle.com/datasets/raj713335/tbo-hotels-dataset' target='_blank'>https://www.kaggle.com/datasets/raj713335/tbo-hotels-dataset</a><br>
          
                  <i>Internet cost ranking 2025—Global Relocate.</i> (2024, December 22). 
                  <a href='https://global-relocate.com/rankings/worldwide-data-pricing' target='_blank'>https://global-relocate.com/rankings/worldwide-data-pricing</a><br>
                  
                  <i>Monthly Average Surface Temperatures by Year</i>. (n.d.). Our World in Data. Retrieved March 15, 2025, from 
                  <a href='https://ourworldindata.org/grapher/monthly-average-surface-temperatures-by-year' target='_blank' >https://ourworldindata.org/grapher/monthly-average-surface-temperatures-by-year</a><br>
                  
                  Nadeem, M. (2024, July). <i>Global Cost of Living Rankings: Affordability Index</i>.
                  <a href='https://www.kaggle.com/datasets/marianadeem755/global-cost-of-living-rankingsaffordability-index' target='_blank'>https://www.kaggle.com/datasets/marianadeem755/global-cost-of-living-rankingsaffordability-index</a><br>
                  
                  <i>Ookla Speedtest Global Index (2017–2024)</i>. (n.d.). DataHub Cloud. Retrieved March 15, 2025, from 
                  <a href='https://datahub.io/cheredia19/ookla-speedtest-global-index-fixed-broadband-2017-2024' target='_blank'>https://datahub.io/cheredia19/ookla-speedtest-global-index-fixed-broadband-2017-2024</a><br>
          
                  <i>Yearly Average Relative Humidity (%)—Table—Geospa-al Data—Global Data Lab</i>. (n.d.). Global Data Lab. Retrieved March 15, 2025, from 
                  <a href='https://globaldatalab.org/geos/table/relhumidityyear/' target='_blank'>https://globaldatalab.org/geos/table/relhumidityyear/</a>
          
                  </p>")
                  )
             )
      ),
    
      # Bubble Plot Description 
      fluidRow(
        column(12, br(), # Add Line for whitespace
               div(
                 HTML(
                   "<p><strong>Use these interactive visualisations</strong> to explore how countries compare on cost and quality-of-life metrics.
                 The <strong>bubble plot</strong> (left) and <strong>radar chart</strong> (right) work together to help you identify optimal digital nomad destinations.</p>
                 
                 <ul>
                   <li><strong>🫧 Bubble Plot</strong>
                     <ul>
                       <li>X-axis: Selected Feature (e.g., Internet Speed)</li>
                       <li>Y-axis: <strong>Living Cost Index</strong> (<code>LCI_Cost</code>, <b>lower</b> is better)
                         <ul>
                           <li><em><strong>LCI_Cost = 0.5 × (Cost of Living + Rent) + 0.3 × Grocery Index + 0.2 × Restaurant Price Index</strong></em></li>
                         </ul>
                       </li>
                       <li>Bubble size: <strong>Living Condition Index</strong> (<code>LCI_Cond</code>, higher is better)</li>
                       <li>Click a bubble to see the detailed profile on radar chart</li>
                     </ul>
                   </li>
                   
                   <li><strong>🕸 Radar Chart</strong>
                     <ul>
                       <li>Displays 5 key features: <code>LCI_Cost</code>, <code>Hotel Rate</code>, <code>Internet Speed</code>, <code>Temperature</code>, <code>Precipitation</code></li>
                       <li>Only the selected country is shown</li>
                     </ul>
                   </li>
                 </ul>"
                 ),
                 
                 # Interactive Description based on the selected x feature
                 uiOutput("bubble_radar_desc"),
                 
                 class = "info-block",
                 style = "max-width: 1200px; margin: auto; padding: 15px;"
               )
        )
      ),
      
      fluidRow(column(12, br())),
  
      # ------- Feature Table -------
      # Title for Feature Table Section
      fluidRow(div(id = "section3",
                   h3("Compare and Decide: Digital Nomad Country Insights"))),
      
      # Filters
      fluidRow(
        column(12,
               div(
                 style = "display: flex; align-items: center; justify-content: space-between; gap: 10px; margin-bottom: 5px; flex-wrap: wrap;",
                 
                 # Feature Checkbox (inline)
                 div(
                   style = "display: flex; align-items: center; flex-wrap: wrap;",
                   tags$label("Select Features to Display: ", style = "color: #FFBA00; font-size: 20px; font-weight: bold; margin-right: 18px;"),
                
                div(class = "checkbox-feature-white",
                 checkboxGroupInput("feature_filter", label = NULL,
                                    choices = c(
                                      "Living Condition Cluster" = "Cluster_Cond",
                                      "Living Cost Cluster" = "Cluster_Cost",
                                      "Hotel Rate (1-5 star)" = "Hotel_Rate",
                                      "Internet Speed (Mbps)" = "Internet_Speed",
                                      "Average Temperature (°C)" = "Temperature",
                                      "Average Precipitation (mm)" = "Precipitation"
                                    ),
                                    selected = c("Cluster_Cond", "Cluster_Cost", "Hotel_Rate", 
                                                 "Internet_Speed", "Temperature", "Precipitation"),
                                    inline = T))
                                    
                 ),
                   
                 # Buttons
                div(
                  style = "display: flex; align-items: center; gap: 10px; margin-left: auto;",
                  actionButton("select_all_feature", "Select All"),
                  actionButton("clear_all_feature", "Clear All")
                )
               )
           )
      ),
      
      
      fluidRow(
        column(12,
               div(
                 style = "display: flex; justify-content: center; align-items: center;
                 gap: 15px; margin-top: 10px;",
                 
                 # Filter Name: Compare up to 3 countries
                 div(tags$label("Compare up to 3 Countries:"), style = "color: #FFBA00; font-size: 20px;"),
                 
                 # Select Comparison Countries (Max 3 Countries)
                 div(selectizeInput("compare_countries", label = NULL,
                                    choices = unique(df$Country),
                                    multiple = T,
                                    options = list(maxItems = 3)),
                     style = "margin-top: 10px;"),
                 
                 # Reset Button
                 actionButton("reset_compare", "Reset Comparison")

               )
            )
        ),
  
      # Render Feature Table
      fluidRow(div(style = "margin-top: 20px;",
                   # Left: Filter + Comparison Selection + Table
                   column(7,
                          
                          # Output of Interactive Table
                          div(uiOutput("feature_table_ui"), 
                              style = "max-height: 520px;",
                              class = "plot-container")
                          
                   ),
                   
                   # Right: Description
                   column(5,
                          h4("Comparison Summary", style = "color: #FFBA00; font-size: 20px;"),
                          div(class = "info-block",
                              style = "
                            min-height: 448px;
                            margin-left: auto;
                            margin-right: auto;
                            padding: 15px;
                          " ,
                              
                    # Fixed Introduction
                    div(class = "comparison-summary-placeholder" ,HTML("
                    <div style='line-height: 1.5; margin-bottom: 20px'>
                    <p><strong>Use this section to directly compare selected countries and make your final decision.</strong></p>
                    <ul style='font-style: italic; padding-left: 18px; margin-bottom: 0; font-weight: normal;'>
                      <li>Select features using the checkboxes above.</li>
                      <li>Choose up to 3 countries to compare.</li>
                      <li>A comparison table and summary will appear.</li>
                      <li>You can also search for a country using the search bar.</li>
                    </ul>
                  </div>
                ")),
                # Interactive Summary
                uiOutput("table_desc")
                )
         ),
                   
         # Data Source used in Feature Table
         column(12,
                div(
                  HTML("
                    <div style='background-color: #49662ed6; padding: 20px; border-radius: 8px; color: white; font-size: 13px;'>
                      <b>Data Sources Used in This Narrative Visualisation :</b><br><br>
              
                      Das, A. (n.d.). <i>Hotels Dataset</i>. Kaggle. Retrieved March 21, 2025, from 
                      <a href='https://www.kaggle.com/datasets/raj713335/tbo-hotels-dataset' target='_blank'>https://www.kaggle.com/datasets/raj713335/tbo-hotels-dataset</a><br>
              
                      <i>Internet cost ranking 2025—Global Relocate.</i> (2024, December 22). 
                      <a href='https://global-relocate.com/rankings/worldwide-data-pricing' target='_blank'>https://global-relocate.com/rankings/worldwide-data-pricing</a><br>
                      
                      <i>Monthly Average Surface Temperatures by Year</i>. (n.d.). Our World in Data. Retrieved March 15, 2025, from 
                      <a href='https://ourworldindata.org/grapher/monthly-average-surface-temperatures-by-year' target='_blank' >https://ourworldindata.org/grapher/monthly-average-surface-temperatures-by-year</a><br>
                      
                      Nadeem, M. (2024, July). <i>Global Cost of Living Rankings: Affordability Index</i>.
                      <a href='https://www.kaggle.com/datasets/marianadeem755/global-cost-of-living-rankingsaffordability-index' target='_blank'>https://www.kaggle.com/datasets/marianadeem755/global-cost-of-living-rankingsaffordability-index</a><br>
                      
                      <i>Ookla Speedtest Global Index (2017–2024)</i>. (n.d.). DataHub Cloud. Retrieved March 15, 2025, from 
                      <a href='https://datahub.io/cheredia19/ookla-speedtest-global-index-fixed-broadband-2017-2024' target='_blank'>https://datahub.io/cheredia19/ookla-speedtest-global-index-fixed-broadband-2017-2024</a><br>
              
                      <i>Yearly Average Relative Humidity (%)—Table—Geospa-al Data—Global Data Lab.</i>. (n.d.). Global Data Lab. Retrieved March 15, 2025, from 
                      <a href='https://globaldatalab.org/geos/table/relhumidityyear/' target='_blank'>https://globaldatalab.org/geos/table/relhumidityyear/</a>
                    </div>"),
                  style = "margin-top: 30px; margin-bottom: 20px;")
                ),
                   
         # Side Navigation Icon
         div(id = "nav-toggle", "❯", class = "nav-toggle"),
         
         div(id = "side-nav", class = "nav-hidden",
             
             tags$strong("Quick Navigation"),
             br(), br(),
             actionButton("goto1", "Region Explore Map", class = "btn btn-sm"),
             br(), br(),
             actionButton("goto2", "Country Explore", class = "btn btn-sm"),
             br(), br(),
             actionButton("goto3", "Country Comparison", class = "btn btn-sm")
         ),
         fluidRow(column(12, br()))
        ) 
      )
    )
  )
  


# Define server logic required to draw a histogram
server <- function(input, output, session) {
  
  # ------- Bubble Plot & Radar Chart Color setup -------
  country_vector <- unique(df$Country)
  base_colors <- RColorBrewer::brewer.pal(8, "Set1")
  filtered_base <- base_colors[base_colors != "#FFFF33"] # Exclude Yellow
  
  bubble_colors <- setNames(
    colorRampPalette(filtered_base)(length(country_vector)),
    country_vector
  )
  
  # ------- Region filter for map and bubble plot -------
  df_filtered <- reactive({
    regions <- input$region_filter
    if(is.null(regions) || length(regions) == 0) return(NULL)
    df %>% filter(Region %in% regions)
  })
  
  # ------- Select All & Reset Region Filter buttons (Map & bubble Plot)
  # Select All Regions
  observeEvent(input$select_all_region, {
    updateCheckboxGroupInput(
      session,
      inputId = "region_filter",
      selected = all_regions
    )
  })
  
  # Clear All Regions
  observeEvent(input$clear_all_region, {
    updateCheckboxGroupInput(
      session, inputId = "region_filter",
      selected = character(0)
    )
  })
  
  # Reset Region Filter for Bubble Plot
  observeEvent(input$reset_region, {
    updateCheckboxGroupInput(
      session,
      inputId = "region_filter",
      selected = all_regions
    )
  })
  
  
  
  # ------- Choropleth Map Output -------
  # Color palette for LCI_Cond on map
  map_colors <- c("#DAB194", "#d3a17e", "#74462a", "#4c281d", "#190e0a")

  pal <- colorBin(
    palette = map_colors,
    domain = df$LCI_Cond,
    bins = c(0, 0.15, 0.3, 0.45, 0.6, 0.8)
  )
  
  # Reactive Region Selection (Default NULL)
  select_region <- reactiveVal(NULL)
  
  # Render the interactive world choropleth map
  output$choropleth_map <- renderLeaflet({
    
    data_to_plot <- df_filtered()
    
    base_map <- leaflet(options = leafletOptions(wordlCopyJump = F)) %>%
      setMaxBounds(lng1 = -180, lat1= -40, lng2 = 180, lat2=65) %>%
      setView(lng = 20, lat = 20, zoom = 1.5) %>%
      addProviderTiles(providers$CartoDB.Positron)
    
    if(!is.null(data_to_plot)){
      base_map <- base_map %>%
        
        # Country Polygons filled colors based on LCI_Cond
        addPolygons(
          data = data_to_plot,
          fillColor = ~pal(LCI_Cond),
          weight = 1,
          # Boarder Color
          color = "#BDBDC3",
          opacity = 1,
          fillOpacity = .8,
          label = ~lapply(paste0("<strong>", Country, "</strong><br>",
                                 "Living Condition Index: ", round(LCI_Cond, 2)), HTML),
          labelOptions = labelOptions(direction = "auto"),
          highlightOptions = highlightOptions(
            weight = 2,
            color = "#666",
            fillOpacity = .9,
            bringToFront = T
          ),
          layerId = ~Country
        )
    }
    
    # Add Legend to base map and add "No Data"
    base_map <- base_map %>% addLegend(
      colors = c(map_colors, "#F2F2F2"),
      labels = c("0.00 – 0.15", "0.15 – 0.30", 
                 "0.30 – 0.45", "0.45 – 0.60", 
                 "0.60 – 0.80", "No Data"),
      title = "Living Condition Index (LCI)",
      position = "bottomleft"
    )
    
    # Return base map
    base_map
  })
  
  # Reactive Region Selection [Operation for Map]
  select_region <- reactiveVal(NULL)
  
  # ------- Map Description Output -------
  output$map_desc <- renderUI({
      selected_regions <- input$region_filter
      all_regions <- unique(df$Region)
      
      default_text <- default_text <- paste0(
        "<h4><strong>🌏 Digital Nomad Living Conditions</strong></h4>
          <p>This map shows the <b>Living Condition Index (LCI_Cond)</b>, based on internet
          speed and temporary accommodation conditions. Each country is colored according to its <b>LCI_Cond score</b>, where
          <b>darker shades</b> indicate <b>better</b> overall living conditions for digital nomads.<br><br>
          
          <b>Top Condition Regions</b>: <i>Western Europe, East Asia, Middle East</i><br>
          <b>Lower Condition Regions</b>: <i>Parts of Africa & Central Asia</i><br>
          
          To explore further:
          <li>🔎 Hover over a country to view exact values.</li>
          <li>🟤 The map uses a color-binned scaled based on continuous LCI scores, enabling clear interpretation of value ranges.</li><br>
          This map provides a <b>baseline global comparison</b> to help digital nomads explore region and countries with strong short-term livability infrastructure.
          "
      )
      
      # Cond1: If non of region is selected
      if (is.null(selected_regions) || length(selected_regions) == 0){
        return(HTML(default_text))
      }
      
      # Cond2: All Region is selected
      if (length(selected_regions) == length(all_regions) && all(selected_regions %in% all_regions)) {
        return(HTML(default_text))
      }
      
      # Cond3: If some regions are selected
      summaries <- region_info %>%
        filter(Region %in% selected_regions) %>%
        distinct(Region, Summary)
      
      # Connect Summary per Region
      summary_html <- paste0(
        "<p><strong>Selected Regions:</strong> ", paste(selected_regions, collapse = ", "), "</p>",
        paste0("<p><strong>", summaries$Region, "</strong> ", summaries$Summary, "</p>", collapse ="")
      )
      
      # Return the HTML content
      HTML(summary_html)
   })
  
  # ------- Bubble Plot Output -------
   output$bubble_plot <- renderPlotly({
      
      # 1. Filtered data based on selected region
      data_to_plot <- df_filtered()
      
      # 2. Mapping feature name to label
      feature_names <- list(
        Internet_Speed = "Internet Speed (Mbps)",
        Hotel_Rate = "Average Hotel Rate (1-5 Star)",
        Temperature = "Average Surface Temperature (°C)",
        Precipitation = "Average Precipitation (mm)"
      )
      
      # 3. Select x feautures
      x_feature <- input$x_feature
      x_label <- feature_names[[x_feature]]
      if (is.null(data_to_plot) || nrow(data_to_plot) == 0) {
        data_to_plot <- df
        x_feature <- "Internet_Speed"
        x_label <- feature_names[[x_feature]]
      }
      
      # 4. Create Tooltip 
      data_to_plot <- data_to_plot %>%
        mutate(tooltip = paste0(
          "Country: ", Country, "<br>",
          x_label, ": ", .data[[x_feature]], "<br>",
          "Living Condition Index: ", LCI_Cond, "<br>",
          "Living Cost Index: ", LCI_Cost
        ))
      
      # 5. Create ggplot
      p <- ggplot(data_to_plot, aes(
        x = .data[[x_feature]],
        y = LCI_Cost,
        size = LCI_Cond,
        fill = Country,
        text = tooltip,
        customdata = Country
      )) +
        geom_point(shape = 21, alpha = 0.75, stroke = 0.6, color = "black") +
        scale_fill_manual(values = bubble_colors) +
        theme_minimal()
      
      
      # 6. Main Plotly Plot for ggplotly
      main_plot <- ggplotly(p, tooltip = "text", config = list()) %>%
        layout(
          title = list(
            text = paste0("<b>Living Cost vs ", x_label, "</b>"),
            x = 0.5, y = 0.96,
            xanchor = "center",
            font = list(size = 18)
          ),
          xaxis = list(
            title = list(text = x_label, font = list(size = 14))
          ),
          yaxis = list(
            title = list(text = "Living Cost Index", font = list(size = 14))
          ),
          margin = list(t = 100, b = 100, l = 40, r = 40),
          legend = list(
            title = list(text = "  Country\n", font = list(size = 13)),
            y = 0.5
          ) 
        )
      
      # 7. Set up Size Legend (Bubble Legend)
      size_vals <- c(0.2, 0.4, 0.6, 0.8)
      bubble_size_px <- size_vals * 40
      
      size_legend <- plot_ly(
        x = 1:4, y = rep(1, 4),
        type = "scatter", mode = "markers+text",
        marker = list(size = bubble_size_px, color = "#999999"),
        text = as.character(size_vals),
        textposition = "middle right",
        showlegend = F,
        hoverinfo = "none"
      ) %>%
        layout(
          margin = list(t = 70),
          xaxis = list(
            title = "",
            showticklabels = F, showgrid = F, zeroline = F
          ),
          yaxis = list(
            showticklabels = F, showgrid = F, zeroline = F
          ),
          annotations = list(
            list(
              text = "Bubble Size: Living Condition Index (LCI)",
              x = 0.5, y = -0.4,
              xref = "paper", yref = "paper",
              showarrow = F,
              font = list(size = 13)
            )
          )
        )
      
      # Create Empty plot for preventing overlapping between main plot and bubble size legend
      empty_plot <- plotly_empty(type = "scatter", mode = "markers") %>%
        layout(
          xaxis = list(visible = F),
          yaxis = list(visible = F)
        )
      
      
      # 8. Combine main_plot + size_legend
      subplot(
        main_plot,
        empty_plot,
        size_legend,
        nrows = 3,
        heights = c(.8, .08,.12),
        shareX = F,
        titleX = T,
        titleY = T
      ) %>%
        layout(margin = list(b = 50))%>%
        config(
          displaylogo = F,
          modeBarButtonsToRemove = list("zoomIn2d", "zoomOut2d", "toImage")
        )
      
    })
    # ------ Bubble Click Operation ------
    # Selected country from bubble plot
    selected_country <- reactiveVal(NULL)
    
    # Observe Event for Bubble Click
    observeEvent(event_data("plotly_click"), {
      click <-  event_data("plotly_click")
      
      # Store the selected country from customdata(in bubble plot)
      if (!is.null(click) && !is.null(click$customdata)) {
        selected_country(click$customdata[1])
      } else {
        selected_country(NULL)
      }
    })
  
  
    # ------- Radar Chart Output -------
    # Default Radar Chart (Empty)
    output$radar_chart <- renderPlot({
      # Set the margin
      par(mar= c(2,2,3,2))
      
      # Chart Labels
      radar_labels <- c("Living Cost Index", "Hotel Rate",
                        "Internet Speed", "Temperature",
                        "Precipitation")
      
      
      if(is.null(selected_country()) || selected_country() == ""){
        
        # DataFrame for Empty Chart
        empty_df <- as.data.frame(rbind(rep(1,5),
                                        rep(0,5),
                                        rep(NA, 5)
        ))
        colnames(empty_df) <- radar_labels
        
        radarchart(empty_df, axistype = 1,
                   pcol = "grey", pfcol = adjustcolor("grey", alpha.f = .5),
                   plty = 1, plwd = 4, 
                   
                   # Grid style
                   cglcol = "#848787",cglwd=1.8, cglty = 1, axislabcol = "grey",
                   caxislabels = seq(0,1,.25),
                   
                   # Label
                   vlcex = 1.2, # Label Size
                   title = "Country Radar (No Country Selected)")
      } else{
        # DataFrame for Selected Country's Chart
        selected_country_data <- df %>%
          filter(Country == selected_country()) %>%
          select(LCI_Cost, norm_hotel_rate,
                 norm_internet_speed, norm_temp, norm_precip) %>%
          st_drop_geometry()
        
        radar_df <- as.data.frame(rbind(rep(1,5),
                                        rep(0,5),
                                        as.numeric(selected_country_data[1,])))
        
        colnames(radar_df) <- radar_labels
        
        # Radar chart with selected country data
        radarchart(radar_df,
                   axistype = 1,
                   
                   pcol = bubble_colors[[selected_country()]],
                   pfcol = adjustcolor(bubble_colors[[selected_country()]], alpha.f = .5),
                   plty = 1, plwd = 4,
                   
                   # Grid style
                   cglcol = "#848787", cglwd = 1.8, cglty = 1, axislabcol = "grey",
                   caxislabels = seq(0,1,.25),
                   
                   # Label
                   vlcex = 1.2, # Label Size
                   title = paste0(selected_country(), "'s Radar Chart")
        )
      }
    }) # radar_chart renderPlot End
    
    # ------ Bubble Plot & Radar Chart Description Output -------
    output$bubble_radar_desc <- renderUI({
      # Mapping Feature label
      feature_names <- list(
        Internet_Speed = "Internet Speed (Mbps)",
        Hotel_Rate = "Average Hotel Rate (1-5 Star)",
        Temperature = "Average Surface Temperature (°C)",
        Precipitation = "Average Precipitation (mm)"
      )
      
      x_label <- feature_names[[input$x_feature]]
      
      HTML(paste0(
        "Currently comparing: <b>", x_label, "</b> vs. <b>Living Cost Index (LCI_Cost)</b>.",
        "Bubble size reflects <b>Living Condition Index (LCI_Cond)</b> (livability score)."
      ))
    })
    
    # ------ Interactive Feature Table Output -------
    # feature_filter [Interactive Checkbox Operation]
    observeEvent(input$feature_filter, {
      # User must select at least 1 features
      req(length(input$feature_filter) >=1)
    })
    
    # select_all_feature
    observeEvent(input$select_all_feature, {
      updateCheckboxGroupInput(session, "feature_filter",
                               selected = c("Cluster_Cond", "Cluster_Cost", "Hotel_Rate", 
                                            "Internet_Speed", "Temperature", "Precipitation"))
    })
    
    # clear_all_feature
    observeEvent(input$clear_all_feature, {
      updateCheckboxGroupInput(session, "feature_filter", selected = c("Country", "Region"))
    })
    
    # reset_compare
    observeEvent(input$reset_compare,{
      updateSelectizeInput(
        session, inputId = "compare_countries", selected = character(0)
      )
    })
    
    # Render Interactive Feature Table (feature_table)
    output$feature_table <-  renderDT({
      
      req(length(input$feature_filter) >=1)
      
      base_cols <- c("Country", "Region")
      selected_cols <- input$feature_filter
      all_cols <- c(base_cols, selected_cols)
      
      display_names = c("Cluster_Cond" = "Living Condition Cluster",
                        "Cluster_Cost" = "Living Cost Cluster",
                        "Hotel_Rate" = "Hotel Rate (1-5 Star)",
                        "Internet_Speed" = "Internet Speed (Mbps)",
                        "Temperature" = "Average Temperature (°C)",
                        "Precipitation" = "Average Precipitation (mm)")
      
      
      # Numeric Columns for rounding
      numeric_cols <- c("Hotel_Rate", "Internet_Speed", "Temperature", "Precipitation")
      selected_numeric_cols <- intersect(selected_cols, numeric_cols)
      
      table_df <- df %>%
        select(all_of(all_cols)) %>%
        st_drop_geometry() %>%
        rename_with(~ display_names[.x], .cols = names(display_names)[names(display_names) %in% colnames(.)])
      
      if(!is.null(input$compare_countries) && length(input$compare_countries) > 0){
        table_df <- table_df %>%
          filter(Country %in% input$compare_countries)
      }
      
      datatable(
        table_df,
        options = list(scrollX = T, pageLength = 3,
                       fixedcolumns = list(leftColumns = 2)),
        rownames = F)
      
    })
    
    # ------ Country Comparison Input Operation ------
    output$feature_table_ui <- renderUI({
      if (length(input$feature_filter) < 1) {
        return(tags$p("Select features you want to compare.", style = "font-style: italic; color: #FFFFFF;"))
      }
      div(class = "plot-container", DTOutput("feature_table"))
    })
    
    # ------- Interactive Table Description Output -------
    # Get Sentence Template
    get_template <- function(feature, type, num_countries, extra_tag = NULL) {
      key <- if (type == "categorical" && num_countries == 2) extra_tag else as.character(num_countries)
      
      match_row <- sentence_templates %>%
        filter(feature == !!feature,
               type == !!type,
               num_countries == !!key)
      
      if (nrow(match_row) == 0) return(NA_character_)
      return(match_row$template[1])
    }
    
    
    generate_desc_from_template <- function(feature, df_sub){
      n <- nrow(df_sub)
      
      # Highlight Text Function
      highlight <-  function(text, class = "highlight"){
        paste0("<span class = '", class, "'>", text, "</span>")
      }
      
      # Define the feature types
      numeric_feats <- c("Internet_Speed", "Hotel_Rate", "Temperature", "Precipitation")
      categorical_feats <- c("Cluster_Cond", "Cluster_Cost")
      
      type <- if(feature %in% numeric_feats) "numeric"
      else if (feature %in% categorical_feats) "categorical"
      
      # Numeric Feature
      if(type == "numeric") {
        vals <- df_sub %>%
          select(Country, all_of(feature))
        
        colnames(vals)[2] <-  "val"
        
        if(n == 1){
          template <- get_template(feature, type, 1)
          str_interp(template, list(
            country = highlight(vals$Country[1]),
            val= highlight(vals$val[1], "num")
          ))
          
        } else if(n==2){
          a <- vals[1, ] # Country 1
          b <- vals[2, ] # Country 2
          if(a$val >= b$val){
            higher <-  a; lower <- b
          } else {
            higher <- b; lower <- a
          }
          
          template <- get_template(feature, type ,2)
          str_interp(template, list(
            country1 = highlight(higher$Country),
            country2 = highlight(lower$Country),
            val1 = highlight(higher$val, "num"),
            val2 = highlight(lower$val, "num")
          ))
        } else{
          top <- vals[which.max(vals$val), ]
          bottom <- vals[which.min(vals$val), ]
          
          template <- get_template(feature, type, "3+")
          str_interp(template, list(
            top_country = highlight(top$Country),
            top_val = highlight(top$val, "num"),
            bottom_country = highlight(bottom$Country),
            bottom_val = highlight(bottom$val, "num")
          ))
        }
      } 
      
      # Categorical Feature
      else if(type == "categorical"){
        cat_df <- df_sub %>%
          select(Country, .data[[feature]])
        
        colnames(cat_df)[2] <- "cluster"
        clusters <- unique(cat_df$cluster)
        
        if(n==1){
          template <- get_template(feature, type, 1)
          str_interp(template, list(
            country = highlight(cat_df$Country[1]),
            cluster = highlight(clusters[1],"cluster")
          ))
        } else if(n==2){
          if(length(clusters) == 1){
            template <- get_template(feature, type, 2, "2_same")
            str_interp(template, list(
              country1 = highlight(cat_df$Country[1]),
              country2 = highlight(cat_df$Country[2]),
              cluster = highlight(clusters[1],"cluster") 
            ))
          } else{
            template <- get_template(feature, type, 2, "2_diff")
            str_interp(template, list(
              country1 = highlight(cat_df$Country[1]),
              country2 = highlight(cat_df$Country[2]),
              cluster1 = highlight(cat_df$cluster[1], "cluster"),
              cluster2 = highlight(cat_df$cluster[2], "cluster")
            ))
          }
        } else {
          template <- get_template(feature, type, "3+")
          
          summary_text <- paste(apply(cat_df, 1, function(row){
            sprintf("%s (%s)", highlight(row["Country"]), highlight(row["cluster"], "cluster"))
          }), collapse = ", ")
          
          str_interp(template, list(
            country_group_summary = summary_text))
        }
      }
    }
    
    comparison_text <- function(df, selected_countries, seleced_features){
      # Connectors
      connectors <- c("First,", "In comparison,", "Additionally,", "Lastly,")
      
      # Define the feature type
      numeric_feats <- c("Internet_Speed", "Hotel_Rate", "Temperature", "Precipitation")
      categorical_feats <- c("Cluster_Cond", "Cluster_Cost")
      
      used_numeric_feats <- intersect(seleced_features, numeric_feats)
      used_categorical_feats <- intersect(seleced_features, categorical_feats)
      
      # Maximum Features
      max_feats_to_display <- 3
      total_feats <- c(used_numeric_feats, used_categorical_feats)
      
      if(length(total_feats) > max_feats_to_display){
        difference <-  sapply(used_numeric_feats, function(feat){
          vals <- df %>%
            filter(Country %in% selected_countries) %>%
            pull(feat)
          max(vals) - min(vals)
        })
        rank_numeric <- names(sort(difference, decreasing = T))
        top_numeric <-  head(rank_numeric, max_feats_to_display)
        remain_slots <- max_feats_to_display - length(top_numeric)
        top_categorical <- head(setdiff(used_categorical_feats, remain_slots), remain_slots)
        used_feats <- c(top_numeric, top_categorical)
      } else{
        used_feats <- total_feats
      }
      
      # Generate Paragraph
      df_sub <- df %>%
        filter(Country %in% selected_countries)
      
      paragraph <- mapply(function(i, feat){
        connector <- ifelse(i <= length(connectors), connectors[i], "")
        sentence <- generate_desc_from_template(feat, df_sub)
        paste(connector, sentence)
      }, seq_along(used_feats), used_feats, SIMPLIFY = T)
      
      paste(paragraph, collapse = " ")
    }
    
    # Render Comparison Summary
    output$table_desc <- renderUI({
      if(length(input$compare_countries) == 0 || length(input$feature_filter) == 0 ||
         is.null(input$compare_countries) || is.null(input$feature_filter)){
        return(NULL)
      } else {
        div(style = "line-height: 1.6; margin-top:10px;", 
            HTML(comparison_text(df, input$compare_countries, input$feature_filter)))
      }
    })
    
    # Observe Navigation Buttons
    observeEvent(input$goto1, {
      session$sendCustomMessage("scrollTo", "section1")
    })
    observeEvent(input$goto2, {
      session$sendCustomMessage("scrollTo", "section2")
    })
    observeEvent(input$goto3, {
      session$sendCustomMessage("scrollTo", "section3")
    })
    
}

# Run the application 
shinyApp(ui = ui, server = server)
