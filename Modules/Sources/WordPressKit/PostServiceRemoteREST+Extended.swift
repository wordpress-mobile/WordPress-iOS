import Foundation

extension PostServiceRemoteREST: PostServiceRemoteExtended {
    public func post(withID postID: Int) async throws -> RemotePost {
        let path = self.path(forEndpoint: "sites/\(siteID)/posts/\(postID)?context=edit", withVersion: ._1_1)
        let result = await wordPressComRestApi.perform(.get, URLString: path)
        switch result {
        case .success(let response):
            return try await decodePost(from: response.body)
        case .failure(let error):
            if case .endpointError(let error) = error, error.apiErrorCode == "unknown_post" {
                throw PostServiceRemoteError.notFound
            }
            throw error
        }
    }

    public func createPost(with parameters: RemotePostCreateParameters) async throws -> RemotePost {
        let path = self.path(forEndpoint: "sites/\(siteID)/posts/new?context=edit", withVersion: ._1_2)
        let parameters = try makeParameters(from: RemotePostCreateParametersWordPressComEncoder(parameters: parameters))

        let response = try await wordPressComRestApi.perform(.post, URLString: path, parameters: parameters).get()
        return try await decodePost(from: response.body)
    }

    public func patchPost(withID postID: Int, parameters: RemotePostUpdateParameters) async throws -> RemotePost {
        let path = self.path(forEndpoint: "sites/\(siteID)/posts/\(postID)?context=edit", withVersion: ._1_2)
        let parameters = try makeParameters(from: RemotePostUpdateParametersWordPressComEncoder(parameters: parameters))

        let result = await wordPressComRestApi.perform(.post, URLString: path, parameters: parameters)
        switch result {
        case .success(let response):
            return try await decodePost(from: response.body)
        case .failure(let error):
            guard case .endpointError(let error) = error else {
                throw error
            }
            switch error.apiErrorCode ?? "" {
            case "unknown_post": throw PostServiceRemoteError.notFound
            case "old-revision": throw PostServiceRemoteError.conflict
            default: throw error
            }
        }
    }

    public func deletePost(withID postID: Int) async throws {
        let path = self.path(forEndpoint: "sites/\(siteID)/posts/\(postID)/delete", withVersion: ._1_1)
        let result = await wordPressComRestApi.perform(.post, URLString: path)
        switch result {
        case .success:
            return
        case .failure(let error):
            guard case .endpointError(let error) = error else {
                throw error
            }
            switch error.apiErrorCode ?? "" {
            case "unknown_post": throw PostServiceRemoteError.notFound
            default: throw error
            }
        }
    }

    public func createAutosave(forPostID postID: Int, parameters: RemotePostCreateParameters) async throws -> RemotePostAutosaveResponse {
        let path = self.path(forEndpoint: "sites/\(siteID)/posts/\(postID)/autosave", withVersion: ._1_1)
        let parameters = try makeParameters(from: RemotePostCreateParametersWordPressComEncoder(parameters: parameters))
        let result = await wordPressComRestApi.perform(.post, URLString: path, parameters: parameters, type: RemotePostAutosaveResponse.self)
        return try result.get().body
    }
}

public struct RemotePostAutosaveResponse: Decodable {
    public let autosaveID: Int
    public let previewURL: URL

    enum CodingKeys: String, CodingKey {
        case autosaveID = "ID"
        case previewURL = "preview_URL"
    }
}

// Decodes the post in the background.
private func decodePost(from object: AnyObject) async throws -> RemotePost {
    guard let dictionary = object as? [AnyHashable: Any] else {
        throw WordPressAPIError<WordPressComRestApiEndpointError>.unparsableResponse(response: nil, body: nil)
    }
    return PostServiceRemoteREST.remotePost(fromJSONDictionary: dictionary)
}

private func makeParameters<T: Encodable>(from value: T) throws -> [String: AnyObject] {
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .formatted(.wordPressCom)
    let data = try encoder.encode(value)
    let object = try JSONSerialization.jsonObject(with: data)
    guard let dictionary = object as? [String: AnyObject] else {
        throw URLError(.unknown) // This should never happen
    }
    return dictionary
}
