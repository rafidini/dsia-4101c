#
# This script contains the user interface code.
#

# Define UI for application that draws a histogram
body <- dashboardBody(
  
  # Different pages
  tabItems(
    # Obesity page
    tabItem(
      tabName = "obesity",
      
      # Title
      h2(strong("Obesity")),
      
      # Content
      tabBox(
        title = icon('hippo'),
        width = 12,
        
        id = "tbx",
        
        # Content for global data
        tabPanel(
          title = "Yearly",
          # Subtitle for picker
          h4(strong("Select a year to visualize")),
          
          # Picker for the year
          box(
            width = 12,
            status = "primary",
            sliderInput(
              inputId = 'year',
              label = 'Year',
              min = min(obesity$year),
              max = max(obesity$year),
              value = min(obesity$year),
              step = 1
            ),
          ),
          
          
          # Subtitle
          h4(strong(textOutput("year_out_aroundworld"))),
          
          # Around the world Content
          fluidRow(
            # Box for the percentage of obesity in the world
            valueBoxOutput('obesity_B_year'),
            
            # Box for the percentage of obesity in the world for men
            valueBoxOutput('obesity_M_year'),
            
            # Box for the percentage of obesity in the world for women
            valueBoxOutput('obesity_F_year')
          ),
          
          # Next Subtitle (2)
          h4(strong(textOutput("year_out_spatiotemporal"))),
          
          # Obesity in spatiotemporaldimension Content
          fluidRow(
            box(
              width = 12,
              status = "info",
              column(
                width = 12,
                # Map
                leafletOutput("map", height = 750)
              ),
            ),
          ),
          
          # Distribution of obesity 
          fluidRow(
            box(
              width = 2,
              status = "primary",
              
              # Radio input for sex
              radioButtons(
                inputId = 'radio_distribution_obesity_year',
                label = "Select a sex to display",
                choices = c("Males" = "M", "Females" = "F", "Both" = "B"),
                selected = "B",
              )
            ),
            
            box(
              width = 10,
              status = "success",
              
              # Title for the histogram 
              h4(strong(textOutput("distribution_title_obesity_year"))),
              
              # Histogram
              plotOutput('distribution_obesity_year')
              
            )
          ),
        ),
        
        # Content for selected data
        tabPanel(
          title = "Selected",
          
          # Widgets allowing the user to choose a group
          fluidRow(
            box(
              width = 6,
              status = "primary",
              column(
                width = 12,
                h4(strong("What?")),
                radioButtons(
                  label = "Select the group",
                  inputId = 'group',
                  choices = c(
                    "Continents",
                    "Countries"
                  )
                )
              )
            ),
            
            # Widgets allowing the user to choose a sub-group 
            box(
              width = 6,
              status = "primary",
              column(
                width = 12,
                h4(strong("Where?")),
                uiOutput('group_out'),
                
                # Radio buttons or nothing
                uiOutput('plot_option_plot_type_selected'),
              )
            ),
          ),
          
          fluidRow(
            box(
              width = 12,
              status = "primary",
              
              # Range input
              h4(strong("When?")),
              sliderInput(
                'slider_year_selected',
                label = "Select the interval",
                min = min(obesity$year),
                max = max(obesity$year),
                step = 1,
                round = TRUE,
                value = c(1990, 2005)
              ),
            ),
          ),
          
          # Box containing one plot
          fluidRow(
            # Basic lineplot of obesity for
            box(
              status = "success",
              width = 12,
              
              # Title
              div(
                span(
                  textOutput('choice_selected', inline = TRUE),
                  style = "font-size:18px;font-weight:bold;"
                ),
                span(
                  textOutput('difference_selected', inline = TRUE),
                  style = "font-size:14px;vertical-align: super;color:red;font-style:bold;"
                )
                
              ),
              
              # Plot
              column(
                width = 12,
                
                # Plot for obesity in country in a given range
                plotOutput("plot_country", height = 650)
              ),
            ),
          )
        ),
        
        tabPanel(
          title = "Raw data",
          
          dataTableOutput('obesity_raw')
        )
      )
      
    ),
    
    # Employment page
    tabItem(
      tabName = "employment",
      
      # Title
      h2(strong("Employment")),
      
    ),
    
    # Obesity & Employment page
    tabItem(
      tabName = "obesity_employment",
      
      # Title
      h2(strong("Analytics")),
      
      tabBox(
        width = 12,
        tabPanel(
          title = "By country",
          
          valueBoxOutput("correlation_desk_analytics", width = 6),
          valueBoxOutput("correlation_manual_analytics", width = 6),
          
          # Left side
          fluidRow(
            width = 12,
            
            column(
              width = 9,
              
              box(
                width = 12,
                status = "success",
                
                h4(strong(textOutput("correlation_title_plot"))),
                
                plotOutput('correlation_plot', height = 600),
              )
            ),
            
            # Right side
            column(
              width = 3,
              
              # Select input for countries
              box(
                width = 12,
                status = "primary",
                
                selectInput(
                  'select_country_analytics',
                  label = "Choose a country",
                  choices = unique(analytics$country),
                  selected = "France"
                )
              ),
            )
          )
        ),
        
        tabPanel(
          title = "Overall",
          
          span(
            "Heatmap of correlation between obesity and desk/manual jobs",
            style = "font-size:18px;font-weight:bold;"
          ),
          
          plotOutput('heatmap_correlation_analytics')
        )
      )
    )
  )
)


header <- dashboardHeader(
  title = "Menu"
)

sidebar = dashboardSidebar(
  # Menu
  sidebarMenu(
    menuItem("Obesity", tabName = "obesity", icon = icon("hippo")),
    menuItem("Employment", tabName = "employment", icon = icon("suitcase")),
    menuItem("Analytics", tabName = "obesity_employment", icon = icon("users"))
  )
)

ui <- dashboardPage(
  
  # Theme of the app
  skin = "purple",
  
  # Skeleton
  header,
  sidebar,
  body
)
