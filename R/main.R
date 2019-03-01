#' @importFrom httr GET add_headers modify_url http_error
#' @importFrom jsonlite fromJSON
#' @importFrom utils read.csv
#' @importFrom xml2 xml_find_all as_list read_html
#' @import tidyr

headers = list(
    "Accept" = "application/json",
    "Content-Type" = "application/json",
    "X-Holistics-Key" = NULL
)

extract_error_response = function(result) {

    char_content = rawToChar(result$content)
    html_content = try(read_html(char_content), silent = T)

    if ("xml_document" %in% class(html_content)) {
        error_response = xml_find_all(html_content, "//p[@class='description']/text()") %>% as_list() %>% unlist() %>% trimws()
    } else if (class(html_content) == "try-error") {

        if (jsonlite::validate(char_content) == T) {
            json_content = try(fromJSON(char_content))
            error_response = json_content$error
        } else {
            error_response = char_content
        }
    }

    return(error_response)
}

#' Assistance function to submit export request
#'
#' Submit a GET request to create data export
#'
#' @param url URL to access your Holistics app. If nothing is provided, this will default to \url{https://secure.holistics.io/}
#' @param api_key API key to access Holistics API. Your Holistics user must be allowed to use API access first.
#' @param report_id Can be the ID number, or the full string containing ID and the name of the report. \cr
#' @param filters A list of filters to apply to the requested report. These must be the filters that you already included in the report. \cr
#' \itemize{
#'   \item If the filter is of Dropdown type, fitler values must be the "key", not the display values that end-user sees in the report.
#'   \item Text or datetime values must be enclosed in quotation marks.
#' }
#' Please refer to example below on how translate this sample URL to a data export call: \cr
#' \code{https://secure.holistics.io/queries/1846-users-growth/queries?start_date=2019-01-01&end_date=2019-01-31&status=active}
#'
#' @examples
#' \dontrun{
#' submit_request(url = "https://secure.holistics.io/"
#'                       , api_key = "api_key"
#'                       , report_id = "1846-users-growth"
#'                       , filters = list(
#'                           start_date = "2019-01-01"
#'                           , end_date = "2019-01-31"
#'                           , status = "active")
#'                        )
#' }
#'
#' @return Report export's job ID
#'
#' @export

submit_request = function(url = "https://secure.holistics.io/", api_key, report_id, filters = list()) {
    # Create an export job, and return job_id
    cat("Submitting export request...", "\n")

    headers$`X-Holistics-Key` = api_key
    url_submit_export = modify_url(url, path = paste("queries", report_id, "submit_export.csv", sep = "/"))
    result = GET(url_submit_export, add_headers(unlist(headers)), query = filters)

    if (http_error(result) == T) {
        error_response = extract_error_response(result)
        stop(sprintf("\nError: %s. \nMessage: \"%s\".", result$headers$status, error_response))
    } else {
        content = try(fromJSON(rawToChar(result$content)), silent = T)
    }

    if (class(content) == "try-error") {
        stop("Failed to get Job ID. Please try again.")
    } else {
        cat("Success.", "\n")
        return(content$job_id)
    }
}


#' Assistance function to check job status
#'
#' @param url URL to access your Holistics app. If nothing is provided, this will default to \url{https://secure.holistics.io/}
#' @param api_key API key to access Holistics API
#' @param job_id Report export's job ID, as returned by submit_request()
#'
#' @return None. If job succeeds, continue, If job fails, it will raise an error.
#'
#' @export

