import Foundation

enum NonceRetrievalMethod {
    case newPostScrap
    case ajaxNonceRequest

    func retrieveNonce(username: String, password: Secret<String>, loginURL: URL, adminURL: URL, using urlSession: URLSession) async -> String? {
        guard let webpageThatContainsNonce = buildURL(base: adminURL) else { return nil }

        // First, make a request to the URL to grab REST API nonce. The HTTP request is very likely to pass, because
        // when this method is called, user should have already authenticated and their site's cookies are already in
        // the `urlSession.
        if let found = await nonce(from: webpageThatContainsNonce, using: urlSession) {
            return found
        }

        // If the above request failed, then make a login request, which redirects to the webpage that contains
        // REST API nonce.
        let loginThenRedirect = HTTPRequestBuilder(url: loginURL)
            .method(.post)
            .body(form: [
                "log": username,
                "pwd": password.secretValue,
                "rememberme": "true",
                "redirect_to": webpageThatContainsNonce.absoluteString
            ])

        return await nonce(from: loginThenRedirect, using: urlSession)
    }

    private func buildURL(base: URL) -> URL? {
        switch self {
            case .newPostScrap:
                return URL(string: "post-new.php", relativeTo: base)
            case .ajaxNonceRequest:
                return URL(string: "admin-ajax.php?action=rest-nonce", relativeTo: base)
        }
    }

    private func retrieveNonce(from html: String) -> String? {
        switch self {
            case .newPostScrap:
                return scrapNonceFromNewPost(html: html)
            case .ajaxNonceRequest:
                return readNonceFromAjaxAction(html: html)
        }
    }

    private func scrapNonceFromNewPost(html: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: "apiFetch.createNonceMiddleware\\(\\s*['\"](?<nonce>\\w+)['\"]\\s*\\)", options: []),
            let match = regex.firstMatch(in: html, options: [], range: NSRange(location: 0, length: html.count)) else {
                return nil
        }
        let nsrange = match.range(withName: "nonce")
        let nonce = Range(nsrange, in: html)
            .map({ html[$0] })
            .map( String.init )

        return nonce
    }

    private func readNonceFromAjaxAction(html: String) -> String? {
        guard !html.isEmpty,
              html.allSatisfy({ $0.isNumber || $0.isLetter })
        else {
            return nil
        }

        return html
    }
}

private extension NonceRetrievalMethod {

    func nonce(from url: URL, using urlSession: URLSession) async -> String? {
        await nonce(from: HTTPRequestBuilder(url: url), using: urlSession)
    }

    func nonce(from builder: HTTPRequestBuilder, using urlSession: URLSession) async -> String? {
        guard let request = try? builder.build() else { return nil }

        guard let (data, response) = try? await urlSession.data(for: request),
            let httpResponse = response as? HTTPURLResponse
        else {
            return nil
        }

        guard 200...299 ~= httpResponse.statusCode, let content = HTTPAPIResponse(response: httpResponse, body: data).bodyText else {
            return nil
        }

        return retrieveNonce(from: content)
    }

}
