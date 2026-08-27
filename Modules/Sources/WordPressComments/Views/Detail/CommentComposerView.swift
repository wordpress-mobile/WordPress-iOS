import SwiftUI

/// The reply composer sheet, presented from the detail screen. Cancelling a
/// dirty reply asks whether to keep or discard its draft.
struct CommentComposerView: View {
    @ObservedObject var viewModel: CommentComposerViewModel
    let onFinished: (CommentComposerViewModel.Outcome) -> Void
    let onDismiss: () -> Void

    @FocusState private var editorFocused: Bool
    @State private var isCancelConfirmationPresented = false

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                parentSnippet(viewModel.parentPreview)
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
        }
        .interactiveDismissDisabled(viewModel.isDirty || viewModel.isSending)
        .onDisappear { viewModel.deleteDraftIfBlank() }
        .confirmationDialog("", isPresented: $isCancelConfirmationPresented) {
            cancelConfirmationActions
        }
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
            .padding(.horizontal, 12)
            .overlay(alignment: .topLeading) {
                if viewModel.text.isEmpty {
                    Text(Strings.composerPlaceholder)
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .allowsHitTesting(false)
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
            Button(Strings.composerCancel) { handleCancel() }
                .disabled(viewModel.isSending)
        }
        ToolbarItem(placement: .confirmationAction) {
            if viewModel.isSending {
                ProgressView()
                    .accessibilityLabel(viewModel.sendButtonTitle)
            } else {
                Button(viewModel.sendButtonTitle) {
                    Task {
                        if let outcome = await viewModel.send() {
                            onFinished(outcome)
                        }
                    }
                }
                .disabled(!viewModel.canSend)
            }
        }
    }

    /// A dirty reply offers to keep or discard its draft.
    @ViewBuilder
    private var cancelConfirmationActions: some View {
        Button(Strings.composerSaveDraft) {
            viewModel.saveDraft()
            onDismiss()
        }
        Button(Strings.composerDeleteDraft, role: .destructive) {
            viewModel.deleteDraft()
            onDismiss()
        }
        Button(Strings.composerKeepEditing, role: .cancel) {}
    }

    private func handleCancel() {
        guard viewModel.isDirty else {
            onDismiss()
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
    return CommentComposerView(viewModel: viewModel, onFinished: { _ in }, onDismiss: {})
}
#endif
