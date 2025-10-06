import UIKit
import Combine
import SwiftUI
import WordPressData
import WordPressShared
import WordPressUI

enum PublishingSheetResult {
    /// The sheet published the post (new behavior)
    case published
    /// The user cancelled publishing.
    ///
    /// - parameter isSaved: If `true`, the changes to the settings made in
    /// the publishing sheet were saved.
    case cancelled(isSaved: Bool = false)
}

/// A screen shown just before publishing the post and allows you to change
/// the post settings along with some publishing options like the publish date.
final class PublishPostViewController: UIHostingController<PublishPostView> {
    private let viewModel: PostSettingsViewModel
    private let uploadsViewModel: PostMediaUploadsViewModel

    var onCompletion: ((PublishingSheetResult) -> Void)?

    init(post: AbstractPost, isStandalone: Bool) {
        let viewModel = PostSettingsViewModel(
            post: post,
            isStandalone: isStandalone,
            context: .publishing
        )
        self.viewModel = viewModel

        let uploadsViewModel = PostMediaUploadsViewModel(post: post)
        self.uploadsViewModel = uploadsViewModel

        let view = PublishPostView(viewModel: viewModel, uploadsViewModel: uploadsViewModel)
        super.init(rootView: view)
    }

    static func show(for revision: AbstractPost, isStandalone: Bool = false, from presentingViewController: UIViewController, completion: @escaping (PublishingSheetResult) -> Void) {
        // End editing to avoid issues with accessibility
        presentingViewController.view.endEditing(true)

        let publishVC = PublishPostViewController(post: revision, isStandalone: isStandalone)
        publishVC.onCompletion = completion
        // - warning: Has to be UIKit because some of the  `PostSettingsView` rows rely on it.
        let navigationVC = UINavigationController(rootViewController: publishVC)
        navigationVC.sheetPresentationController?.detents = [
            .custom(identifier: .medium, resolver: { context in 526 }),
            .large()
        ]
        presentingViewController.present(navigationVC, animated: true)
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        viewModel.onEditorPostSaved = { [weak self] in
            self?.onCompletion?(.cancelled(isSaved: true))
        }

        viewModel.onPostPublished = { [weak self] in
            self?.onCompletion?(.published)
        }
        viewModel.onDismiss = { [weak self] in
            self?.presentingViewController?.dismiss(animated: true)
        }

        // Set the view controller reference for navigation
        // This is temporary until we can fully migrate to SwiftUI navigation
        viewModel.viewController = self
    }
}

struct PublishPostView: View {
    @ObservedObject var viewModel: PostSettingsViewModel
    @ObservedObject var uploadsViewModel: PostMediaUploadsViewModel

    @State private var isShowingDiscardChangesAlert = false

    var post: AbstractPost { viewModel.post }

    var body: some View {
        Form {
            if let state = uploadsViewModel.uploadingSnackbarState {
                NavigationLink {
                    PostMediaUploadsView(viewModel: uploadsViewModel)
                } label: {
                    PostMediaUploadsSnackbarView(state: state)
                }
            }
            PostSettingsFormContentView(viewModel: viewModel)
        }
        .environment(\.defaultMinListHeaderHeight, 0) // Reduces top inset a bit
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.onAppear()
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                buttonCancel
                    .confirmationDialog(Strings.discardChangesTitle, isPresented: $isShowingDiscardChangesAlert) {
                        Button(Strings.saveChangesButton) {
                            viewModel.buttonSaveTapped()
                        }
                        // - warning: It's important for the destructive button to
                        // be at the bottom or "Save" will not be shown
                        Button(Strings.discardChangesButton, role: .destructive) {
                            viewModel.buttonCancelTapped()
                        }
                    } message: {
                        Text(Strings.discardChangesMessage)
                    }
            }
            ToolbarItemGroup(placement: .topBarTrailing) {
                buttonPublish
            }
        }
        .interactiveDismissDisabled(viewModel.isSaving || viewModel.hasChanges)
        .alert(viewModel.deletedAlertTitle, isPresented: $viewModel.isShowingDeletedAlert) {
            Button(SharedStrings.Button.ok) {
                viewModel.onDismiss?()
            }
        } message: {
            Text(viewModel.deletedAlertMessage)
        }
        .disabled(viewModel.isSaving)
    }

    // MARK: – Actions

    @ViewBuilder
    private var buttonCancel: some View {
        if #available(iOS 26, *) {
            Button(role: .cancel, action: buttonCancelTapped)
        } else {
            Button(SharedStrings.Button.cancel, action: buttonCancelTapped)
                .tint(AppColor.tint)
        }
    }

    private func buttonCancelTapped() {
        if viewModel.hasChanges {
            isShowingDiscardChangesAlert = true
        } else {
            viewModel.buttonCancelTapped()
        }
    }

    @ViewBuilder
    private var buttonPublish: some View {
        if viewModel.isSaving {
            ProgressView()
        } else {
            let isDisabled = !uploadsViewModel.isCompleted

            Button(viewModel.publishButtonTitle) {
                viewModel.buttonPublishTapped()
            }
            .fontWeight(.medium)
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .tint(isDisabled ? Color(.opaqueSeparator) : AppColor.primary)
            .disabled(isDisabled)
            .accessibilityIdentifier("publish")
        }
    }
}

