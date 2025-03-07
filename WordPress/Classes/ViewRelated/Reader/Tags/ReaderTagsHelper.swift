import Foundation
import UIKit
import WordPressData

struct ReaderTagsHelper {
    let contextManager: CoreDataStackSwift = ContextManager.shared

    private var viewControler: NSManagedObjectContext { contextManager.mainContext }

    @MainActor
    func followTag(_ tag: String) async throws {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()

        try await withUnsafeThrowingContinuation { continuation in
            let service = ReaderTopicService(coreDataStack: contextManager)
            service.followTagNamed(tag, withSuccess: {
                generator.notificationOccurred(.success)
                continuation.resume(returning: ())
            }, failure: { error in
                DDLogError("Could not follow tag named \(tag) : \(String(describing: error))")
                generator.notificationOccurred(.error)
                continuation.resume(throwing: error ?? URLError(.unknown))
            }, source: "manage")
        }
    }

    @MainActor
    func unfollow(_ tag: ReaderTagTopic) {
        let service = ReaderTopicService(coreDataStack: contextManager)
        service.unfollowTag(tag, withSuccess: {
            // Do nothing
        }, failure: { error in
            DDLogError("Could not unfollow topic \(tag), \(String(describing: error))")
            Notice(title: Strings.failedToUnfollow, message: error?.localizedDescription, feedbackType: .error).post()
        })
    }
}

private enum Strings {
    static let failedToUnfollow = NSLocalizedString("reader.tags.failedToUnfollowErrorTitle", value: "Could Not Remove Topic", comment: "Title for an error snackbar")
}
