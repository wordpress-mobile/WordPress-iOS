import SwiftUI
import WordPressUI
import WordPressKit
import WordPressData
import WordPressAPI
import SVProgressHUD

struct EditTagView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: EditTagViewModel

    init(term: AnyTermWithViewContext?, taxonomy: SiteTaxonomy?, tagsService: TaxonomyServiceProtocol) {
        self._viewModel = StateObject(wrappedValue: EditTagViewModel(term: term, taxonomy: taxonomy, tagsService: tagsService))
    }

    var body: some View {
        Form {
            Section {
                HStack {
                    TextField(viewModel.localizedLabels.newPlaceholder, text: $viewModel.tagName)
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
            } header: {
                Text(Strings.tagSectionHeader)
            } footer: {
                if let text = viewModel.localizedLabels.nameFieldDescription {
                    Text(verbatim: text)
                }
            }

            Section {
                TextField(Strings.descriptionPlaceholder, text: $viewModel.tagDescription, axis: .vertical)
                    .textFieldStyle(.plain)
                    .lineLimit(5...15)
            } header: {
                Text(Strings.descriptionSectionHeader)
            } footer: {
                if let text = viewModel.localizedLabels.descriptionFieldDescription {
                    Text(verbatim: text)
                }
            }

            if viewModel.isExistingTag {
                Section {
                    Button(role: .destructive) {
                        viewModel.showDeleteConfirmation = true
                    } label: {
                        Text(SharedStrings.Button.delete)
                            .foregroundColor(.red)
                    }
                    .frame(maxWidth: .infinity)
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
    private let tagsService: TaxonomyServiceProtocol
    fileprivate let localizedLabels: LocalizedLabels

    var isExistingTag: Bool {
        originalTerm != nil
    }

    var navigationTitle: String {
        originalTerm?.name ?? localizedLabels.newItemTitle
    }

    init(term: AnyTermWithViewContext?, taxonomy: SiteTaxonomy?, tagsService: TaxonomyServiceProtocol) {
        self.originalTerm = term
        self.localizedLabels = taxonomy.flatMap(LocalizedLabels.from) ?? .tag
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

            let tagName = tagName.trimmingCharacters(in: .whitespacesAndNewlines)
            let tagDescription = tagDescription.trimmingCharacters(in: .whitespacesAndNewlines)
            if let existingTerm = originalTerm {
                savedTerm = try await tagsService.updateTag(existingTerm, name: tagName, description: tagDescription)
            } else {
                savedTerm = try await tagsService.createTag(name: tagName, description: tagDescription)
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

private struct LocalizedLabels {
    var newPlaceholder: String
    var newItemTitle: String
    var nameFieldDescription: String?
    var descriptionFieldDescription: String?

    static func from(taxonomy: SiteTaxonomy) -> Self {
        Self(
            newPlaceholder: taxonomy.labels.newItemName ?? "",
            newItemTitle: taxonomy.labels.addNewItem ?? "",
            nameFieldDescription: taxonomy.labels.nameFieldDescription,
            descriptionFieldDescription: taxonomy.labels.descFieldDescription
        )
    }

    static var tag: Self {
        Self(
            newPlaceholder: NSLocalizedString(
                "edit.tag.name.placeholder",
                value: "Tag name",
                comment: "Placeholder text for tag name field"
            ),
             newItemTitle: NSLocalizedString(
                "edit.tag.new.title",
                value: "New Tag",
                comment: "Navigation title for new tag creation"
            ),
            nameFieldDescription: nil,
            descriptionFieldDescription: nil
        )
    }
}

private enum Strings {
    static let tagSectionHeader = NSLocalizedString(
        "edit.tag.section.tag",
        value: "Name",
        comment: "Section header for tag name in edit tag view"
    )

    static let descriptionSectionHeader = NSLocalizedString(
        "edit.tag.section.description",
        value: "Description",
        comment: "Section header for tag description in edit tag view"
    )

    static let descriptionPlaceholder = NSLocalizedString(
        "edit.tag.description.placeholder",
        value: "Add a description...",
        comment: "Placeholder text for tag description field"
    )

    static let deleteConfirmationTitle = NSLocalizedString(
        "edit.tag.delete.confirmation.title",
        value: "Delete",
        comment: "Title for delete a term confirmation dialog"
    )

    static let deleteConfirmationMessage = NSLocalizedString(
        "edit.tag.delete.confirmation.message",
        value: "Are you sure you want to delete this?",
        comment: "Message for delete tag confirmation dialog"
    )
}
