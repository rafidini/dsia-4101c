#
# This script contains objects that will be used through every R script
# in the project.
#

#- Necessary packages -#
# Deal with the necessary packages
packages <- read.csv("packages.csv")
list.of.packages <- c(packages$packages)
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages)

#- Load packages -#

# Load the processing functions
source("process.R")

# Imports for dashboard and graphs
library(glue)
library(rnaturalearth)
library(sp)
library(leaflet)
library(DT)
library(tidyverse)
library(shiny)
library(shinydashboard)

#- Data processing -#

# Process the data
obesity <- processObesity('data/obesity.csv')
employment <- processEmployment('data/employment.csv')
analytics <- merge(
  processObesityAnalytics(obesity, employment),
  processEmploymentAnalytics(employment, obesity),
  by = c("continent", "country", "year")
)

#- Functions -#

# sexToTitle:
# Input :
# Output:
sexToTitle <- function(pSex){
  return (ifelse(
    pSex == "B", "both sexes",
    ifelse(
      pSex == "M", "males", "females"
    )
  ))
}

#- Obesity -#

# meanObesityByYearSex: Returns a string representing the mean percentage of
# obesity in a given year and sex 
# Input : pYear = the year, pSex = the sex
# Output: a string
meanObesityByYearSex <- function(pYear, pSex) {
  result <- (obesity %>% group_by(sex,year) %>% summarize(total=mean(obesity)) %>% filter(sex==pSex, year==pYear))
  
  result <- (as.integer(result$total))
  
  result <- (paste0(result, '%'))
  
  return (result)
}

# obesityByGroupSingle: Returns a DataFrame representing the obesity during a 
# given period for a given group
# Input : pGroup = string of the group ('Countries' or 'Continents'),
#         pValue = name of the Country/Continent, 
#         pMinYear = minimum year, pMaxYear = maximum year
# Output: a DataFrame
obesityByGroupSingle <- function(pGroup, pValue, pMinYear, pMaxYear) {
  
  if (pGroup == "Countries") {
    return (obesity %>% filter(country == pValue, sex != 'B', year <= pMaxYear, year >= pMinYear))
  } else {
    return (obesity %>% filter(continent == pValue, sex != 'B', year <= pMaxYear, year >= pMinYear) %>% group_by(sex, year) %>% summarise(obesity=mean(obesity)))
  }
}

# obesityByGroupMultiple: Returns a DataFrame representing the obesity during a 
# given period for a given continent
# Input : pValue = name of the Continent, pMinYear = minimum year
#         pMaxYear = maximum year
# Output: a DataFrame
obesityByGroupMultiple <- function(pValue, pMinYear, pMaxYear){
  return (
    obesity %>%
      filter(sex == 'B', year >= pMinYear, year <= pMaxYear, continent == pValue) %>%
      group_by(country, year) %>%
      summarise(obesity=mean(obesity))
  )
}

# obesityDistribution: Returns a DataFrame representing the obesity for a given
# year and sex.
# Input : pYear = the year, pSex = the sex
# Output: a DataFrame
obesityDistribution <- function(pYear, pSex) {
  
  return (
    obesity %>%
      filter(year == pYear, if(pSex == 'B') sex != pSex else sex == pSex)
  )
}

