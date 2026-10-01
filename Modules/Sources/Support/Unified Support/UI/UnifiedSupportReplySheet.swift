import SwiftUI

/// The form used to answer the support team, with optional attachments and application logs.
struct UnifiedSupportReplySheet: View {

    @ObservedObject var viewModel: UnifiedSupportConversationViewModel

    /// Backs the shared application log picker, which is also used by the other support screens.
    let supportDataProvider: SupportDataProvider

    @Environment(\.dismiss) private var dismiss

    @FocusState private var isMessageFocused: Bool

    @State private var isConfirmingDiscard = false

    /// Set while the picked files are still being brought in, so a reply can't leave without its attachments.
    @State private var isImportingAttachments = false

    /// The imports still running, so that leaving the form stops them.
    @State private var attachmentImports = UnifiedSupportAttachmentImports()

    var body: some View {
        NavigationStack {
            Form {
                Section(UnifiedSupportLocalization.message) {
                    TextEditor(text: $viewModel.replyDraft.message)
                        .focused($isMessageFocused)
                        .frame(minHeight: 120)
                }

                UnifiedSupportAttachmentPicker(
                    files: $viewModel.replyDraft.files,
                    isImporting: $isImportingAttachments,
                    imports: attachmentImports,
                    maximumUploadSize: viewModel.maximumUploadSize
                )

                ApplicationLogPicker(includeApplicationLogs: $viewModel.replyDraft.includeApplicationLogs)
                    .environmentObject(supportDataProvider)
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(viewModel.replyAction.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    SupportCancelButton(title: UnifiedSupportLocalization.cancel, action: close)
                }

                ToolbarItem(placement: .confirmationAction) {
                    SupportSendButton(
                        title: UnifiedSupportLocalization.send,
                        action: viewModel.sendTicketReply
                    )
                    .disabled(!viewModel.canSendReply || isImportingAttachments)
                }
            }
        }
        // Closing the form by swiping it down would throw the reply away without asking.
        .interactiveDismissDisabled(!viewModel.replyDraft.isEmpty)
        .onAppear {
            isMessageFocused = true
        }
        // Whichever way the form went away, a file still on its way in has nowhere left to go.
        .onDisappear {
            attachmentImports.cancelAll()
        }
        .alert(UnifiedSupportLocalization.discardReplyTitle, isPresented: $isConfirmingDiscard) {
            Button(UnifiedSupportLocalization.discardReply, role: .destructive) {
                attachmentImports.cancelAll()
                viewModel.discardReplyDraft()
                dismiss()
            }
            Button(UnifiedSupportLocalization.keepWriting, role: .cancel) {}
        } message: {
            Text(UnifiedSupportLocalization.discardReplyMessage)
        }
    }

    private func close() {
        guard viewModel.replyDraft.isEmpty else {
            isConfirmingDiscard = true
            return
        }
        // Nothing was written, so a file still being brought in isn't wanted either.
        attachmentImports.cancelAll()
        dismiss()
    }
}

#Preview {
    @Previewable @State var isPresented = true

    Text(verbatim: "Ticket")
        .sheet(isPresented: $isPresented) {
            UnifiedSupportReplySheet(
                viewModel: UnifiedSupportConversationViewModel(
                    source: .existing(UnifiedSupportConversation.previewEscalatedConversation.summary),
                    dataProvider: InternalUnifiedSupportDataProvider(),
                    tracker: InternalUnifiedSupportTracker(),
                    currentUser: SupportDataProvider.supportUser
                ),
                supportDataProvider: .testing
            )
        }
}
