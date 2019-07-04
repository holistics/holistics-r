context("Submit export request")
library(Holistics)
library(testthat)

# Get correct params from local environments
api_key = Sys.getenv("HOLISTICS_API_KEY")
report_id = Sys.getenv("report_id")
filters = list(date_range_start = "2016-01-01", date_range_end = "2019-02-15", tenant = 52)

not_test_machine = api_key == "" | report_id == ""
if (not_test_machine) skip("Not on test machine")

test_that("submit_request() returns numeric", {
    skip_on_cran()
    skip_if(not_test_machine)
    expect_is(submit_request(api_key = api_key, report_id = report_id, filters = filters), 'integer')
})

test_that("if no API key, submit_request() Unauthorized error message", {
    skip_on_cran()
    skip_if(not_test_machine)
    expect_error(submit_request(api_key = NULL, report_id = report_id, filters = filters), regexp = "401 Unauthorized")
})

test_that("If wrong API key, submit_request() returns authentication error message", {
    skip_on_cran()
    skip_if(not_test_machine)
    expect_error(submit_request(api_key = 12345, report_id = report_id, filters = filters), regexp = "422 Unprocessable Entity")
})

test_that("If wrong report_id, submit_request() returns Not Found message", {
    skip_on_cran()
    skip_if(not_test_machine)
    expect_error(submit_request(api_key = api_key, report_id = 123, filters = filters), regexp = "404 Not Found")
})

