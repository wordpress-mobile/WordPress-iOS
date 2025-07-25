import Foundation
import SwiftUI
import DesignSystem

struct ApplicationPasswordsInfoView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(Strings.allInfo)
                .font(.body)

            Spacer()

            DSButton(
                title: Strings.gotItButton,
                style: DSButtonStyle(emphasis: .primary, size: .large)
            ) {
                dismiss()
            }
        }
        .padding()
        .navigationTitle(Strings.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private enum Strings {
    static let title = NSLocalizedString(
        "applicationPassword.info.title",
        value: "About Application Passwords",
        comment: "Title for the application passwords information view"
    )

    static let allInfo = NSLocalizedString(
        "applicationPassword.info.content",
        value: "Application passwords are a more secure way for this app to access your site content without using your actual account password.\n\nWhen you add sites to the app, application passwords will be created automatically as needed.\n\nYou can view and manage these passwords in your user profile within your WordPress site's admin panel.\n\nPlease note that revoking application passwords used by the app will terminate the app's access to your site. Be cautious when revoking application passwords created by the app.",
        comment: "Complete information about application passwords with security benefits, creation process, management instructions, and revocation warning"
    )

    static let gotItButton = NSLocalizedString(
        "applicationPassword.info.gotIt.button",
        value: "Got it",
        comment: "Button to dismiss the application password information view"
    )
}
