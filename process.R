#
# This script contains the processing code.
#

#- Libraries -#
library(tidyverse) # For graph, grouping, ...
library(countrycode) # For countries, continent, ...
library(stringi) # For string processing


#- Functions -#
# Return a continent from a given country name.
convertCountryNameToContinent <- function(pCountries){
  # Get continent from country name
  continents <- countrycode(sourcevar = pCountries, origin = "country.name",destination = "region")
  
  continents <- ifelse(
    continents == "South Asia", "Asia",
    
    ifelse(
      continents == "Europe & Central Asia", "Europe",
      
      ifelse(
        continents == "Middle East & North Africa", "Africa",
        
        ifelse(
          continents == "Sub-Saharan Africa", "Africa",
          
          ifelse(
            continents == "Latin America & Caribbean", "South America",
          
            ifelse(
              continents == "North America", "North America",
            
              ifelse(
                continents == "East Asia & Pacific", "Oceania",
                "?"
              )
            )
          )
        )
      )
    )
  )
  
  return (continents)
}

# Return the float value in a given index from a given string
extractFloatFromString <- function(string, index){
  # Extract every float
  floats <- (as.numeric(unlist(regmatches(string,gregexpr("[[:digit:]]+\\.*[[:digit:]]*",string)))))
  
  # Exception case
  if(length(floats) > 3){
    for(i in 1:3)
      floats[i] <- (floats[i] + floats[i + 3]) / 2
  }
  
  return (floats[index])
}

# Return a diminished version of sex
convertSexToSexAbbrevation <- function(sex){
  sex_abbr <- ifelse(
    sex == "Male", "M",
    
    ifelse(
      sex == "Males", "M",
      
      ifelse(
        sex == "Female", "F",
        
        ifelse(
          sex == "Females", "F",
          
          ifelse(
            sex == "Both sexes", "B",
            
            ifelse(
              sex == "All persons", "B",
              
              "?"
            )
          )
        )
      )
    )
  )
  
  return (sex_abbr)
}

# Return a type of activity ("D" for a desk job or "M" for a manual job)
convertSubjectToActivity <- function(subject){
  desk = c("J", "K", "L", "M", "N", "O", "P", "Q", " R", "U")
  manual = c("A", "B", "C ", "D", "E", "F", "G", "H", "I", "S", "T")
  
  # Add the '(' and ')' characters around
  desk <- paste("(", paste(desk, ")", sep = ""), sep = "")
  manual <- paste("(", paste(manual, ")", sep = ""), sep = "")

  # Desk case
  if(sum(stri_detect_fixed(subject, desk)) == 1)
    return ("D")
  
  # Manual case
  if(sum(stri_detect_fixed(subject, manual)) == 1)
    return ("M")
  
  else
    return ("?")
}

#-- Processing functions --#
processObesity <- function(pObesityPath){
  obesity <- read.csv(pObesityPath, na = c("No data"))
  
  # Rename columns of obesity
  obesity <- obesity %>% rename(
    str_obesity = Obesity....,
    country = Country,
    year = Year,
    sex = Sex,
  )
  
  # Continent : Add a new column
  obesity$continent <- convertCountryNameToContinent(obesity$country)
  
  # Obesity : Process the obesity column to create 3 other
  obesity$max_obesity <- unlist(lapply(obesity$str_obesity, function(x) extractFloatFromString(x, 3)))
  obesity$min_obesity <- unlist(lapply(obesity$str_obesity, function(x) extractFloatFromString(x, 2)))
  obesity$obesity <- unlist(lapply(obesity$str_obesity, function(x) extractFloatFromString(x, 1)))
  
  # Country code : Add a new column 
  obesity$country_code <- countrycode(obesity$country, origin = "country.name", destination = "iso3c")
  
  # Sex : Modify a column
  obesity$sex <- convertSexToSexAbbrevation(obesity$sex)
  
  # Drop useless index column
  obesity <- select(obesity, -X, -str_obesity)
  
  # Replace NA values
  obesity <- obesity %>% 
    replace_na(list(
      obesity = 0,
      max_obesity = 0,
      min_obesity = 0
    ))
  
  # write.csv(obesity, "data/obesity_final.csv", row.names=FALSE)
  
  return (obesity)
}

processEmployment <- function(pEmploymentPath){
  employment <- read.csv(pEmploymentPath, fileEncoding="UTF-8-BOM")
  
  # Rename columns of employment
  employment <- employment %>% rename(
    country = Country,
    country_code = LOCATION,
    year = Time,
    sex = Sex,
    subject = Subject,
    value = Value
  )
  
  # Drop useless columns
  employment <- employment %>%
    select(country, country_code, year, sex, subject, value)
  
  # Value : Modify the column to its real value
  employment$value <- employment$value * 1000
  
  # Continent : Add a new column
  employment$continent <- convertCountryNameToContinent(employment$country)
  
  # Sex : Modify a column
  employment$sex <- convertSexToSexAbbrevation(employment$sex)
  
  # Subject -> Activity : Process a column to create another one
  employment$activity <- unlist(lapply(employment$subject, function(x) convertSubjectToActivity(x)))
  
  # write.csv(employment, "data/employment_final.csv", row.names=FALSE)
  
  return (employment)
}

processObesityAnalytics <- function(pObesityDataframe, pEmploymentDataframe){
  obesityAnalytics <- pObesityDataframe %>%
    filter(
      country %in% unique(pEmploymentDataframe$country),
      year >= min(pEmploymentDataframe$year),
      year <= max(pEmploymentDataframe$year),
      sex == "B"
    )
  
  return (obesityAnalytics)
}

processEmploymentAnalytics <- function(pEmploymentDataframe, pObesityDataframe){
  employmentAnalytics <- pEmploymentDataframe %>%
    filter(
      country %in% unique(pEmploymentDataframe$country),
      year >= min(pEmploymentDataframe$year),
      year <= max(pEmploymentDataframe$year),
      sex == "B",
      activity != "?"
    ) %>%
    group_by(continent, year, country, activity) %>%
    summarise(value = sum(value))
    
  return (employmentAnalytics)
}
