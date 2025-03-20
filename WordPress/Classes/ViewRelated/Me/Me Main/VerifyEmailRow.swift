import Foundation
import UIKit
import SwiftUI
import WordPressUI
import Combine

final class VerifyEmailRow: ImmuTableRow {
    static let cell = ImmuTableCell.class(VerifyEmailCell.self)
    let action: ImmuTableAction? = nil

    func configureCell(_ cell: UITableViewCell) {
        // Do nothing.
    }
}

final class VerifyEmailCell: UITableViewCell {
    private let hostingView: UIHostingView<VerifyEmailView>

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        hostingView = .init(view: .init())
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        selectionStyle = .none

        contentView.addSubview(hostingView)
        hostingView.pinEdges(to: contentView)
    }
}

private struct VerifyEmailView: View {
    @StateObject private var viewModel = VerifyEmailViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "envelope.circle.fill")
                Text(Strings.verifyEmailTitle)
            }
            .foregroundStyle(Color(uiColor: #colorLiteral(red: 0.8392476439, green: 0.2103677094, blue: 0.2182099223, alpha: 1)))
            .font(.subheadline.weight(.semibold))

            Text(viewModel.state.message)
                .font(.callout)
                .foregroundStyle(.primary)

            Spacer()

            Button {
                viewModel.sendVerificationEmail()
            } label: {
                HStack {
                    if viewModel.state.showsActivityIndicator {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    }

                    Text(viewModel.state.buttonTitle)
                        .font(.callout)
                }
            }
            .buttonStyle(.borderless)
            .disabled(!viewModel.state.isButtonEnabled)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

// This value is not an actual "timeout" value of the verification link. It's just an arbitrary value to prevent
// users from sending links repeatedly.
private let verificationLinkTimeout: TimeInterval = 300

@MainActor
private class VerifyEmailViewModel: ObservableObject {
    enum State {
        case needsVerification
        case sending
        case sent(Date)
        case error(Error)

        var message: String {
            let email = try? WPAccount.lookupDefaultWordPressComAccount(in: ContextManager.shared.mainContext)?.email ?? ""

            switch self {
            case .needsVerification, .sending, .sent:
                if let email, !email.isEmpty {
                    return String(format: Strings.verifyMessage, email, Strings.sendButton)
                } else {
                    return String(format: Strings.verifyMessageNoEmail, Strings.sendButton)
                }
            case .error(let error):
                return error.localizedDescription
            }
        }

        var buttonTitle: String {
            switch self {
            case .needsVerification:
                return Strings.sendButton
            case .sending:
                return Strings.sendingButton
            case .sent:
                return Strings.sentButton
            case .error:
                return Strings.retryButton
            }
        }

        var isButtonEnabled: Bool {
            switch self {
            case .needsVerification, .error: return true
            case .sending: return false
            case .sent(let date):
                return Date().timeIntervalSince(date) >= verificationLinkTimeout
            }
        }

        var showsActivityIndicator: Bool {
            if case .sending = self {
                return true
            }
            return false
        }
    }

    private let userID: NSNumber

    private var lastVerificationSentDate: Date? {
        get {
            let key = "LastEmailVerificationSentDate-\(userID)"
            return UserDefaults.standard.object(forKey: key) as? Date
        }
        set {
            let key = "LastEmailVerificationSentDate-\(userID)"
            UserDefaults.standard.set(newValue, forKey: key)
        }
    }

    @Published private(set) var state: State

    init() {
        userID = (try? WPAccount.lookupDefaultWordPressComAccount(in: ContextManager.shared.mainContext)?.userID) ?? 0
        state = .needsVerification

        if let sentDate = lastVerificationSentDate,
           Date().timeIntervalSince(sentDate) < verificationLinkTimeout {
            state = .sent(sentDate)
        }
    }

    func sendVerificationEmail() {
        guard state.isButtonEnabled else { return }

        state = .sending

        let accountService = AccountService(coreDataStack: ContextManager.shared)
        accountService.requestVerificationEmail({ [weak self] in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.lastVerificationSentDate = Date()
                self.state = .sent(Date())
            }
        }, failure: { [weak self] error in
            Task { @MainActor [weak self] in
                self?.state = .error(error)
            }
        })
    }
}

private enum Strings {
    static let verifyEmailTitle = NSLocalizedString("me.verifyEmail.title", value: "Verify Your Email", comment: "Title for email verification card")
    static let verifyMessage = NSLocalizedString("me.verifyEmail.message.withEmail", value: "Verify your email to secure your account and access more features.\nCheck your inbox at %@ for the confirmation email, or click '%@' to get a new one.", comment: "Message for email verification card with email address")
    static let verifyMessageNoEmail = NSLocalizedString("me.verifyEmail.message.noEmail", value: "Verify your email to secure your account and access more features.\nCheck your inbox for the confirmation email, or click '%@' to get a new one..", comment: "Message for email verification card")
    static let sendButton = NSLocalizedString("me.verifyEmail.button.send", value: "Resend email", comment: "Button title to send verification link")
    static let sendingButton = NSLocalizedString("me.verifyEmail.button.sending", value: "Sending...", comment: "Button title while verification link is being sent")
    static let sentButton = NSLocalizedString("me.verifyEmail.button.sent", value: "Email sent", comment: "Button title after verification link is sent")
    static let retryButton = NSLocalizedString("me.verifyEmail.button.retry", value: "Try Again", comment: "Button title when verification link sending failed")
}
