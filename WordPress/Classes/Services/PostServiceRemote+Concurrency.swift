import Foundation
import WordPressKit

extension PostServiceRemote {
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
