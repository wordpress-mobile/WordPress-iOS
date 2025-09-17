import UIKit
import Combine
import SwiftUI
import WordPressData
import WordPressShared
import WordPressUI

/// A screen shown just before publishing the post and allows you to change
/// the post settings along with some publishing options like the publish date.
final class PublishPostViewController: UIHostingController<NavigationView<PublishPostView>> {
    private let settingsViewModel: PostSettingsViewModel

    init(post: AbstractPost) {
        // TODO: add isStandalone support
        let settingsViewModel = PostSettingsViewModel(
            post: post,
            isStandalone: true,
            context: .publishing
        )
        self.settingsViewModel = settingsViewModel
        super.init(rootView: NavigationView { PublishPostView(settingsViewModel: settingsViewModel) })
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct PublishPostView: View {
    @ObservedObject var settingsViewModel: PostSettingsViewModel

    var post: AbstractPost { settingsViewModel.post }

    // TODO: (publish) figure out the media upload situation
    var body: some View {
        Form {
            PostSettingsFormContentView(viewModel: settingsViewModel)
        }
        .environment(\.defaultMinListHeaderHeight, 0) // Reduces top inset a bit
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                buttonCancel
            }
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    // TODO: (publish) show preview
                } label: {
                    Image(systemName: "safari")
                }
                buttonPublish
            }
        }
    }

    @ViewBuilder
    private var buttonCancel: some View {
        // TODO: (publish) connect to actual hasChanges
        if #available(iOS 26, *) {
            Button(role: .cancel, action: buttonCancelTapped)
        } else {
            Button(SharedStrings.Button.cancel, action: buttonCancelTapped)
                .tint(AppColor.tint)
        }
    }

    private func buttonCancelTapped() {
        if settingsViewModel.hasChanges {
            // TODO: implement isShowingDiscardChangesAlert
//                isShowingDiscardChangesAlert = true
        } else {
            settingsViewModel.buttonCancelTapped()
        }
    }

    @ViewBuilder
    private var buttonPublish: some View {
        // TODO: connect to actual isSaving and save
        if settingsViewModel.isSaving {
            ProgressView()
        } else {
            // TODO: change dyncam to "Schedule"
            Button(Strings.publish) {
                settingsViewModel.buttonSaveTapped()
            }
            .fontWeight(.medium)
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .tint(AppColor.primary)
        }
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
}
