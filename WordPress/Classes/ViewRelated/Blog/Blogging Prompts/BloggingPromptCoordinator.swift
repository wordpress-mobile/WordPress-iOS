import UIKit

class BloggingPromptCoordinator {

    private let promptsServiceFactory: BloggingPromptsServiceFactory

    enum Errors: Error {
        case invalidSite
    }

    // MARK: Public Method

    init(bloggingPromptsServiceFactory: BloggingPromptsServiceFactory = .init()) {
        self.promptsServiceFactory = bloggingPromptsServiceFactory
    }

    func present(from viewController: UIViewController, promptID: Int? = nil, blog: Blog, completion: @escaping (Result<Void, Error>) -> Void) {

        // TODO: Switch site if needed.

        // TODO: Fetch prompts if needed. Try to load local prompts first.
        if let promptID = promptID {
            // load local prompt.
        } else {

        }

        // TODO: Update reminder settings.

        // Finally, present!
    }

}

// MARK: Private Helpers

private extension BloggingPromptCoordinator {

    func fetchPrompt(with promptID: Int? = nil, blog: Blog, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let service = promptsServiceFactory.makeService(for: blog) else {
            completion(.failure(Errors.invalidSite))
            return
        }

        // TODO: Load local prompts first.
    }

}