private extension PostSettingsViewModel {
    var publishButtonTitle: String {
        let isScheduled = settings.publishDate.map { $0 > .now } ?? false
        return isScheduled ? Strings.schedule : Strings.publish
    }
}

private typealias Strings = PrepublishingSheetStrings

enum PrepublishingSheetStrings {
    static let title = NSLocalizedString("prepublishing.title", value: "Publishing", comment: "Navigation title")
    static let publishingTo = NSLocalizedString("prepublishing.publishingTo", value: "Publishing to", comment: "Label in the header in the pre-publishing sheet")
    static let publish = NSLocalizedString("prepublishing.publish", value: "Publish", comment: "Primary button label in the pre-publishing sheet")
    static let schedule = NSLocalizedString("prepublishing.schedule", value: "Schedule", comment: "Primary button label in the pre-publishing shee")
    static let publishDate = NSLocalizedString("prepublishing.publishDate", value: "Publish Date", comment: "Label for a cell in the pre-publishing sheet")
    static let visibility = NSLocalizedString("prepublishing.visibility", value: "Visibility", comment: "Label for a cell in the pre-publishing sheet")
    static let categories = NSLocalizedString("prepublishing.categories", value: "Categories", comment: "Label for a cell in the pre-publishing sheet")
    static let tags = NSLocalizedString("prepublishing.tags", value: "Tags", comment: "Label for a cell in the pre-publishing sheet")
    static let jetpackSocial = NSLocalizedString("prepublishing.jetpackSocial", value: "Jetpack Social", comment: "Label for a cell in the pre-publishing sheet")
    static let immediately = NSLocalizedString("prepublishing.publishDateImmediately", value: "Immediately", comment: "Placeholder value for a publishing date in the prepublishing sheet when the date is not selected")
    static let uploadingMedia = NSLocalizedString("prepublishing.uploadingMedia", value: "Uploading media", comment: "Title for a publish button state in the pre-publishing sheet")
    private static let uploadMediaOneItemRemaining = NSLocalizedString("prepublishing.uploadMediaOneItemRemaining", value: "%@ item remaining", comment: "Details label for a publish button state in the pre-publishing sheet")
    private static let uploadMediaManyItemsRemaining = NSLocalizedString("prepublishing.uploadMediaManyItemsRemaining", value: "%@ items remaining", comment: "Details label for a publish button state in the pre-publishing sheet")
    static func uploadMediaRemaining(count: Int) -> String {
        String(format: count == 1 ? Strings.uploadMediaOneItemRemaining : Strings.uploadMediaManyItemsRemaining, count.description)
    }
    static let mediaUploadFailedTitle = NSLocalizedString("prepublishing.mediaUploadFailedTitle", value: "Failed to upload media", comment: "Title for a publish button state in the pre-publishing sheet")
    static let mediaUploadFailedDetailsMultipleFailures = NSLocalizedString("prepublishing.mediaUploadFailedDetails", value: "%@ items failed to upload", comment: "Details for a publish button state in the pre-publishing sheet; count as a parameter")

    static let discardChangesTitle = NSLocalizedString(
        "prepublishing.discardChanges.title",
        value: "Discard Changes?",
        comment: "Title for the discard changes confirmation dialog"
    )

    static let discardChangesMessage = NSLocalizedString(
        "prepublishing.discardChanges.message",
        value: "You have unsaved changes to the post settings. Are you sure you want to discard them?",
        comment: "Message for the discard changes confirmation dialog"
    )

    static let discardChangesButton = NSLocalizedString(
        "prepublishing.discardChanges.button",
        value: "Discard Changes",
        comment: "Button to confirm discarding changes"
    )

    static let saveChangesButton = NSLocalizedString(
        "prepublishing.saveChanges.button",
        value: "Save Changes",
        comment: "Button to confirm discarding changes"
    )
}
