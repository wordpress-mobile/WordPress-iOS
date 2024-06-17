extension URLRequest {

    static func googleSignInTokenRequest(
        body: OAuthTokenRequestBody
    ) throws -> URLRequest {
        var request = URLRequest(url: URL.googleSignInOAuthTokenURL)
        request.httpMethod = "POST"

        request.setValue(
            "application/x-www-form-urlencoded; charset=UTF-8",
            forHTTPHeaderField: "Content-Type"
        )

        request.httpBody = try body.asURLEncodedData()

        return request
    }
}
