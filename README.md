# R package for Holistics API

This is our R package which allows R users to export Holistics' report data by inputting:

- Your tenant URL
- Your API-key
- Report's ID
- A list of filters applied to that report

## Installation

You can either install Holistics from CRAN, or grab the latest version from GitHub.

- Install from CRAN:

```
install_packages("Holistics")
```

- Install from GitHub:

```
devtools::install_github("holistics/holisticsr")
```

## Basic usage

For most use cases, you can just use `export_data()` to download report's data. For example, we have a complete report link with all filters: 

https://secure.holistics.io/queries/1846-users-growth/queries?start_date=2019-01-01&end_date=2019-01-31&status=active

This link will translate into the following function call:

```
report_data = export_data(url = "https://secure.holistics.io/", 
                          api_key = "api_key",
                          report_id = "1846-users-growth",
                          filters = list(start_date = "2019-01-01", 
                                         end_date = "2019-01-31", 
                                         status = "active"))
```

Behind the scene this function uses three assistance functions consecutively:

```
# Submit an export request
job_id = submit_request(url, api_key, report_id, filters)

# Check result status with a HTTP request. As long as the request is valid,
# this will run until the result is ready for downloading.
# If the request is invalid, this will raise an error.
check_result(url, api_key, job_id)

# Download report result after it is ready
result_df = download_result(url, api_key, job_id)
```

In other words, you can use these functions individually to gain greater control of the export creation and data download process.


## Documentation

Holistics' API documentation, as well as full usage of Holistics R & Python libraries can be found here: https://docs.holistics.io/reference


## Copyright and License:

Copyright (c) 2019, Holistics Software
HolisticsR source code is licensed under [MIT License](https://github.com/holistics/holistics-r/blob/master/LICENSE.md)
