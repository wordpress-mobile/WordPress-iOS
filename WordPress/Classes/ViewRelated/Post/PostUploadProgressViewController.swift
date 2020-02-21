import Foundation

/// This class controls the setup and update of a standard UIProgressView
/// used to reflect the upload progress of a post (or page).
///
class PostUploadProgressViewController {
    private let viewModel: PostUploadProgressViewModel
    private let onUploadComplete: () -> ()

    init(with post: AbstractPost, onUploadComplete: @escaping () -> ()) {
        self.onUploadComplete = onUploadComplete
        viewModel = PostUploadProgressViewModel(for: post)
    }

    /// Configure the provided progress view based on the progress of the
    /// post passed on initialization to this controller.
    ///
    /// - Parameters:
    ///     - progressView: the view that this controller will configure.
    ///
    func configure(_ progressView: UIProgressView) {
        let shouldHide = viewModel.shouldHideProgressView()

        guard !shouldHide else {
            progressView.isHidden = true
            progressView.progress = 0
            viewModel.progressBlock = nil
            return
        }

        progressView.isHidden = false
        progressView.progress = viewModel.progress()

        if viewModel.progressBlock == nil {
            viewModel.progressBlock = { [weak self] progress in
                progressView.setProgress(progress, animated: true)

                if progress >= 1.0 {
                    self?.hide(progressView)
                    self?.onUploadComplete()
                }
            }
        }
    }

    private func hide(_ progressView: UIProgressView) {
        progressView.isHidden = true
        progressView.progress = 0
        viewModel.progressBlock = nil
    }
}
