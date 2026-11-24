import SwiftUI

/// The reply/edit composer sheet. Presented from the detail screen for both
/// modes; the mode dictates which rows show (the parent snippet and approve
/// note appear only in reply mode) and what cancelling asks about (a reply
/// offers to keep or discard its draft; an edit only offers to discard).
struct CommentComposerView: View {
    @ObservedObject var viewModel: CommentComposerViewModel
    /// Called once when the sheet should close: with the outcome after a
    /// successful send, nil when the user cancelled.
    let onClose: (CommentComposerViewModel.Outcome?) -> Void

    @FocusState private var editorFocused: Bool
    @State private var isCancelConfirmationPresented = false

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                if let parent = viewModel.parentPreview {
                    parentSnippet(parent)
                }
                if viewModel.showsApproveNote {
                    approveNote
                }
                textEditor
                if let error = viewModel.errorMessage {
                    errorBanner(error)
                }
            }
            .navigationTitle(viewModel.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .onAppear { editorFocused = true }
            .onChange(of: viewModel.isSending) { _, isSending in
                if isSending { announce(viewModel.sendingAnnouncement) }
            }
            .onChange(of: viewModel.errorMessage) { _, message in
                if let message { announce(message) }
            }
        }
        .interactiveDismissDisabled(viewModel.isDirty || viewModel.isSending)
        .onDisappear { viewModel.deleteDraftIfBlank() }
    }

    @ViewBuilder
    private func parentSnippet(_ parent: CommentListItem) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(parent.authorName)
                .font(.headline)
            Text(parent.snippet)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        Divider()
    }

    private var approveNote: some View {
        Label(Strings.composerApproveNote, systemImage: "info.circle")
            .font(.footnote)
            .foregroundStyle(.secondary)
            .padding(.horizontal)
            .padding(.top, 8)
    }

    private var textEditor: some View {
        TextEditor(text: $viewModel.text)
            .focused($editorFocused)
            .disabled(viewModel.isSending)
            .accessibilityLabel(viewModel.title)
            .padding(.horizontal, 12)
            .overlay(alignment: .topLeading) {
                if viewModel.text.isEmpty, let placeholder = viewModel.placeholder {
                    Text(placeholder)
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
            }
    }

    private func errorBanner(_ message: String) -> some View {
        Text(message)
            .font(.footnote)
            .foregroundStyle(.red)
            .padding(.horizontal)
            .padding(.vertical, 8)
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            // Attached to the button so the iOS 26+ popover anchors to Cancel
            // instead of the sheet's center.
            Button(Strings.composerCancel) { handleCancel() }
                .disabled(viewModel.isSending)
                .confirmationDialog("", isPresented: $isCancelConfirmationPresented) {
                    cancelConfirmationActions
                }
        }
        ToolbarItem(placement: .confirmationAction) {
            // One button for both states: swapping it for a bare spinner
            // removes the element VoiceOver is focused on.
            Button {
                Task {
                    if let outcome = await viewModel.send() {
                        onClose(outcome)
                    }
                }
            } label: {
                Text(viewModel.sendButtonTitle)
                    .opacity(viewModel.isSending ? 0 : 1)
                    .overlay {
                        if viewModel.isSending {
                            ProgressView()
                        }
                    }
            }
            .accessibilityLabel(viewModel.sendButtonTitle)
            .disabled(!viewModel.canSend || viewModel.isSending)
        }
    }

    /// High priority, so VoiceOver's own speech after the button is activated
    /// can't talk over it.
    private func announce(_ message: String) {
        var announcement = AttributedString(message)
        announcement.accessibilitySpeechAnnouncementPriority = .high
        AccessibilityNotification.Announcement(announcement).post()
    }

    /// A dirty reply offers to keep or discard its draft; a dirty edit only
    /// offers to discard.
    @ViewBuilder
    private var cancelConfirmationActions: some View {
        switch viewModel.mode {
        case .reply:
            Button(Strings.composerSaveDraft) {
                viewModel.saveDraft()
                onClose(nil)
            }
            Button(Strings.composerDeleteDraft, role: .destructive) {
                viewModel.deleteDraft()
                onClose(nil)
            }
        case .edit:
            Button(Strings.composerDiscardChanges, role: .destructive) { onClose(nil) }
        }
        Button(Strings.composerKeepEditing, role: .cancel) {}
    }

    private func handleCancel() {
        guard viewModel.isDirty else {
            onClose(nil)
            return
        }
        isCancelConfirmationPresented = true
    }
}

#if DEBUG
#Preview("Reply") {
    let coordinator = CommentsModerationCoordinator(service: PreviewCommentsService())
    let viewModel = CommentComposerViewModel(
        mode: .reply(parent: .preview(status: .pending)),
        coordinator: coordinator,
        draftStore: PreviewCommentDraftStore()
    )
    return CommentComposerView(viewModel: viewModel, onClose: { _ in })
}

#Preview("Edit") {
    let coordinator = CommentsModerationCoordinator(service: PreviewCommentsService())
    let viewModel = CommentComposerViewModel(
        mode: .edit(comment: .preview()),
        coordinator: coordinator,
        draftStore: PreviewCommentDraftStore()
    )
    return CommentComposerView(viewModel: viewModel, onClose: { _ in })
}
#endif
