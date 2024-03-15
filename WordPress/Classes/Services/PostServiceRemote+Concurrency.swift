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
}
