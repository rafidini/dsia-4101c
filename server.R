#
# This script contains the code for the server.
#

# Define server logic required to build interactive user interface
server <- function(input, output) {
  
  # Obesity : Yearly
  output$map <- renderLeaflet({ obesityMapByYear(input$year) })
  output$top_obesity <- renderPlot({
    ggplot(
      obesity %>% 
        filter(sex == 'B', year == input$year) %>%
        select(country, obesity) %>%
        arrange(desc(obesity)) %>%
        top_n(10)
      , 
      aes(x = country, y = obesity, fill = country)
    ) + 
      geom_bar(stat = 'identity', width= .90) + 
      coord_flip()
  })
  output$year_out_spatiotemporal <- renderText({ paste0("World map of obesity percentage in ", input$year) }) # Title
  output$year_out_aroundworld <- renderText({ paste0("Facts about obesity around the world in ", input$year) }) # Title
  output$obesity_F_year <- renderValueBox({
    shinydashboard::valueBox(
      meanObesityByYearSex(input$year, 'F'),
      subtitle = "Obesity around the globe for women",
      icon = icon("venus"),
      color = "fuchsia",
      width = 4,
    )
  })
  output$obesity_B_year <- renderValueBox({
    shinydashboard::valueBox(
      meanObesityByYearSex(input$year, 'B'),
      subtitle = "Obesity around the globe",
      icon = icon("globe"),
      color = "light-blue",
      
    )
  })
  output$obesity_M_year <- renderValueBox({
    shinydashboard::valueBox(
      meanObesityByYearSex(input$year, 'M'),
      subtitle = "Obesity around the globe for men",
      icon = icon("mars"),
      color = "blue",
      width = 4,
    )
  })
  output$distribution_title_obesity_year <- renderText({
    paste0(
      "Distribution of obesity percentage among ",
      sexToTitle(input$radio_distribution_obesity_year),
      " in  ",
      input$year
    )
  })
  output$distribution_obesity_year <- renderPlot({
    ggplot(obesityDistribution(input$year, input$radio_distribution_obesity_year), aes(x = obesity)) +
      geom_histogram(aes( color = sex, fill = sex), bins = 35, position ="identity", alpha = 0.25) +
      scale_color_manual(values = c("M" = "blue", "F" = "red"), labels = c("M" = "Males", "F" = "Females")) +
      scale_fill_manual(values = c("M" = "blue", "F" = "red"), labels = c("M" = "Males", "F" = "Females")) +
      labs(
        x = "Obesity (%)",
        y = "Distribution"
      ) +
      theme(
        panel.background = element_rect(fill = "white", colour = "black"),
        axis.title.x = element_text(size = 14, face = "bold"),
        axis.title.y = element_text(size = 14, face = "bold"),
      ) 
  })
  
  # Obesity : Selected
  output$group_out <- renderUI({
    selectInput(
      inputId = 'choice',
      label = input$group,
      choices = if (input$group=="Continents") { unique(obesity$continent) } else { unique(obesity$country) },
      selected = if (input$group=="Continents") { 'Asia' } else { 'France' }
    )
    
  })
  output$difference_selected <- renderText({
    if(input$group == "Countries")
      obesityCountryDifferenceInterval(input$choice, input$slider_year_selected[1], input$slider_year_selected[2])
    else
      " "
  })
  output$choice_selected <- renderText({
    paste0('Obesity (%) for men and women in ', input$choice)
  })
  output$plot_country <- renderPlot({
    if(input$plot_option_type_selected == "single" | input$group == "Countries"){
      ggplot( obesityByGroupSingle(input$group, input$choice, input$slider_year_selected[1], input$slider_year_selected[2]), aes(x=year, y=obesity, color=sex)) + 
        geom_point() + 
        geom_smooth() + 
        labs(
          subtitle = paste0("From ", paste0( input$slider_year_selected[1], paste0(" to ", input$slider_year_selected[2]))),
          x = "Year",
          y = "Obesity (%)",
          color = "Sex"
        ) +
        theme(
          legend.title = element_text(size = 14, face = "bold"),
          legend.text = element_text(size = 12),
          axis.title.x = element_text(size = 14, face = "bold"),
          axis.title.y = element_text(size = 14, face = "bold"),
        ) +
        #theme_linedraw() +
        scale_colour_discrete(
          name = "Sex",
          breaks = c("F", "M", "B"),
          labels = c("Females", "Males", "Both sexes")
        ) +
        scale_color_manual(
          labels = c("Women", "Men", "Both"),
          values = c("#FF6969", "#52D4FF", "#46C267")
        )
    }
    else if(input$plot_option_type_selected == "multiple"){
      ggplot(obesityByGroupMultiple(input$choice, input$slider_year_selected[1], input$slider_year_selected[2]), aes(x=year, y=obesity, color=country)) +
        geom_point() +
        geom_smooth() +
        theme(legend.position="bottom") +
        labs(
          subtitle = paste0("From ", paste0( input$slider_year_selected[1], paste0(" to ", input$slider_year_selected[2]))),
          x = "Year",
          y = "Obesity (%)",
          color = "Country"
        ) +
        theme(
          legend.title = element_text(size = 14, face = "bold"),
          legend.text = element_text(size = 12),
          axis.title.x = element_text(size = 14, face = "bold"),
          axis.title.y = element_text(size = 14, face = "bold"),
        )
    }
  })
  output$plot_option_plot_type_selected <- renderUI({
    if (input$group == "Continents"){
      radioButtons(
        'plot_option_type_selected',
        label = "Plot type",
        selected = "single",
        choiceNames = c("Whole continent", "Every countries"),
        choiceValues = c("single", "multiple")
      )
    }
  })
  
  # Obesity : Raw data
  output$obesity_raw <- renderDataTable({obesity})
  
  # Employment : Yearly
  output$map_E <- renderLeaflet({ employmentMapByYear(input$year_E,input$radio_type_employment) }) 
  output$top_employment <- renderPlot({
    ggplot(
      employment %>% 
        filter(sex == 'B', year == input$year_E) %>%
        select(country, value) %>%
        arrange(desc(value)) %>%
        top_n(10)
      , 
      aes(x = country, y = value, fill = country)
    ) + 
      geom_bar(stat = 'identity', width= .90) + 
      coord_flip()
  })
  output$year_out_spatiotemporal_E <- renderText({ paste0("World map of manual percentage in ", input$year_E) }) # Title
  output$year_out_aroundworld_E <- renderText({ paste0("Facts about manual around the world in ", input$year_E) }) # Title
  output$employment_F_year <- renderValueBox({
    shinydashboard::valueBox(
      meanEmploymentByYearSex(input$year_E, 'F', input$radio_type_employment),
      subtitle = "Employment around the globe for women",
      icon = icon("venus"),
      color = "fuchsia",
      width = 4,
    )
  })
  output$employment_B_year <- renderValueBox({
    shinydashboard::valueBox(
      meanEmploymentByYearSex(input$year_E, 'B',input$radio_type_employment),
      subtitle = "Employment around the globe",
      icon = icon("globe"),
      color = "light-blue",
      
    )
  })
  output$employment_M_year <- renderValueBox({
    shinydashboard::valueBox(
      meanEmploymentByYearSex(input$year_E, 'M',input$radio_type_employment),
      subtitle = "Employment around the globe for men",
      icon = icon("mars"),
      color = "blue",
      width = 4,
    )
  })
  output$distribution_title_employment_year <- renderText({
    paste0(
      "Distribution of manual percentage among ",
      sexToTitle(input$radio_distribution_employment_year_S),
      " in  ",
      input$year_E
    )
  })
  output$distribution_employment_year <- renderPlot({
    ggplot(employmentDistribution(input$year_E, input$radio_distribution_employment_year_S, input$radio_type_employment), aes(x = value)) +
      geom_histogram(aes( color = sex, fill = sex), bins = 35, position ="identity", alpha = 0.25) +
      scale_color_manual(values = c("M" = "blue", "F" = "red"), labels = c("M" = "Males", "F" = "Females")) +
      scale_fill_manual(values = c("M" = "blue", "F" = "red"), labels = c("M" = "Males", "F" = "Females")) +
      labs(
        x = if (input$radio_type_employment == "M") "Manual" else "Desk",
        y = "Distribution"
      ) +
      theme(
        panel.background = element_rect(fill = "white", colour = "black"),
        axis.title.x = element_text(size = 14, face = "bold"),
        axis.title.y = element_text(size = 14, face = "bold"),
      ) 
  })
  
  # Employment : Selected
  output$group_out_E <- renderUI({
    selectInput(
      inputId = 'choice_E',
      label = input$group_E,
      choices = if (input$group_E=="Continents") { unique(employment$continent) } else { unique(employment$country) },
      selected = if (input$group_E=="Continents") { 'Asia' } else { 'France' }
    )
    
  })
  output$difference_selected_E <- renderText({
    if(input$group_E == "Countries")
      employmentCountryDifferenceInterval(input$choice_E, input$slider_year_selected_E[1], input$slider_year_selected_E[2],input$radio_type_employment_S)
    else
      " "
  })
  output$choice_selected_E <- renderText({
    paste0('Employment for men and women in ', input$choice_E)
  })
  output$plot_country_E <- renderPlot({
    if(input$group_E == "Countries"){
      ggplot( employmentByGroupSingle(input$group_E, input$choice_E, input$slider_year_selected_E[1], input$slider_year_selected_E[2],input$radio_type_employment_S), aes(x=year, y=value)) + 
        geom_point() + 
        geom_smooth() + 
        labs(
          subtitle = paste0("From ", paste0( input$slider_year_selected_E[1], paste0(" to ", input$slider_year_selected_E[2]))),
          x = "Year",
          y = if (input$radio_type_employment_S == 'M') "Manual" else "Desk"
          
        ) +
        theme(
          legend.title = element_text(size = 14, face = "bold"),
          legend.text = element_text(size = 12),
          axis.title.x = element_text(size = 14, face = "bold"),
          axis.title.y = element_text(size = 14, face = "bold"),
        ) 
      
    }
    else {
      ggplot(employmentByGroupMultiple(input$choice_E, input$slider_year_selected_E[1], input$slider_year_selected_E[2],input$radio_type_employment_S), aes(x=year, y=value, color=country)) +
        geom_line() +
        theme(legend.position="bottom") +
        labs(
          subtitle = paste0("From ", paste0( input$slider_year_selected_E[1], paste0(" to ", input$slider_year_selected_E[2]))),
          x = "Year",
          y = "Obesity (%)",
          color = "Country"
        ) +
        theme(
          legend.title = element_text(size = 14, face = "bold"),
          legend.text = element_text(size = 12),
          axis.title.x = element_text(size = 14, face = "bold"),
          axis.title.y = element_text(size = 14, face = "bold"),
        )
    }
  })
  
  # Employment : Raw data 
  output$employment_raw <- renderDataTable({employment})
  
  # Analytics : By country
  output$correlation_title_plot <- renderText({
    paste0(
      "Employment in desk/manual jobs vs. Obesity percentage in ",
      input$select_country_analytics
    )
  })
  output$correlation_plot <- renderPlot({analyticsPlotCorrelationByCountry(input$select_country_analytics)})
  output$correlation_desk_analytics <- renderValueBox({
    valueBox(
      round(analyticsCorrelationByCountryActivity(input$select_country_analytics,"D"), digits = 2),
      "Desk jobs/obesity correlation",
      icon = icon("chart-line"),
      color = if(analyticsCorrelationByCountryActivity(input$select_country_analytics,"D") < 0) "red" else "blue")
  })
  output$correlation_manual_analytics <- renderValueBox({
    valueBox(
      round(analyticsCorrelationByCountryActivity(input$select_country_analytics,"M"), digits = 2),
      "Manual jobs/obesity correlation",
      icon = icon("chart-line"),
      color = if(analyticsCorrelationByCountryActivity(input$select_country_analytics,"M") < 0) "red" else "blue")
  })

  # Analytics : Overall
  output$heatmap_correlation_analytics <- renderPlot({ analyticsHeatmapCorrelation() })
}

