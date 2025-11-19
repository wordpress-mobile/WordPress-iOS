import SwiftUI
import PhotosUI

public struct SupportConversationReplyView: View {

    private let enableRichTextForm: Bool = false

    enum ViewState: Equatable {
        case editing
        case sending(Task<Void, Never>)
        case sent(Task<Void, Never>)
        case error(String)

        var isSendingMessage: Bool {
            guard case .sending = self else { return false }
            return true
        }

        var messageWasSent: Bool {
            guard case .sent = self else { return false }
            return true
        }

        var isError: Bool {
            guard case .error = self else { return false }
            return true
        }

        var error: String {
            guard case .error(let string) = self else {
                return ""
            }

            return string
        }

        var cancelButtonShouldBeDisabled: Bool {
            if case .sending = self {
                return true
            }

            return false
        }
    }

    let conversation: Conversation
    let currentUser: SupportUser
    let conversationDidUpdate: (Conversation) -> Void

    @Environment(\.dismiss)
    private var dismiss

    @EnvironmentObject
    var dataProvider: SupportDataProvider

    @State
    private var richText: AttributedString = ""

    @State
    private var plainText: String = ""

    @State
    private var state: ViewState = .editing

    @State
    private var isDisplayingCancellationConfirmation: Bool = false

    @FocusState
    private var isTextFieldFocused: Bool

    @State private var selectedPhotos: [URL] = []
    @State private var uploadLimitExceeded: Bool = false

    @State
    private var includeApplicationLogs: Bool = false

    private var textIsEmpty: Bool {
        plainText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && String(richText.characters).trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var canSendMessage: Bool {
        !textIsEmpty && state == .editing && !uploadLimitExceeded
    }

    public init(conversation: Conversation, currentUser: SupportUser, conversationDidUpdate: @escaping (Conversation) -> Void) {
        self.conversation = conversation
        self.currentUser = currentUser
        self.conversationDidUpdate = conversationDidUpdate
    }

    public var body: some View {
        VStack {
            Form {
                Section(Localization.message) {
                    textEditor
                }

                ScreenshotPicker(
                    attachedImageUrls: self.$selectedPhotos,
                    maximumUploadSize: self.dataProvider.maximumUploadSize,
                    uploadLimitExceeded: self.$uploadLimitExceeded
                )

                ApplicationLogPicker(
                    includeApplicationLogs: self.$includeApplicationLogs
                )
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .interactiveDismissDisabled(!self.textIsEmpty) // Don't allow swiping down to dismiss if the user would lose data
        .navigationTitle(Localization.reply)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(Localization.cancel) {
                    dismiss()
                }
                .disabled(self.state.cancelButtonShouldBeDisabled)
            }

            ToolbarItem(placement: .confirmationAction) {
                Button {
                    self.sendReply()
                } label: {
                    Text(Localization.send)
                }
                .disabled(!canSendMessage)
            }
        }
        .overlay {
            ZStack {
                ProgressView(Localization.sendingMessage)
                    .padding()
                    .background(Color(UIColor.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(radius: 8)
                    .opacity(state.isSendingMessage ? 1.0 : 0.0)
                    .offset(x: 0, y: state.isSendingMessage ? 0 : 20)

                ErrorView(
                    title: Localization.unableToSendMessage,
                    message: state.error
                )
                .padding()
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(radius: 8)
                .opacity(state.isError ? 1.0 : 0.0)
                .offset(x: 0, y: state.isError ? 0 : 20)
                .onTapGesture {
                    self.state = .editing
                }

                VStack {
                    HStack {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 48))
                            .foregroundStyle(Color.gray)
                            .padding(.top, -4)
                            .padding(.bottom, 4)
                    }
                    Text(Localization.messageSent).font(.title2).bold()
                }
                .padding()
                .background(Color(UIColor.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(radius: 8)
                .opacity(state.messageWasSent ? 1.0 : 0.0)
                .offset(x: 0, y: state.messageWasSent ? 0 : 20)
                .onTapGesture {
                    self.dismiss()
                }
            }
        }
        .onAppear {
            isTextFieldFocused = true
        }
        .alert(
            Localization.confirmCancellation,
            isPresented: $isDisplayingCancellationConfirmation,
            actions: {
                Button(Localization.discardChanges, role: .destructive) {
                    self.dismiss()
                }

                Button(Localization.continueWriting, role: .cancel) {
                    self.isDisplayingCancellationConfirmation = false
                }
            }, message: {
                Text(Localization.confirmCancelMessage)
            }
        )
    }

    @ViewBuilder
    var textEditor: some View {
        if #available(iOS 26.0, *), enableRichTextForm {
            TextEditor(text: $richText)
                .focused($isTextFieldFocused)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .frame(minHeight: 120)
                .disabled(state != .editing)
        } else {
            TextEditor(text: $plainText)
                .focused($isTextFieldFocused)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .frame(minHeight: 120)
                .disabled(state != .editing)
        }
    }

    private func getText() throws -> String {
        if #available(iOS 26.0, *), enableRichTextForm {
            return self.richText.toHtml()
        } else {
            return self.plainText.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    private func sendReply() {
        guard !textIsEmpty else { return }

        withAnimation {
            state = .sending(self.sendingTask)
        }
    }

    var sendingTask: Task<Void, Never> {
        Task {
            do {
                let text = try getText()

                let conversation = try await dataProvider.replyToSupportConversation(
                    id: conversation.id,
                    message: text,
                    user: self.currentUser,
                    attachments: self.selectedPhotos
                )

                self.conversationDidUpdate(conversation)

                withAnimation {
                    state = .sent(Task {
                        // Display the sent message for 2 seconds, then auto-dismiss
                        try? await Task.sleep(for: .seconds(2))

                        dismiss()
                    })
                }
            } catch {
                state = .error(error.localizedDescription)

                if case .error = state {
                    state = .editing
                }
            }
        }
    }

    private func formatTimestamp(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Application Log Row Component

#Preview {

    @Previewable @State
    var isPresented: Bool = true

    NavigationStack {
        Text("Hello World").onTapGesture {
            isPresented = true
        }
    }.sheet(isPresented: $isPresented) {
        NavigationStack {
            SupportConversationReplyView(
                conversation: SupportDataProvider.supportConversation,
                currentUser: SupportDataProvider.supportUser, conversationDidUpdate: { _ in }
            )
        }
    }
    .environmentObject(SupportDataProvider.testing)
}
