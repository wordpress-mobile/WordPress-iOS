import Foundation

public final class JetpackAIServiceRemote: SiteServiceRemoteWordPressComREST {

    /// Returns information about your current tier, requests limit, and more.
    public func getAssistantFeatureDetails() async throws -> JetpackAssistantFeatureDetails {
        let path = path(forEndpoint: "sites/\(siteID)/jetpack-ai/ai-assistant-feature", withVersion: ._2_0)
        let response = await wordPressComRestApi.perform(.get, URLString: path, type: JetpackAssistantFeatureDetails.self)
        return try response.get().body
    }

    /// Returns short-lived JWT token (lifetime is in minutes).
    public func getAuthorizationToken() async throws -> String {
        struct Response: Decodable {
            let token: String
        }
        let path = path(forEndpoint: "sites/\(siteID)/jetpack-openai-query/jwt", withVersion: ._2_0)
        let response = await wordPressComRestApi.perform(.post, URLString: path, type: Response.self)
        return try response.get().body.token
    }

    /// - parameter token: Token retrieved using ``JetpackAIServiceRemote/getAuthorizationToken``.
    public func transcribeAudio(from fileURL: URL, token: String) async throws -> String {
        let path = path(forEndpoint: "jetpack-ai-transcription?feature=voice-to-content", withVersion: ._2_0)
        let file = FilePart(parameterName: "audio_file", url: fileURL, fileName: "voice_recording", mimeType: "audio/m4a")
        let result = await wordPressComRestApi.upload(URLString: path, httpHeaders: [
            "Authorization": "Bearer \(token)"
        ], fileParts: [file])
        guard let body = try result.get().body as? [String: Any],
              let text = body["text"] as? String else {
            throw URLError(.unknown)
        }
        return text
    }

    /// - parameter token: Token retrieved using ``JetpackAIServiceRemote/getAuthorizationToken``.
    public func makePostContent(fromPlainText plainText: String, token: String) async throws -> String {
        let path = path(forEndpoint: "jetpack-ai-query", withVersion: ._2_0)
        let request = JetpackAIQueryRequest(messages: [
            .init(role: "jetpack-ai", context: .init(type: "voice-to-content-simple-draft", content: plainText))
        ], feature: "voice-to-content", stream: false)
        let builder = try wordPressComRestApi.requestBuilder(URLString: path)
            .method(.post)
            .headers(["Authorization": "Bearer \(token)"])
            .body(json: request, jsonEncoder: JSONEncoder())
        let result = await wordPressComRestApi.perform(request: builder) { data in
            try JSONDecoder().decode(JetpackAIQueryResponse.self, from: data)
        }
        let response = try result.get().body
        guard let content = response.choices.first?.message.content else {
            throw URLError(.unknown)
        }
        return content
    }
}

private struct JetpackAIQueryRequest: Encodable {
    let messages: [Message]
    let feature: String
    let stream: Bool

    struct Message: Encodable {
        let role: String
        let context: Context
    }

    struct Context: Codable {
        let type: String
        let content: String
    }
}

private struct JetpackAIQueryResponse: Decodable {
    let model: String?
    let choices: [Choice]

    struct Choice: Codable {
        let index: Int
        let message: Message
    }

    struct Message: Codable {
        let role: String?
        let content: String
    }
}
