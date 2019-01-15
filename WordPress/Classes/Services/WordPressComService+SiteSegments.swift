import WordPressKit

// MARK: - WordPressComServiceRemote (Site Segments)

/// Describes the errors that could arise when searching for site verticals.
///
/// - requestEncodingFailure:   unable to encode the request parameters.
/// - responseDecodingFailure:  unable to decode the server response.
/// - serviceFailure:           the service returned an unexpected error.
///
enum SiteSegmentsError: Error {
    case requestEncodingFailure
    case responseDecodingFailure
    case serviceFailure
}

/// Advises the caller of results related to requests for site verticals.
///
/// - success: the site verticals request succeeded with the accompanying result.
/// - failure: the site verticals request failed due to the accompanying error.
///
//enum SiteSegmentsResult {
//    case success([SiteSegment])
//    case failure(SiteSegmentsError)
//}
//typealias SiteSegmentsServiceCompletion = ((SiteVerticalsResult) -> ())

extension WordPressComServiceRemote {
    func retrieveSegments(completion: @escaping SiteSegmentsServiceCompletion) {
        print("===== firing request to service in Wordpresscomserviceremote")
    }
}
