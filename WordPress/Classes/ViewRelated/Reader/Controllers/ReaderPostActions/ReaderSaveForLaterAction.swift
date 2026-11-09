import UIKit
import WordPressAPI
import WordPressData
import WordPressFlux
import WordPressShared
import WordPressUI

/// Encapsulates saving a post for later. Posts are saved in the WordPress.com account, so this needs
/// a WordPress.com sign-in; the save buttons are hidden without one.
final class ReaderSaveForLaterAction {
    private enum Strings {
        static let postSaved = NSLocalizedString(
            "Post saved.",
            comment: "Title of the notification presented in Reader when a post is saved for later"
        )
        static let postRemoved = NSLocalizedString(
            "Post removed.",
            comment: "Title of the notification presented in Reader when a post is removed from save for later"
        )
        static let addToSavedError = NSLocalizedString("Could not save post for later", comment: "Title of a prompt.")
        static let removeFromSavedError = NSLocalizedString(
            "Could not remove post from Saved for Later",
            comment: "Title of a prompt."
        )
        static let promoTitle = NSLocalizedString(
            "reader.saveForLaterAlert.title",
            value: "Save Posts for Later",
            comment: "Title of alert informing users about the Reader Save for Later feature."
        )
        static let promoDescription = NSLocalizedString(
            "reader.saveForLaterAlert.description.synced",
            value:
                "Save this post, and come back to read it whenever you'd like. Saved posts sync across your devices signed in to the same WordPress.com account.",
            comment:
                "Body text of alert informing users about the Reader Save for Later feature, when saved posts sync with their WordPress.com account."
        )
    }

    var visibleConfirmation: Bool

    init(visibleConfirmation: Bool = false) {
        self.visibleConfirmation = visibleConfirmation
    }

    func execute(
        with post: ReaderPost,
        context: NSManagedObjectContext = ContextManager.shared.mainContext,
        origin: ReaderSaveForLaterOrigin,
        viewController: UIViewController?,
        completion: (() -> Void)? = nil
    ) {
        // Every caller is UI code on the main thread.
        let isSignedIn = MainActor.assumeIsolated { ReaderSavedPostsStore.shared.isActive }
        guard isSignedIn else {
            // The save buttons are hidden without a WordPress.com account.
            Loggers.app.warning("Reader: saving a post needs a WordPress.com account")
            completion?()
            return
        }

        /// Preload the post
        if let viewController, !post.isSavedForDisplay {
            let offlineReaderWebView = OfflineReaderWebView()
            offlineReaderWebView.saveForLater(post, viewController: viewController)
        }

        if let viewController, !post.isSavedForDisplay {
            presentReaderSavedPostsAlertControllerIfNecessary(from: viewController)
        }

        trackSaveAction(for: post, origin: origin)
        MainActor.assumeIsolated {
            toggleSavedForLater(post, context: context, origin: origin, completion: completion)
        }
    }

    /// Saves or unsaves the post in the WordPress.com account, which syncs it to the user's other
    /// devices. The account's saved posts service shows the change straight away, and takes it back
    /// if the request fails.
    @MainActor
    private func toggleSavedForLater(
        _ post: ReaderPost,
        context: NSManagedObjectContext,
        origin: ReaderSaveForLaterOrigin,
        completion: (() -> Void)?
    ) {
        let willSave = !post.isSavedForDisplay
        Task { @MainActor in
            do {
                try await ReaderSavedPostsStore.shared.toggleSaved(post)
                if origin == .otherStream {
                    presentSuccessNotice(
                        for: post,
                        isSaved: willSave,
                        context: context,
                        origin: origin,
                        completion: completion
                    )
                }
            } catch {
                // The post is back as it was, so tell the user wherever they are.
                presentErrorNotice(error, activating: willSave)
            }
            completion?()
        }
    }

    @MainActor
    private func presentSuccessNotice(
        for post: ReaderPost,
        isSaved: Bool,
        context: NSManagedObjectContext,
        origin: ReaderSaveForLaterOrigin,
        completion: (() -> Void)?
    ) {
        guard visibleConfirmation else {
            return
        }

        if isSaved {
            present(Notice(title: Strings.postSaved, feedbackType: .success))
        } else {
            presentPostRemovedNotice(for: post, context: context, origin: origin, completion: completion)
        }
    }

    @MainActor
    private func presentPostRemovedNotice(
        for post: ReaderPost,
        context: NSManagedObjectContext,
        origin: ReaderSaveForLaterOrigin,
        completion: (() -> Void)?
    ) {
        guard visibleConfirmation else {
            return
        }

        let notice = Notice(
            title: Strings.postRemoved,
            feedbackType: .success,
            actionTitle: SharedStrings.Button.undo,
            actionHandler: { _ in
                self.trackSaveAction(for: post, origin: origin)
                MainActor.assumeIsolated {
                    self.toggleSavedForLater(post, context: context, origin: origin, completion: completion)
                }
            }
        )

        present(notice)
    }

    private func presentErrorNotice(_ error: Error?, activating: Bool) {
        Loggers.app.error("Could not toggle save for later: \(String(describing: error))")

        let title = activating ? Strings.addToSavedError : Strings.removeFromSavedError

        let notice = Notice(
            title: title,
            message: Self.errorMessage(for: error),
            feedbackType: .error
        )

        present(notice)
    }

    private static func errorMessage(for error: Error?) -> String? {
        switch error {
        case let error as ReaderSavedError:
            switch error {
            case .Api(let apiError): apiError.localizedDescription
            // The title already says the post couldn't be saved.
            case .PostCannotBeSaved: nil
            default: error.localizedDescription
            }
        default:
            error?.localizedDescription
        }
    }

    private func present(_ notice: Notice) {
        ActionDispatcher.dispatch(NoticeAction.post(notice))
    }

    private func presentReaderSavedPostsAlertControllerIfNecessary(from origin: UIViewController) {
        guard !UserPersistentStoreFactory.instance().savedPostsPromoWasDisplayed else {
            return
        }
        UserPersistentStoreFactory.instance().savedPostsPromoWasDisplayed = true

        let alert = AlertView {
            AlertHeaderView(title: Strings.promoTitle, description: Strings.promoDescription)
        } content: {
            ScaledImage("wpl-bookmark", height: 78)
                .foregroundStyle(.secondary)
        } actions: {
            AlertDismissButton()
        }
        alert.present(in: origin)
    }
}
