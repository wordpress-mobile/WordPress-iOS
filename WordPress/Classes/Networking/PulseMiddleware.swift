import Pulse
import WordPressAPI
import WordPressAPIInternal

final class PulseMiddleware: Middleware {

    private static let errorStatusCodes: [UInt16] = [
        400, 401, 402, 403, 404, 419, 429,
        500
    ]

    func process(
        requestExecutor: any RequestExecutor,
        response: WpNetworkResponse,
        request: WpNetworkRequest,
        context: RequestContext?
    ) async throws -> WpNetworkResponse {

        LoggerStore.shared.storeRequest(
            convertToUrlRequest(request),
            response: try convertToUrlResponse(response),
            error: Self.errorStatusCodes.contains(response.statusCode) ? parseBodyAsError(response.body) : nil,
            data: response.body
        )
        return response
    }

    private func convertToUrlRequest(_ original: WpNetworkRequest) -> URLRequest {
        let url = URL(string: original.url())!
        var request = URLRequest(url: url)
        request.httpMethod = "\(original.method())"
        request.allHTTPHeaderFields = original.headerMap().toFlatMap()
        request.httpBody = original.body()?.contents()
        return request
    }

    private func convertToUrlResponse(_ original: WpNetworkResponse) throws -> URLResponse? {
        HTTPURLResponse(
            url: try original.requestUrl.asURL(),
            statusCode: Int(original.statusCode),
            httpVersion: nil,
            headerFields: original.responseHeaderMap.toFlatMap()
        )
    }

    // TODO: This implementation should probably use the underlying Rust implementation
    private func parseBodyAsError(_ data: Data) -> Error? {
        try? JSONDecoder().decode(WpError.self, from: data)
    }

    struct WpError: Codable, Error {
        let code: Int
        let message: String

        var description: String {
            message
        }
    }
}
