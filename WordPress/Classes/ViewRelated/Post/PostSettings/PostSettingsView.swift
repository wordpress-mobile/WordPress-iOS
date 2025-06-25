import UIKit
import CoreData
import Combine
import WordPressData
import WordPressKit
import WordPressShared
import WordPressUI
import SwiftUI

final class NewPostSettingsViewController: UIHostingController<PostSettingsView> {
    private let viewModel: PostSettingsViewModel

    init(viewModel: PostSettingsViewModel) {
        self.viewModel = viewModel
        let postSettingsView = PostSettingsView(viewModel: viewModel)
        super.init(rootView: postSettingsView)
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
        Section(header: Text(Strings.moreOptionsHeader)) {
            HStack {
                Text(Strings.slugLabel)
                Spacer()
                TextField(Strings.slugPlaceholder, text: $viewModel.settings.slug)
                    .textFieldStyle(.plain)
                    .multilineTextAlignment(.trailing)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
            }
        }
    }
}

private enum Strings {
    static let moreOptionsHeader = NSLocalizedString(
        "postSettings.section.moreOptions",
        value: "More Options",
        comment: "Section header for More Options in Post Settings"
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
