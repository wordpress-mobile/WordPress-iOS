import SwiftUI
import WordPressUI
import WordPressKit

struct SubscriberInviteView: View {
    let blog: SubscribersBlog

    @State private var emails: [SubscriberEmail] = [SubscriberEmail()]
    @State private var isSending = false
    @State private var isShowingDismissConfirmation = false

    @Environment(\.dismiss) private var dismiss

    private var isSendEnabled: Bool {
        emails.contains(where: \.isValid) && emails.allSatisfy { $0.isEmpty || $0.isValid }
    }

    var body: some View {
        List {
            ForEach($emails) { email in
                SubscriberInviteViewRowView(email: email)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }

            PasteButton(payloadType: String.self, onPaste: paste)
                .buttonBorderShape(.capsule)
                .tint(AppColor.tint)

            Text(String(format: Strings.disclosure, SharedStrings.Button.send))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(8)
                .padding(.top, 8)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
        }
        .listStyle(.plain)
        .onChange(of: emails) { emails in
            if !emails.contains(where: \.isEmpty) {
                withAnimation {
                    self.emails.append(SubscriberEmail())
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(SharedStrings.Button.cancel) {
                    if emails.contains(where: { !$0.value.isEmpty }) {
                        isShowingDismissConfirmation = true
                    } else {
                        dismiss()
                    }
                }
                .tint(AppColor.tint)
            }
            ToolbarItem(placement: .topBarTrailing) {
                if isSending {
                    ProgressView()
                } else {
                    Button(SharedStrings.Button.send, action: buttonSendTapped)
                        .buttonStyle(.borderedProminent)
                        .buttonBorderShape(.capsule)
                        .disabled(!isSendEnabled)
                        .tint(AppColor.tint)
                }
            }
        }
        .confirmationDialog(Strings.cancelConfirmation, isPresented: $isShowingDismissConfirmation, actions: {
            Button(Strings.discardChanges) {
                dismiss()
            }
        })
        .disabled(isSending)
        .navigationTitle(Strings.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func paste(_ strings: [String]) {
        let emails = strings.flatMap {
            $0.components(separatedBy: .whitespacesAndNewlines.union(CharacterSet(charactersIn: ",")))
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        }
        guard !emails.isEmpty else {
            return
        }
        withAnimation {
            if self.emails.last?.isEmpty == true {
                self.emails.removeLast()
            }
            for email in emails {
                self.emails.append(SubscriberEmail(value: email))
            }
            self.emails.append(SubscriberEmail())
        }
    }

    private func buttonSendTapped() {
        let emails = emails
            .filter { $0.isValid && !$0.isEmpty }
            .map(\.value)

        isSending = true
        Task {
            do {
                guard let api = blog.getRestAPI() else {
                    throw URLError(.unknown, userInfo: [NSLocalizedDescriptionKey: SharedStrings.Error.generic])
                }
                let service = SubscribersServiceRemote(wordPressComRestApi: api)
                try await service.importSubscribers(siteID: blog.dotComSiteID, emails: emails)

                UINotificationFeedbackGenerator().notificationOccurred(.success)
                dismiss()
                Notice(title: Strings.successTitle, message: Strings.successMessage).post()
            } catch {
                UINotificationFeedbackGenerator().notificationOccurred(.error)
                isSending = false
                Notice(error: error).post()
            }
        }
    }
}

private struct SubscriberEmail: Identifiable, Hashable {
    let id = UUID()
    var rawValue: String {
        didSet { didChangeRawValue() }
    }
    var isEmpty: Bool { value.isEmpty }
    private(set) var value = ""
    private(set) var isValid = false

    init(value: String = "") {
        self.rawValue = value
        didChangeRawValue()
    }

    private mutating func didChangeRawValue() {
        value = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        isValid = SubscriberEmail.isValidEmail(value)
    }

    private static func isValidEmail(_ email: String) -> Bool {
        let parts = email.split(separator: "@")
        return parts.count == 2 && parts[1].contains(".") && !email.contains(where: \.isWhitespace)
    }
}

private struct SubscriberInviteViewRowView: View {
    @Binding var email: SubscriberEmail

    @State private var isValid = true
    @FocusState private var isFocused: Bool

    private var isShowingError: Bool {
        !isFocused && !email.isEmpty && !email.isValid
    }

    var body: some View {
        HStack {
            TextField(Strings.email, text: $email.rawValue, prompt: Text(verbatim: "name@example.com"))
                .focused($isFocused)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)

            if !email.isEmpty {
                Button(action: {
                    self.email.rawValue = ""
                }) {
                    Image(systemName: "multiply.circle.fill")
                        .foregroundStyle(.tertiary)
                }.buttonStyle(.plain)
            }
        }
        .padding(8)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(
                    Color(isShowingError ? UIAppColor.error : .separator),
                    lineWidth: isShowingError ? 1 : 0.5
                )
        )
    }
}

private enum Strings {
    static let title = NSLocalizedString("inviteSubscribers.title", value: "Add Subscribers", comment: "Screen title")
    static let cancelConfirmation = NSLocalizedString("inviteSubscribers.cancelConfirmationTitle", value: "Are you sure you want to discard the new subscribers?", comment: "Cancel dialog confirmation title")
    static let discardChanges = NSLocalizedString("inviteSubscribers.discardChanges", value: "Discard Changes", comment: "Cancel dialog confirmation button")
    static let email = NSLocalizedString("inviteSubscribers.fieldTitleEmail", value: "Email", comment: "Field title (not shown, accessibility)")
    static let disclosure = NSLocalizedString("inviteSubscribers.disclosure", value: "By clicking \"%@,\" you represent that you've obtained the appropriate consent to email each person. Spam complaints or high bounce rate from your subscribers may lead to action against your account.", comment: "A footer view (small text). The button title is inserted by the app via a parameter.")
    static let successTitle = NSLocalizedString("inviteSubscribers.importSuccessTitle", value: "Import Started", comment: "Import success snackbar title")
    static let successMessage = NSLocalizedString("inviteSubscribers.importSuccessMessage", value: "It make take a few minutes before the import completes", comment: "Import success snackbar title")
}

#Preview {
    NavigationView {
        SubscriberInviteView(blog: .mock())
    }.tint(AppColor.tint)
}