# obesityMapByYear: Return a Map plot of obesity for a given year
# Input : pYear = the year
# Output: a plot
obesityMapByYear <- function(pYear) {
  map <- ne_countries()
  names(map)[names(map) == "iso_a3"] <- "country_code"
  names(map)[names(map) == "name"] <- "country_name"
  
  
  df <- obesity %>% filter(year == pYear, sex == 'B') %>% select(country_code, country, obesity)
  
  map$obesity <- df[match(map$country_code, df$country_code), "obesity"]
  
  
  pal <- colorBin(
    palette = "Reds",
    domain = map$obesity,
    bins = seq(0, max(df$obesity, na.rm = TRUE) - 15, by = 4)
  )
  
  map$labels <- paste0(
    "<strong> Country: </strong> ",
    map$country_name, "<br/> ",
    "<strong> Obesity: </strong> ",
    map$obesity, "<br/> "
  ) %>%
    lapply(htmltools::HTML)
  
  return (
    leaflet(map) %>%
      addTiles() %>%
      addProviderTiles(providers$OpenMapSurfer.Hybrid) %>%
      setView(lng = 0, lat = 30, zoom = 2) %>%
      addPolygons(
        fillColor = ~ pal(obesity),
        color = "white",
        fillOpacity = 0.7,
        label = ~labels,
        highlight = highlightOptions(
          color = "black",
          bringToFront = TRUE
        )
      ) %>%
      leaflet::addLegend(
        pal = pal, values = ~obesity,
        opacity = 0.7, title = "Obesity (%)"
      )
  )
}

# obesityCountryDifferenceInterval:
# Input :
# Output:
obesityCountryDifferenceInterval <- function(pCountry, pMinYear, pMaxYear){
  obesityCountry <- obesity %>% filter(country == pCountry, sex == 'B')
  before <- obesityCountry %>% filter(year == pMinYear)
  after <- obesityCountry %>% filter(year == pMaxYear)
  
  difference <- (after$obesity - before$obesity)
  
  if(difference >= 0)
    difference <- paste0("+", difference)
  
  return (difference)
}

#- Employment -#

# employmentMapByYear: Return a Map plot of employment for a given year
# Input : pYear = the year
# Output: a plot
employmentMapByYear <- function(pYear,pType) {
  map <- ne_countries()
  names(map)[names(map) == "iso_a3"] <- "country_code"
  names(map)[names(map) == "name"] <- "country_name"
  
  copy <- data.frame(employment %>% mutate(value = log(value)))
  df <- copy %>% filter(year == pYear, sex == 'B', activity ==pType) %>% select(country_code, country, value)
  
  map$value <- df[match(map$country_code, df$country_code), "value"]
  
  pal <- colorBin(
    palette = if(pType =='M') "Blues"  else "Reds", 
    domain = map$value,
    bins = seq(6, max(df$value, na.rm = TRUE), by = 2 )
  )
  
  map$labels <- paste0(
    "<strong> Country: </strong> ",
    map$country_name, "<br/> ",
    "<strong> Employment: </strong> ",
    map$value, "<br/> "
  ) %>%
    lapply(htmltools::HTML)
  
  return (
    leaflet(map) %>%
      addTiles() %>%
      addProviderTiles(providers$OpenMapSurfer.Hybrid) %>%
      setView(lng = 0, lat = 30, zoom = 2) %>%
      addPolygons(
        fillColor = ~ pal(value),
        color = "white",
        fillOpacity = 0.7,
        label = ~labels,
        highlight = highlightOptions(
          color = "black",
          bringToFront = TRUE
        )
      ) %>%
      leaflet::addLegend(
        pal = pal, values = ~value,
        opacity = 0.7, title = "Employment (log scale)"
      )
  )
}

# meanEmploymentByYearSex: Returns a string representing the mean value of manual employment
# in a given year and sex 
# Input : pYear = the year, pSex = the sex
# Output: a string
meanEmploymentByYearSex <- function(pYear, pSex, pType) {
  result <- (employment %>% filter(sex==pSex, year==pYear,activity ==pType)  %>% group_by(sex,year,activity) %>% summarize(total=mean(value)))
  
  result <- (as.integer(result$total))
  
  return (result)
}

# employmentCountryDifferenceInterval:
# Input :
# Output:
employmentCountryDifferenceInterval <- function(pCountry, pMinYear, pMaxYear, pType){
  employmentCountry <- employment %>% filter(country == pCountry, sex == 'B', activity == pType)
  before <- employmentCountry %>% filter(year == pMinYear)
  after <- employmentCountry %>% filter(year == pMaxYear) 
  
  difference <- (sum(after$value)   - sum(before$value)) 
  
  if(difference >= 0)
    difference <- paste0("+", difference)
  
  return (difference)
}

