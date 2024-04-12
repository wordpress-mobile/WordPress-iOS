import Foundation
import WordPressKit

extension PostServiceRemote {
    func post(withID postID: NSNumber) async throws -> RemotePost {
        try await withCheckedThrowingContinuation { continuation in
            getPostWithID(postID, success: {
                guard let post = $0 else {
                    return continuation.resume(throwing: URLError(.unknown))
                }
                continuation.resume(returning: post)
            }, failure: {
                let error = $0.map(mapRemotePostError) ?? URLError(.unknown)
                continuation.resume(throwing: error)
            })
        }
    }

    func trashPost(_ post: RemotePost) async throws -> RemotePost {
        try await withCheckedThrowingContinuation { continuation in
            trashPost(post) {
                guard let post = $0 else {
                    return continuation.resume(throwing: URLError(.unknown))
                }
                continuation.resume(returning: post)
            } failure: {
                continuation.resume(throwing: $0 ?? URLError(.unknown))
            }
        }
    }
}

// TODO: move this and `post(withID)` to WordPressKit
private func mapRemotePostError(error: Error) -> Error {
    if let error = error as? WordPressAPIError<WordPressComRestApiEndpointError>,
       case .endpointError(let error) = error,
        error.apiErrorCode == "unknown_post" {
        return PostServiceRemoteUpdatePostError.notFound
    }
    if let error = error as? WordPressAPIError<WordPressOrgXMLRPCApiFault>,
       case .endpointError(let error) = error,
        error.code == 404 {
        return PostServiceRemoteUpdatePostError.notFound
    }
    if (error as NSError).code == 404 {
        return PostServiceRemoteUpdatePostError.notFound
    }
    return error
}

extension PostServiceRemoteREST {
    struct AutosaveResponse {
        var previewURL: URL
    }

    func createAutosave(with post: RemotePost) async throws -> AutosaveResponse {
        try await withCheckedThrowingContinuation { continuation in
            self.autoSave(post, success: { _, previewURL in
                guard let previewURL = previewURL.flatMap(URL.init) else {
                    return continuation.resume(throwing: URLError(.unknown))
                }
                let response = AutosaveResponse(previewURL: previewURL)
                continuation.resume(returning: response)
            }, failure: {
                continuation.resume(throwing: $0 ?? URLError(.unknown))
            })
        }
    }
}
