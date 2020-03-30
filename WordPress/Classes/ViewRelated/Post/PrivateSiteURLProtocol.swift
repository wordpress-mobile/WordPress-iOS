import Foundation

extension PrivateSiteURLProtocol {
    func requestForPrivateAtomicSite(from url: URL) -> URLRequest {
        guard !PrivateSiteURLProtocol.urlGoes(toWPComSite: url),
            var components = URLComponents(url: url, resolvingAgainstBaseURL: true),
            let urlComponent = components.url,
            let bearerToken = PrivateSiteURLProtocol.bearerToken() else {
                return URLRequest(url: url)
        }

        // Just in case, enforce HTTPs
        components.scheme = "https"

        var request = URLRequest(url: urlComponent)
        request.addValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
        return request
    }
}
