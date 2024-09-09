import Foundation
import UIKit

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
}
