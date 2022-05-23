Downloaded EPA Water Quality data using REST query:

data_url = 'https://www.waterqualitydata.us/data/Result/search?sampleMedia=Water&characteristicName=Lead&characteristicName=Lead-210&characteristicName=Lead-211&characteristicName=Lead-212&characteristicName=Lead-214&startDateLo=01-01-%i&startDateHi=12-31-%i&mimeType=csv'
station_url = 'https://www.waterqualitydata.us/data/Station/search?sampleMedia=Water&characteristicName=Lead&characteristicName=Lead-210&characteristicName=Lead-211&characteristicName=Lead-212&characteristicName=Lead-214&startDateLo=01-01-%i&startDateHi=12-31-%i&mimeType=csv'

# iterate through for loop over desired years
data_reponse = httr::GET(sprintf(data_url, year, year))
station_reponse = httr::GET(sprintf(station_url, year, year))
data_water = read.csv(text=httr::content(data_reponse, "text"))
station = read.csv(text=httr::content(station_reponse, "text"))

# Merged the station data onto the water quality data
  data_water = data_water %>%
    left_join(station %>% select(MonitoringLocationIdentifier, StateCode, 
                                 CountyCode, LatitudeMeasure, LongitudeMeasure, 
                                 MonitoringLocationTypeName,
                                 contains('VerticalMeasure'), contains('VerticalAccuracy')),
              by = 'MonitoringLocationIdentifier')
              
              
              
              