import Foundation
import wpxmlrpc

extension PostServiceRemoteXMLRPC: PostServiceRemoteExtended {
    public func post(withID postID: Int) async throws -> RemotePost {
        let parameters = xmlrpcArguments(withExtra: postID) as [AnyObject]
        let result = await api.call(method: "wp.getPost", parameters: parameters)
        switch result {
        case .success(let response):
            return try await decodePost(from: response.body)
        case .failure(let error):
            if case .endpointError(let error) = error, error.code == 404 {
                throw PostServiceRemoteError.notFound
            }
            throw error
        }
    }

    public func createPost(with parameters: RemotePostCreateParameters) async throws -> RemotePost {
        let dictionary = try makeParameters(from: RemotePostCreateParametersXMLRPCEncoder(parameters: parameters))
        let parameters = xmlrpcArguments(withExtra: dictionary) as [AnyObject]
        let response = try await api.call(method: "wp.newPost", parameters: parameters).get()
        guard let postID = (response.body as? NSObject)?.numericValue() else {
            throw URLError(.unknown) // Should never happen
        }
        return try await post(withID: postID.intValue)
    }

    public func patchPost(withID postID: Int, parameters: RemotePostUpdateParameters) async throws -> RemotePost {
        let dictionary = try makeParameters(from: RemotePostUpdateParametersXMLRPCEncoder(parameters: parameters))
        let parameters = xmlrpcArguments(withExtraDefaults: [postID as NSNumber], andExtra: dictionary) as [AnyObject]
        let result = await api.call(method: "wp.editPost", parameters: parameters)
        switch result {
        case .success:
            return try await post(withID: postID)
        case .failure(let error):
            guard case .endpointError(let error) = error else {
                throw error
            }
            switch error.code ?? 0 {
            case 404: throw PostServiceRemoteError.notFound
            case 409: throw PostServiceRemoteError.conflict
            default: throw error
            }
        }
    }

    public func deletePost(withID postID: Int) async throws {
        let parameters = xmlrpcArguments(withExtra: postID) as [AnyObject]
        let result = await api.call(method: "wp.deletePost", parameters: parameters)
        switch result {
        case .success:
            return
        case .failure(let error):
            if case .endpointError(let error) = error, error.code == 404 {
                throw PostServiceRemoteError.notFound
            }
            throw error
        }
    }
}

private func decodePost(from object: AnyObject) async throws -> RemotePost {
    guard let dictionary = object as? [AnyHashable: Any] else {
        throw WordPressAPIError<WordPressComRestApiEndpointError>.unparsableResponse(response: nil, body: nil)
    }
    return PostServiceRemoteXMLRPC.remotePost(fromXMLRPCDictionary: dictionary)
}

private func makeParameters<T: Encodable>(from value: T) throws -> [String: AnyObject] {
    let encoder = PropertyListEncoder()
    encoder.outputFormat = .xml
    let data = try encoder.encode(value)
    let object = try PropertyListSerialization.propertyList(from: data, format: nil)
    guard let dictionary = object as? [String: AnyObject] else {
        throw URLError(.unknown) // This should never happen
    }
    return dictionary
}
