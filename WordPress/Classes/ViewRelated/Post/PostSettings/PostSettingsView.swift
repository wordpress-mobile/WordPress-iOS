import UIKit
import CoreData
import Combine
import WordPressData
import WordPressKit
import WordPressShared
import WordPressUI
import SwiftUI

final class NewPostSettingsViewController: UIHostingController<AnyView> {
    private let viewModel: PostSettingsViewModel

    init(viewModel: PostSettingsViewModel) {
        self.viewModel = viewModel
        let postSettingsView = PostSettingsView(viewModel: viewModel)
        super.init(rootView: AnyView(postSettingsView))
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = viewModel.navigationTitle

        viewModel.onDismiss = { [weak self] in
            self?.presentingViewController?.dismiss(animated: true)
        }
    }

    @preconcurrency required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

@MainActor
private struct PostSettingsView: View {
    @ObservedObject var viewModel: PostSettingsViewModel
    @State private var isShowingDiscardChangesAlert = false

    var body: some View {
        Form {
            form
        }
        .opacity(viewModel.isSaving ? 0.6 : 1.0)
        .disabled(viewModel.isSaving)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(SharedStrings.Button.cancel) {
                    if viewModel.hasChanges {
                        isShowingDiscardChangesAlert = true
                    } else {
                        viewModel.buttonCancelTapped()
                    }
                }
                .tint(AppColor.tint)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                if viewModel.isSaving {
                    ProgressView()
                } else {
                    Group {
                        if viewModel.isStandalone {
                            Button(SharedStrings.Button.save) {
                                viewModel.buttonSaveTapped()
                            }
                            .buttonStyle(.borderedProminent)
                            .buttonBorderShape(.capsule)
                        } else {
                            Button(SharedStrings.Button.done) {
                                viewModel.buttonSaveTapped()
                            }
                            .fontWeight(.medium)
                        }
                    }
                    .disabled(!viewModel.hasChanges)
                    .tint(AppColor.tint)
                }
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
        .confirmationDialog(Strings.discardChangesTitle, isPresented: $isShowingDiscardChangesAlert) {
            Button(Strings.discardChangesButton, role: .destructive) {
                viewModel.buttonCancelTapped()
            }
            Button(SharedStrings.Button.cancel, role: .cancel) {
                // Do nothing - continue editing
            }
        } message: {
            Text(Strings.discardChangesMessage)
        }
    }

    @ViewBuilder
    private var form: some View {
        generalSection
    }

    @ViewBuilder
    private var generalSection: some View {
        Section {
            if viewModel.isMultiAuthorBlog {
                authorRow
            }
            if viewModel.isDraftOrPending {
                pendingReviewRow
            } else {
                // Publish date picker
                NavigationLink {
                    PublishDatePickerView(configuration: PublishDatePickerConfiguration(
                        date: viewModel.settings.publishDate,
                        isRequired: false,
                        timeZone: viewModel.timeZone,
                        updated: { date in
                            viewModel.settings.publishDate = date
                        }
                    ))
                } label: {
                    SettingsRow(title: Strings.publishDateLabel, value: viewModel.publishDateText)
                }

                // Visibility picker
                NavigationLink {
                    PostVisibilityPicker(
                        selection: PostVisibilityPicker.Selection(post: viewModel.post),
                        onSubmit: { selection in
                            viewModel.updateVisibility(selection)
                        }
                    )
                } label: {
                    SettingsRow(title: Strings.visibilityLabel, value: viewModel.visibilityText)
                }
            }
        }
    }

    private var authorRow: some View {
        NavigationLink {
            PostAuthorPicker(
                blog: viewModel.post.blog,
                currentAuthorID: viewModel.settings.author?.id
            ) { selection in
                viewModel.settings.updateAuthor(with: selection)
            }
        } label: {
            PostSettingsAuthorRow(author: viewModel.settings.author)
        }
    }

    private var pendingReviewRow: some View {
        Toggle(isOn: $viewModel.settings.isPendingReview) {
            Text(Strings.pendingReviewLabel)
        }
    }
}

@MainActor
private struct PostSettingsAuthorRow: View {
    let author: PostSettings.Author?

    var body: some View {
        HStack(spacing: 6) {
            Text(Strings.authorLabel)
            Spacer()
            if let author {
                AvatarView(style: .single(author.avatarURL), diameter: 22)
                Text(author.displayName)
                    .foregroundColor(.secondary)
            } else {
                Text("—")
                    .foregroundColor(.secondary)
            }
        }
    }
}

@MainActor
private struct SettingsRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
        }
    }
}

private enum Strings {
    static let generalHeader = NSLocalizedString(
        "postSettings.section.general",
        value: "General",
        comment: "Section header for General settings in Post Settings"
    )

    static let moreOptionsHeader = NSLocalizedString(
        "postSettings.section.moreOptions",
        value: "More Options",
        comment: "Section header for More Options in Post Settings"
    )

    static let authorLabel = NSLocalizedString(
        "postSettings.author.label",
        value: "Author",
        comment: "Label for the author field in Post Settings"
    )

    static let publishDateLabel = NSLocalizedString(
        "postSettings.publishDate.label",
        value: "Publish Date",
        comment: "Label for the publish date field in Post Settings"
    )

    static let visibilityLabel = NSLocalizedString(
        "postSettings.visibility.label",
        value: "Visibility",
        comment: "Label for the visibility field in Post Settings"
    )

    static let pendingReviewLabel = NSLocalizedString(
        "postSettings.pendingReview.label",
        value: "Pending Review",
        comment: "Label for the pending review toggle in Post Settings"
    )

    static let slugLabel = NSLocalizedString(
        "postSettings.slug.label",
        value: "Slug",
        comment: "Label for the slug field. Should be the same as WP core."
    )

    static let slugPlaceholder = NSLocalizedString(
        "postSettings.slug.placeholder",
        value: "Enter slug",
        comment: "Placeholder text for the slug field"
    )

    static let discardChangesTitle = NSLocalizedString(
        "postSettings.discardChanges.title",
        value: "Discard Changes?",
        comment: "Title for the discard changes confirmation dialog"
    )

    static let discardChangesMessage = NSLocalizedString(
        "postSettings.discardChanges.message",
        value: "You have unsaved changes. Are you sure you want to discard them?",
        comment: "Message for the discard changes confirmation dialog"
    )

    static let discardChangesButton = NSLocalizedString(
        "postSettings.discardChanges.button",
        value: "Discard Changes",
        comment: "Button to confirm discarding changes"
    )
}
