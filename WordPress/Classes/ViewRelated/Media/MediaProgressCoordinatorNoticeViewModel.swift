
struct MediaProgressCoordinatorNoticeViewModel {
    private let mediaProgressCoordinator: MediaProgressCoordinator
    private let progress: Progress

    init?(mediaProgressCoordinator: MediaProgressCoordinator) {
        guard !mediaProgressCoordinator.isRunning,
            let progress = mediaProgressCoordinator.mediaGlobalProgress else {
                return nil
        }

        guard !mediaProgressCoordinator.hasFailedMedia else {
            return nil
        }

        self.mediaProgressCoordinator = mediaProgressCoordinator
        self.progress = progress
    }

    var notice: Notice? {
        if let blog = blogInContext {
            return Notice(title: title,
                          actionTitle: actionTitle,
                          actionHandler: {
                            let editor = EditPostViewController(blog: blog)
                            editor.modalPresentationStyle = .fullScreen
                            WPTabBarController.sharedInstance().present(editor, animated: false, completion: nil)
                            WPAppAnalytics.track(.editorCreatedPost, withProperties: ["tap_source": "media_upload_notice"], with: blog)
            })
        } else {
            return Notice(title: title)
        }
    }

    var title: String {
        let completedUnits = progress.completedUnitCount
        if completedUnits == 1 {
            return NSLocalizedString("Media uploaded (1 file)", comment: "Alert displayed to the user when a single media item has uploaded successfully.")
        } else {
            return String(format: NSLocalizedString("Media uploaded (%ld files)", comment: "Alert displayed to the user when multiple media items have uploaded successfully."), completedUnits)
        }
    }

    let actionTitle: String = NSLocalizedString("Write Post", comment: "Button title. Opens the editor to write a new post.")

    private var blogInContext: Blog? {
        guard let mediaID = mediaProgressCoordinator.inProgressMediaIDs.first,
            let media = mediaProgressCoordinator.media(withIdentifier: mediaID) else {
                return nil
        }

        let context = ContextManager.sharedInstance().mainContext

        var blog = media.blog
        if blog.managedObjectContext != context,
            let objectInContext = try? context.existingObject(with: blog.objectID),
            let blogInContext = objectInContext as? Blog {
            blog = blogInContext
        }

        return blog
    }
}