check_result <- function(url = "https://internal.holistics.io/", api_key, job_id) {

    headers$`X-Holistics-Key` = api_key
    url_check_result = modify_url(url, path = "/queries/get_export_results.json")
    result = GET(url_check_result, add_headers(unlist(headers)), query = list(job_id = job_id))

    if (http_error(result) == T) {
        error_response = extract_error_response(result)
        stop(sprintf("\nError: %s. \nMessage: \"%s\".", result$headers$status, error_response))
    } else {
        result_status = fromJSON(rawToChar(result$content))$status
        counter = 1

        while (result_status != "success") {
            if (result_status == "not yet") {
                cat("Preparing job", paste(rep(".", counter), collapse = ""), "\r", sep = "")
                Sys.sleep(1)
                result = GET(url_check_result, add_headers(unlist(headers)), query = list(job_id = job_id))

                if (http_error(result) == T) {
                    error_response = extract_error_response(result)
                    stop(sprintf("\nError: %s. \nMessage: \"%s\".", result$headers$status, error_response))
                } else {
                    result_status = fromJSON(rawToChar(result$content))$status
                }
            } else if (result_status == "failure") {
                stop("Job status: failure")
            }

            if ((counter + 1) %% 5 == 1) {
                counter = 1
                cat("Preparing job.     ", "\r")
            } else {counter = counter + 1}
        }

        cat("\n")
        cat("Success.", "\n")
    }
}

#' Assistance function to download report result
#'
#' Submit a GET request to download result created by the export job.
#'
#' @param url URL to access your Holistics app. If nothing is provided, this will default to \url{https://secure.holistics.io/}
#' @param api_key API key to access Holistics API. Your Holistics user must be allowed to use API access first.
#' @param job_id Report export's job ID, as returned by submit_request()
#'
#' @return A dataframe containing report's data
#'
#' @export

download_result = function(url = "https://secure.holistics.io/", api_key, job_id) {
    cat("Downloading result...", "\n")

    headers$`X-Holistics-Key` = api_key
    url_download_result = modify_url(url, path = "exports/download")
    result = GET(url_download_result, add_headers(unlist(headers)), query = list(job_id = job_id))

    if (http_error(result) == T) {
        error_response = extract_error_response(result)
        stop(sprintf("\nError: %s. \nMessage: \"%s\".", result$headers$status, error_response))
    } else {
        content = try(rawToChar(result$content), silent = T)

        if (class(content) == "try-error") {
            stop("Failed download result. Please try again.")
        } else {
            result_df = try(read.csv(text = content))

            if (class(result_df) == "try-error") {
                stop("Failed to parse result as CSV.")
            } else {
                return(result_df)
            }
        }
    }
}

#' Main function to export report data
#'
#' Create a report export job, and download data when the job is completed.
#' For more information on working with Holistics API, please go here \url{https://docs.holistics.io/docs/get-data-via-api}
#'
#' @param url URL to access your Holistics app. If nothing is provided, this will default to \url{https://secure.holistics.io/}
#' @param api_key API key to access Holistics API. Your Holistics user must be allowed to use API access first.
#' @param report_id Can be the ID number, or the full string containing ID and the name of the report. \cr
#' @param filters A list of filters to apply to the requested report. These must be the filters that you already included in the report. \cr
#' \itemize{
#'   \item If the filter is of Dropdown type, fitler values must be the "key", not the display values that end-user sees in the report.
#'   \item Text or datetime values must be enclosed in quotation marks.
#' }
#' Please refer to example below on how translate this sample URL to a data export call: \cr
#' \code{https://secure.holistics.io/queries/1846-users-growth/queries?start_date=2019-01-01&end_date=2019-01-31&status=active}
#'
#' @examples
#' \dontrun{
#' export_report_data(url = "https://secure.holistics.io/"
#'                    , api_key = "api_key"
#'                    , report_id = "1846-users-growth"
#'                    , filters = list(
#'                        start_date = "2019-01-01"
#'                        , end_date = "2019-01-31"
#'                        , status = "active")
#'                      )
#' }
#'
#' @return A dataframe containing report's data.
#'
#' @export

export_data = function(url = "https://secure.holistics.io/", api_key, report_id, filters = list()) {

    # Submit an export request
    job_id = submit_request(url, api_key, report_id, filters)

    # Check result status with a HTTP request. As long as the request is valid,
    # this will run until the result is ready for downloading.
    # If the request is invalid, this will raise an error.
    check_result(url, api_key, job_id)

    # Download report result after it is ready
    result_df = download_result(url, api_key, job_id)

    cat("Success.", "\n")
    return(result_df)
}

