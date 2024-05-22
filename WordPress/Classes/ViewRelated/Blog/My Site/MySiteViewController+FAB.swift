import UIKit
import SwiftUI

extension MySiteViewController {

    /// Make a create button coordinator with
    /// - Returns: CreateButtonCoordinator with new post, page, and story actions.
    @objc func makeCreateButtonCoordinator() -> CreateButtonCoordinator {

        let newPage = {
            let presenter = RootViewCoordinator.sharedPresenter
            let blog = presenter.currentOrLastBlog()
            presenter.showPageEditor(forBlog: blog)
        }

        let newPost = { [weak self] in
            let presenter = RootViewCoordinator.sharedPresenter
            presenter.showPostTab(completion: {
                self?.startAlertTimer()
            })
        }

        let newStory = {
            let presenter = RootViewCoordinator.sharedPresenter
            let blog = presenter.currentOrLastBlog()
            presenter.showStoryEditor(forBlog: blog)
        }

        let source = "my_site"

        var actions: [ActionSheetItem] = []

        if blog?.supports(.stories) ?? false {
            actions.append(StoryAction(handler: newStory, source: source))
        }

        actions.append(PostAction(handler: newPost, source: source))
        // TODO: check if the current site is eligible
        if FeatureFlag.voiceToContent.enabled {
            actions.append(PostFromAudioAction(handler: { [weak self] in
                self?.dismiss(animated: true) {
                    self?.startPostFromAudioFlow()
                }
            }, source: source))
        }
        if blog?.supports(.pages) ?? false {
            actions.append(PageAction(handler: newPage, source: source))
        }

        let coordinator = CreateButtonCoordinator(self, actions: actions, source: source, blog: blog)
        return coordinator
    }

    private func startPostFromAudioFlow() {
        guard let blog else {
            wpAssertionFailure("blog missing")
            return
        }
        let viewModel = VoiceToContentViewModel(blog: blog) { [weak self] transcription in
            guard let self else { return }
            self.dismiss(animated: true) {
                // TODO: Are we adding all necessary fields?
                let presenter = RootViewCoordinator.sharedPresenter
                let post = blog.createDraftPost()
                post.content = """
                <!-- wp:paragraph -->
                <p>\(transcription.escapeHtmlNamedEntities())</p>
                <!-- /wp:paragraph -->
                """
                presenter.showPostTab(animated: true, post: post)
            }
        }
        let view = VoiceToContentView(viewModel: viewModel)
        let host = UIHostingController(rootView: view)

        if UIDevice.isPad() {
            host.modalPresentationStyle = .formSheet
        } else {
            if let sheetController = host.sheetPresentationController {
                sheetController.detents = [.medium()]
                sheetController.preferredCornerRadius = 16
            }
        }
        present(host, animated: true)
    }
}
