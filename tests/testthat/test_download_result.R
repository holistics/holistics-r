context("Check result status")
library(Holistics)
library(testthat)

# Get correct params from local environments
api_key = Sys.getenv("HOLISTICS_API_KEY")
report_id = Sys.getenv("report_id")
filters = list(date_range_start = "2016-01-01", date_range_end = "2019-02-15", tenant = 52)
job_id = submit_request(api_key = api_key, report_id = report_id, filters = filters)
check_result(api_key = api_key, job_id = job_id)


test_that("download_result() return data_frame", {
    skip_on_cran()
    skip_if(api_key == "" | report_id == "")
    expect_is(download_result(api_key = api_key, job_id = job_id), "data.frame")
})

test_that("If no API key, download_result() return Unauthorized message", {
    skip_on_cran()
    skip_if(api_key == "" | report_id == "")
    expect_error(download_result(api_key = NULL, job_id = job_id), regexp = "401 Unauthorized")
})

test_that("If no Job ID, download_result() return Unprocessable Entity message", {
    skip_on_cran()
    skip_if(api_key == "" | report_id == "")
    expect_error(download_result(api_key = api_key, job_id = NULL), regexp = "422 Unprocessable Entity")
})

test_that("If wrong API key, download_result() returns authentication error message", {
    skip_on_cran()
    skip_if(api_key == "" | report_id == "")
    expect_error(download_result(api_key = 123, job_id = job_id), regexp = "422 Unprocessable Entity")
    expect_error(download_result(api_key = "123abcxyz", job_id = job_id), regexp = "422 Unprocessable Entity")
})

test_that("IF wrong Job ID, download_result() returns 'Resource not found' message", {
    skip_on_cran()
    skip_if(api_key == "" | report_id == "")
    expect_error(download_result(api_key = api_key, job_id = 123), regexp = "404 Not Found")
    expect_error(download_result(api_key = api_key, job_id = "123abcxyz"), regexp = "404 Not Found")
})
