import SwiftUI
import WordPressUI
import WordPressKit
import WordPressData
import SVProgressHUD

struct EditTagView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: EditTagViewModel

    init(tag: RemotePostTag?, tagsService: TagsService) {
        self._viewModel = StateObject(wrappedValue: EditTagViewModel(tag: tag, tagsService: tagsService))
    }

    var body: some View {
        Form {
            Section(Strings.tagSectionHeader) {
                HStack {
                    TextField(Strings.tagNamePlaceholder, text: $viewModel.tagName)
                        .textFieldStyle(.plain)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .keyboardType(.default)

                    if !viewModel.tagName.isEmpty {
                        Button(action: {
                            viewModel.tagName = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }

            Section(Strings.descriptionSectionHeader) {
                TextField(Strings.descriptionPlaceholder, text: $viewModel.tagDescription, axis: .vertical)
                    .textFieldStyle(.plain)
                    .lineLimit(5...15)
            }

            if viewModel.isExistingTag {
                Section {
                    Button(action: {
                        viewModel.showDeleteConfirmation = true
                    }) {
                        Text(SharedStrings.Button.delete)
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .navigationTitle(viewModel.navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(SharedStrings.Button.save) {
                    Task {
                        let success = await viewModel.saveTag()
                        if success {
                            dismiss()
                        }
                    }
                }
                .disabled(viewModel.tagName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .confirmationDialog(
            Strings.deleteConfirmationTitle,
            isPresented: $viewModel.showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button(SharedStrings.Button.delete, role: .destructive) {
                Task {
                    let success = await viewModel.deleteTag()
                    if success {
                        dismiss()
                    }
                }
            }
            Button(SharedStrings.Button.cancel, role: .cancel) { }
        } message: {
            Text(Strings.deleteConfirmationMessage)
        }
        .alert(SharedStrings.Error.generic, isPresented: $viewModel.showError) {
            Button(SharedStrings.Button.ok) { }
        } message: {
            Text(viewModel.errorMessage)
        }
    }
}

@MainActor
class EditTagViewModel: ObservableObject {
    @Published var tagName: String
    @Published var tagDescription: String
    @Published var showDeleteConfirmation = false
    @Published var showError = false
    @Published var errorMessage = ""

    private let originalTag: RemotePostTag?
    private let tagsService: TagsService

    var isExistingTag: Bool {
        originalTag != nil
    }

    var navigationTitle: String {
        originalTag?.name ?? Strings.newTagTitle
    }

    init(tag: RemotePostTag?, tagsService: TagsService) {
        self.originalTag = tag
        self.tagsService = tagsService
        self.tagName = tag?.name ?? ""
        self.tagDescription = tag?.tagDescription ?? ""
    }

    func deleteTag() async -> Bool {
        guard let tag = originalTag else { return false }

        SVProgressHUD.show()
        defer { SVProgressHUD.dismiss() }

        do {
            try await tagsService.deleteTag(tag)

            // Post notification to update the UI
            NotificationCenter.default.post(
                name: .tagDeleted,
                object: nil,
                userInfo: [TagNotificationUserInfoKeys.tagID: tag.tagID ?? 0]
            )
            return true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            return false
        }
    }

    func saveTag() async -> Bool {
        SVProgressHUD.show()
        defer { SVProgressHUD.dismiss() }

        let tagToSave: RemotePostTag
        if let existingTag = originalTag {
            tagToSave = existingTag
        } else {
            tagToSave = RemotePostTag()
        }

        tagToSave.name = tagName.trimmingCharacters(in: .whitespacesAndNewlines)
        tagToSave.tagDescription = tagDescription.trimmingCharacters(in: .whitespacesAndNewlines)

        do {
            let savedTag = try await tagsService.saveTag(tagToSave)

            NotificationCenter.default.post(
                name: originalTag == nil ? .tagCreated : .tagUpdated,
                object: nil,
                userInfo: [TagNotificationUserInfoKeys.tag: savedTag]
            )
            return true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            return false
        }
    }
}

private enum Strings {
    static let tagSectionHeader = NSLocalizedString(
        "edit.tag.section.tag",
        value: "Tag",
        comment: "Section header for tag name in edit tag view"
    )

    static let descriptionSectionHeader = NSLocalizedString(
        "edit.tag.section.description",
        value: "Description",
        comment: "Section header for tag description in edit tag view"
    )

    static let tagNamePlaceholder = NSLocalizedString(
        "edit.tag.name.placeholder",
        value: "Tag name",
        comment: "Placeholder text for tag name field"
    )

    static let descriptionPlaceholder = NSLocalizedString(
        "edit.tag.description.placeholder",
        value: "Add a description...",
        comment: "Placeholder text for tag description field"
    )

    static let newTagTitle = NSLocalizedString(
        "edit.tag.new.title",
        value: "New Tag",
        comment: "Navigation title for new tag creation"
    )

    static let deleteConfirmationTitle = NSLocalizedString(
        "edit.tag.delete.confirmation.title",
        value: "Delete Tag",
        comment: "Title for delete tag confirmation dialog"
    )

    static let deleteConfirmationMessage = NSLocalizedString(
        "edit.tag.delete.confirmation.message",
        value: "Are you sure you want to delete this tag?",
        comment: "Message for delete tag confirmation dialog"
    )
}
