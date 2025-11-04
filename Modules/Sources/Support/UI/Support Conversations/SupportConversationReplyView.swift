import SwiftUI
import PhotosUI

public struct SupportConversationReplyView: View {

    enum ViewState: Equatable {
        case editing
        case sending(Task<Void, Never>)
        case sent(Task<Void, Never>)
        case error(Error)

        static func == (lhs: Self, rhs: Self) -> Bool {
            switch (lhs, rhs) {
            case (.editing, .editing): return true
            case (.sending, .sending): return true
            case (.sent, .sent): return true
            case (.error(let lhsError), .error(let rhsError)): return lhsError.localizedDescription == rhsError.localizedDescription
            default: return false
            }
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

    @FocusState
    private var isTextFieldFocused: Bool

    @State
    private var selectedPhotos: [URL] = []

    @State
    private var includeApplicationLogs: Bool = false

    private var textIsEmpty: Bool {
        plainText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && String(richText.characters).trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var canSendMessage: Bool {
        !textIsEmpty && state == .editing
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
                    attachedImageUrls: self.$selectedPhotos
                )

                ApplicationLogPicker(
                    includeApplicationLogs: self.$includeApplicationLogs
                )
            }
        }
        .navigationTitle(Localization.reply)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(Localization.cancel) {
                    dismiss()
                }
                .disabled({
                    if case .sending = state {
                        return true
                    }
                    return false
                }())
            }

            ToolbarItem(placement: .confirmationAction) {
                Button {
                    self.sendReply()
                } label: {
                    if case .sending = state {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text(Localization.sending)
                        }
                    } else {
                        Text(Localization.send)
                    }
                }
                .disabled(!canSendMessage)
            }
        }
        .overlay {
            switch self.state {
            case .error(let error):
                ErrorView(
                    title: Localization.unableToSendMessage,
                    message: error.localizedDescription
                )
            case .sent:
                ContentUnavailableView(
                    Localization.messageSent,
                    systemImage: "checkmark.circle",
                    description: nil
                ).onTapGesture {
                    self.dismiss()
                }
            default: EmptyView()
            }
        }
        .onAppear {
            isTextFieldFocused = true
        }
    }

    @ViewBuilder
    var textEditor: some View {
        if #available(iOS 26.0, *) {
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
        if #available(iOS 26.0, *) {
            return self.richText.toHtml()
        } else {
            return self.plainText.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    private func sendReply() {
        guard !textIsEmpty else { return }

        let task = Task {
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

                        await MainActor.run {
                            dismiss()
                        }
                    })
                }
            } catch {
                state = .error(error)

                // Reset to editing state after showing error for a moment
                try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                if case .error = state {
                    state = .editing
                }
            }
        }

        withAnimation {
            state = .sending(task)
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
    NavigationStack {
        Text("Hello World")
    }.sheet(isPresented: .constant(true)) {
        NavigationStack {
            SupportConversationReplyView(
                conversation: SupportDataProvider.supportConversation,
                currentUser: SupportDataProvider.supportUser, conversationDidUpdate: { _ in }
            )
        }
    }
    .environmentObject(SupportDataProvider.testing)
}
