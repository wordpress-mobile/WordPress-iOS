import UIKit

/// Helps manage the flow related to Blogging Prompts.
///
@objc class BloggingPromptCoordinator: NSObject {

    private let promptsServiceFactory: BloggingPromptsServiceFactory

    enum Errors: Error {
        case invalidSite
        case promptNotFound
        case unknown
    }

    /// Defines the interaction sources for Blogging Prompts.
    enum Source {
        case dashboard
        case featureIntroduction
        case actionSheetHeader
        case promptNotification
        case promptStaticNotification
        case unknown

        var editorEntryPoint: PostEditorEntryPoint {
            switch self {
            case .dashboard:
                return .dashboard
            case .featureIntroduction:
                return .bloggingPromptsFeatureIntroduction
            case .actionSheetHeader:
                return .bloggingPromptsActionSheetHeader
            case .promptNotification, .promptStaticNotification:
                return .bloggingPromptsNotification
            default:
                return .unknown
            }
        }
    }

    // MARK: Public Method

    init(bloggingPromptsServiceFactory: BloggingPromptsServiceFactory = .init()) {
        self.promptsServiceFactory = bloggingPromptsServiceFactory
    }

    /// Present the post creation flow to answer the prompt with `promptID`.
    ///
    /// - Note: When the `promptID` is nil, the coordinator will attempt to fetch and use today's prompt from remote.
    ///
    /// - Parameters:
    ///   - viewController: The view controller that will present the post creation flow.
    ///   - promptID: The ID of the blogging prompt. When nil, the method will use today's prompt.
    ///   - blog: The blog associated with the blogging prompt.
    ///   - completion: Closure invoked after the post creation flow is presented.
    func showPromptAnsweringFlow(from viewController: UIViewController,
                                 promptID: Int? = nil,
                                 blog: Blog,
                                 source: Source,
                                 completion: (() -> Void)? = nil) {
        fetchPrompt(with: promptID, blog: blog) { result in
            guard case .success(let prompt) = result else {
                completion?()
                return
            }

            // Present the post creation flow.
            let editor = EditPostViewController(blog: blog, prompt: prompt)
            editor.modalPresentationStyle = .fullScreen
            editor.entryPoint = source.editorEntryPoint
            viewController.present(editor, animated: true)
            completion?()
        }
    }
}

// MARK: Private Helpers

private extension BloggingPromptCoordinator {

    func fetchPrompt(with localPromptID: Int? = nil, blog: Blog, completion: @escaping (Result<BloggingPrompt, Error>) -> Void) {
        guard let service = promptsServiceFactory.makeService(for: blog) else {
            completion(.failure(Errors.invalidSite))
            return
        }

        // When the promptID is specified, there may be a cached prompt available.
        if let promptID = localPromptID,
           let prompt = service.loadPrompt(with: promptID, in: blog) {
            completion(.success(prompt))
            return
        }

        // Otherwise, try to fetch today's prompt from remote.
        service.fetchTodaysPrompt { prompt in
            guard let prompt = prompt else {
                completion(.failure(Errors.promptNotFound))
                return
            }
            completion(.success(prompt))

        } failure: { error in
            completion(.failure(error ?? Errors.unknown))
        }
    }

}
