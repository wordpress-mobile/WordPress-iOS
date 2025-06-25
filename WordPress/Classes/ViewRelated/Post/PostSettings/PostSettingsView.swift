import UIKit
import CoreData
import Combine
import WordPressData
import WordPressKit
import WordPressShared
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
    }

    @preconcurrency required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct PostSettingsView: View {
    @ObservedObject var viewModel: PostSettingsViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Form {
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
            .opacity(viewModel.isSaving ? 0.6 : 1.0)
            .disabled(viewModel.isSaving)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(SharedStrings.Button.cancel) {
                    viewModel.cancel()
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                if viewModel.isSaving {
                    ProgressView()
                } else {
                    Button(SharedStrings.Button.save) {
                        Task {
                            await viewModel.save()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!viewModel.hasChanges)
                }
            }
        }
        .interactiveDismissDisabled(viewModel.isSaving || viewModel.hasChanges)
        .onAppear {
            viewModel.onDismiss = {
                dismiss()
            }
        }
        .alert(viewModel.deletedAlertTitle, isPresented: $viewModel.isShowingDeletedAlert) {
            Button(SharedStrings.Button.ok) {
                dismiss()
            }
        } message: {
            Text(viewModel.deletedAlertMessage)
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
}
