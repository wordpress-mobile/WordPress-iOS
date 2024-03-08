import Foundation
import WordPressKit

extension PostServiceRemote {
    func post(withID postID: NSNumber) async throws -> RemotePost? {
        try await withCheckedThrowingContinuation { continuation in
            getPostWithID(postID, success: {
                continuation.resume(returning: $0)
            }, failure: {
                continuation.resume(throwing: $0 ?? URLError(.unknown))
            })
        }
    }

    func update(_ post: RemotePost) async throws -> RemotePost {
        try await withUnsafeThrowingContinuation { continuation in
            update(post, success: {
                assert($0 != nil)
                continuation.resume(returning: $0 ?? post)
            }, failure: {
                continuation.resume(throwing: $0 ?? URLError(.unknown))
            })
        }
    }

    func create(_ post: RemotePost) async throws -> RemotePost {
        try await withUnsafeThrowingContinuation { continuation in
            createPost(post, success: {
                assert($0 != nil)
                continuation.resume(returning: $0 ?? post)
            }, failure: {
                continuation.resume(throwing: $0 ?? URLError(.unknown))
            })
        }
    }

    func patchPost(withID postID: NSNumber, parameters: RemotePostUpdateParameters) async throws -> RemotePost {
        try await withUnsafeThrowingContinuation { continuation in
            patchPost(withID: postID, parameters: parameters, success: {
                guard let post = $0 else {
                    // This should never happen
                    return continuation.resume(throwing: URLError(.unknown))
                }
                continuation.resume(returning: post)
            }, failure: {
                continuation.resume(throwing: $0 ?? URLError(.unknown))
            })
        }
    }
}
