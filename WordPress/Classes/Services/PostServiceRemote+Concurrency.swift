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
                guard let post = $0 else {
                    return continuation.resume(throwing: URLError(.unknown))
                }
                continuation.resume(returning: post)
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
                guard let post = $0 else {
                    return continuation.resume(throwing: URLError(.unknown))
                }
                continuation.resume(returning: post)
            }, failure: {
                continuation.resume(throwing: $0 ?? URLError(.unknown))
            })
        }
    }
}
