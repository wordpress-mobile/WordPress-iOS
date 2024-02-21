import Foundation
import WordPressKit

extension PostServiceRemote {
    func update(_ post: RemotePost) async throws -> RemotePost {
        try await withUnsafeThrowingContinuation { continuation in
            update(post, success: {
                assert($0 != nil)
                continuation.resume(returning: $0 ?? post)
            }, failure: { error in
                continuation.resume(throwing: error ?? URLError(.unknown))
            })
        }
    }

    // TODO: Check if we need special logic like in `PostService` to update the post status to scheduled if needed
    func create(_ post: RemotePost) async throws -> RemotePost {
        try await withUnsafeThrowingContinuation { continuation in
            createPost(post, success: {
                assert($0 != nil)
                continuation.resume(returning: $0 ?? post)
            }, failure: { error in
                continuation.resume(throwing: error ?? URLError(.unknown))
            })
        }
    }
}
