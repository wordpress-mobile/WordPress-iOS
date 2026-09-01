import WordPressAPI
import WordPressAPIInternal

extension WpApiError {
    /// A REST error carrying only the fields the comments code reads: the WP
    /// error code and the HTTP status.
    static func stub(code: WpErrorCode = .CustomError("stub"), statusCode: UInt32 = 400) -> WpApiError {
        .WpError(
            errorCode: code,
            errorMessage: "",
            statusCode: statusCode,
            response: "{}",
            requestUrl: "https://example.com",
            requestMethod: .get
        )
    }
}