# employmentByGroupSingle: Returns a DataFrame representing the type of employment during a 
# given period for a given group
# Input : pGroup = string of the group ('Countries' or 'Continents'),
#         pValue = name of the Country/Continent, 
#         pMinYear = minimum year, pMaxYear = maximum year
# Output: a DataFrame
employmentByGroupSingle <- function(pGroup, pValue, pMinYear, pMaxYear, pType) {
  
  if (pGroup == "Countries") {
    return (employment %>% filter(country == pValue, sex == 'B', year <= pMaxYear, year >= pMinYear, activity == pType)) %>% group_by(year) %>% summarise(value=sum(value))
  } else {
    return (employment %>% filter(continent == pValue, sex != 'B', year <= pMaxYear, year >= pMinYear, activity == pType) %>% group_by(sex, year) %>% summarise(value=sum(value)))
  }
}

# employmentByGroupMultiple: Returns a DataFrame representing the type of employment during a 
# given period for a given continent
# Input : pValue = name of the Continent, pMinYear = minimum year
#         pMaxYear = maximum year
# Output: a DataFrame
employmentByGroupMultiple <- function(pValue, pMinYear, pMaxYear, pType){
  return (
    employment %>%
      filter(sex == 'B', year >= pMinYear, year <= pMaxYear, continent == pValue, activity == pType) %>%
      group_by(country, year) %>%
      summarise(value=mean(value))
  )
}

# employmentDistribution: Returns a DataFrame representing the manual employment for a given
# year and sex.
# Input : pYear = the year, pSex = the sex
# Output: a DataFrame
employmentDistribution <- function(pYear, pSex, pType) {
  
  return (
    employment %>%
      filter(activity ==pType, year == pYear, if(pSex == 'B') sex != pSex else sex == pSex)
  )
}

#- Analytics -#

# analyticsPlotCorrelationByCountry:
# Input :
# Output:
analyticsPlotCorrelationByCountry <- function(pCountry){
  
  #print(cor(analytics %>% filter(country == pCountry) %>% group_by(activity), x = obesity, y = value ))
  return(
    ggplot(
      analytics %>% 
        filter(country == pCountry) %>%
        mutate(activity = factor(ifelse(activity == "D", "Desktop", "Manual"))),
      aes(x = obesity, y = value)
      ) +
      facet_wrap(~activity, scales = "free")+
      geom_point() + 
      geom_smooth(method = "lm", colour="black") +
      labs(
        x = "Obesity (%)",
        y = "Employment (Persons)"
      ) +
      theme(
        axis.title.x = element_text(size = 14, face = "bold"),
        axis.title.y = element_text(size = 14, face = "bold"),
      )
  )
}

# analyticsCorrelationByCountryActivity:
# Input :
# Output:
analyticsCorrelationByCountryActivity <- function(pCountry, pActivity){
  df <- analytics %>% filter(country == pCountry, activity == pActivity)
  
  return (cor(df$obesity, df$value))
}

# analyticsCorrelationTable:
# Input :
# Output:
analyticsCorrelationTable <- function(){
  return (analytics %>%
            group_by(country, activity) %>%
            summarize(correlation = cor(obesity, value)) %>%
            drop_na()
  )
}

# analyticsCorrelationTable:
# Input :
# Output:
analyticsHeatmapCorrelation <- function(){
  return (
    ggplot(analyticsCorrelationTable(),
           aes(x = country, y = activity, fill = correlation)) +
      geom_tile() +
      labs(
        x = "Country",
        y = "Activity",
        fill = "Correlation"
      ) +
      theme(
        axis.text.x = element_text(angle = 90),
        axis.title.x = element_text(size = 14, face = "bold"),
        axis.title.y = element_text(size = 14, face = "bold"),
      ) + 
      scale_fill_gradientn(colours = c("red", "white", "blue")) +
      scale_y_discrete(labels = c("D" = "Desktop", "M" = "Manual"))
  )
}
