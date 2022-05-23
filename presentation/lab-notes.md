Data:

1. Download lead air data from EPA Pre-Generated Data Files on air:
https://aqs.epa.gov/aqsweb/airdata/download_files.html#Raw
Downloaded all zips of lead for all years.

2. Download lead water data from the water quality portal

https://www.waterqualitydata.us/portal/#sampleMedia=Water&characteristicType=Inorganics%2C%20Major%2C%20Metals&characteristicName=Lead&characteristicName=Lead-210&characteristicName=Lead-211&characteristicName=Lead-212&characteristicName=Lead-214&mimeType=csv

## Curl post (should be GET) but didn't work
curl -X POST --header 'Content-Type: application/json' --header 'Accept: application/zip' -d '{"sampleMedia":["Water"],"characteristicType":["Inorganics, Major, Metals"],"characteristicName":["Lead","Lead-210","Lead-211","Lead-212","Lead-214"],"startDateLo":"01-01-1950","startDateHi":"12-31-1950"}' 'https://www.waterqualitydata.us/data/Station/search?mimeType=csv&zip=yes'


curl -X GET --output lead_water_station.csv --header 'Content-Type: application/json' --header 'Accept: application/zip' -d '{"sampleMedia":["Water"],"characteristicName":["Lead","Lead-210","Lead-211","Lead-212","Lead-214"],"startDateLo":"01-01-1990","startDateHi":"01-10-1990"}' 'https://www.waterqualitydata.us/data/Station/search?mimeType=csv&zip=yes'

curl -X GET --output lead_water_station.csv --header 'Content-Type: application/json' --header 'Accept: application/zip' -d '{"sampleMedia":["Water"],"characteristicName":["Lead","Lead-210","Lead-211","Lead-212","Lead-214"],"startDateLo":"01-01-1990","startDateHi":"01-10-1990"}' 'https://www.waterqualitydata.us/data/Station/search?mimeType=csv&zip=yes'

curl -X GET --output lead_water_data.csv --header 'Content-Type: application/json' --header 'Accept: application/zip' -d '{"sampleMedia":["Water"],"characteristicName":["Lead","Lead-210","Lead-211","Lead-212","Lead-214"],"startDateLo":"01-01-1990","startDateHi":"01-10-1990"}' 'https://www.waterqualitydata.us/data/Result/search?mimeType=csv&zip=yes'

# data
https://www.waterqualitydata.us/data/Result/search?sampleMedia=Water&characteristicName=Lead&characteristicName=Lead-210&characteristicName=Lead-211&characteristicName=Lead-212&characteristicName=Lead-214&startDateLo=01-01-1990&startDateHi=01-10-1990&mimeType=csv

# station info
https://www.waterqualitydata.us/data/Station/search?sampleMedia=Water&characteristicName=Lead&characteristicName=Lead-210&characteristicName=Lead-211&characteristicName=Lead-212&characteristicName=Lead-214&startDateLo=01-01-1990&startDateHi=01-10-1990&mimeType=csv