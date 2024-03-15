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
