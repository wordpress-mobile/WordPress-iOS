import SwiftUI
import WordPressUI
import WordPressKit
import WordPressData
import WordPressAPI
import SVProgressHUD

struct EditTagView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: EditTagViewModel

    init(term: AnyTermWithViewContext?, tagsService: TagsService) {
        self._viewModel = StateObject(wrappedValue: EditTagViewModel(term: term, tagsService: tagsService))
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

    private let originalTerm: AnyTermWithViewContext?
    private let tagsService: TagsService

    var isExistingTag: Bool {
        originalTerm != nil
    }

    var navigationTitle: String {
        originalTerm?.name ?? Strings.newTagTitle
    }

    init(term: AnyTermWithViewContext?, tagsService: TagsService) {
        self.originalTerm = term
        self.tagsService = tagsService
        self.tagName = term?.name ?? ""
        self.tagDescription = term?.description ?? ""
    }

    func deleteTag() async -> Bool {
        guard let term = originalTerm else { return false }

        SVProgressHUD.show()
        defer { SVProgressHUD.dismiss() }

        do {
            try await tagsService.deleteTag(term)

            NotificationCenter.default.post(
                name: .tagDeleted,
                object: nil,
                userInfo: [TagNotificationUserInfoKeys.tagID: NSNumber(value: term.id)]
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

        do {
            let savedTerm: AnyTermWithViewContext

            if let existingTerm = originalTerm {
                savedTerm = try await tagsService.updateTag(
                    existingTerm,
                    name: tagName.trimmingCharacters(in: .whitespacesAndNewlines),
                    description: tagDescription.trimmingCharacters(in: .whitespacesAndNewlines)
                )
            } else {
                savedTerm = try await tagsService.createTag(
                    name: tagName.trimmingCharacters(in: .whitespacesAndNewlines),
                    description: tagDescription.trimmingCharacters(in: .whitespacesAndNewlines)
                )
            }

            NotificationCenter.default.post(
                name: originalTerm == nil ? .tagCreated : .tagUpdated,
                object: nil,
                userInfo: [TagNotificationUserInfoKeys.tag: savedTerm]
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
