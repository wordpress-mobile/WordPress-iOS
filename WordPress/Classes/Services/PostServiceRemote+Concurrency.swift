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

    /// TODO: Remove it once the new `_save()` method is integrated.
    ///
    /// - warning: Work-in-progress (kahu-offline-mode)
    func _update(_ post: RemotePost) async throws -> RemotePost {
        try await withUnsafeThrowingContinuation { continuation in
            update(post, success: {
                assert($0 != nil)
                continuation.resume(returning: $0 ?? post)
            }, failure: {
                continuation.resume(throwing: $0 ?? URLError(.unknown))
            })
        }
    }

    /// TODO: Remove it once the new `_save()` method is integrated.
    ///
    /// - warning: Work-in-progress (kahu-offline-mode)
    func _create(_ post: RemotePost) async throws -> RemotePost {
        try await withUnsafeThrowingContinuation { continuation in
            createPost(post, success: {
                assert($0 != nil)
                continuation.resume(returning: $0 ?? post)
            }, failure: {
                continuation.resume(throwing: $0 ?? URLError(.unknown))
            })
        }
    }
}
