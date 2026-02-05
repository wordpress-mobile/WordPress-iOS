import SwiftUI
import WordPressUI

struct XMLRPCDisabledModalView: View {
    let onConnectJetpack: () -> Void
    let onGoToWPAdmin: () -> Void

    private let learnMoreURL = "https://apps.wordpress.com/support/mobile/login-signup/inaccessible-xml-rpc-connection-error/"

    @Environment(\.dismiss) private var dismiss
    @State private var isShowingLearnMore = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                headerSection
                buttonsSection
                learnMoreButton
                Spacer()
            }
            .padding(24)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
            }
            .sheet(isPresented: $isShowingLearnMore) {
                SafariView(url: URL(string: learnMoreURL)!)
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundStyle(.orange)
            VStack(spacing: 6) {
                Text(Strings.title)
                    .font(.title2.weight(.medium))
                Text(Strings.description)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.bottom, 24)
    }

    private var buttonsSection: some View {
        VStack(spacing: 16) {
            VStack(spacing: 4) {
                Button {
                    onConnectJetpack()
                } label: {
                    Text(Strings.connectJetpackTitle)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Text(Strings.connectJetpackDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 4) {
                Button {
                    onGoToWPAdmin()
                } label: {
                    Text(Strings.goToWPAdminTitle)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)

                Text(Strings.goToWPAdminDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 16)
    }

    private var learnMoreButton: some View {
        Button {
            isShowingLearnMore = true
        } label: {
            Text(Strings.learnMore)
                .font(.subheadline)
        }
    }
}

private enum Strings {
    static let title = NSLocalizedString(
        "blogDetails.xmlrpcDisabled.modal.title",
        value: "XML-RPC Disabled",
        comment: "Title for the XML-RPC disabled modal"
    )
    static let description = NSLocalizedString(
        "blogDetails.xmlrpcDisabled.modal.description",
        value: "XML-RPC is disabled on your site. Some features in the app currently require XML-RPC. Connect Jetpack or enable XML-RPC to access all features.",
        comment: "Description explaining options to restore functionality when XML-RPC is disabled"
    )
    static let connectJetpackTitle = NSLocalizedString(
        "blogDetails.xmlrpcDisabled.modal.connectJetpack.title",
        value: "Connect Jetpack",
        comment: "Title for the Connect Jetpack option in XML-RPC disabled modal"
    )
    static let connectJetpackDescription = NSLocalizedString(
        "blogDetails.xmlrpcDisabled.modal.connectJetpack.description",
        value: "Unlock all features with a secure connection",
        comment: "Description for the Connect Jetpack option in XML-RPC disabled modal"
    )
    static let goToWPAdminTitle = NSLocalizedString(
        "blogDetails.xmlrpcDisabled.modal.wpAdmin.title",
        value: "Enable in WP Admin",
        comment: "Title for the WP Admin option in XML-RPC disabled modal"
    )
    static let goToWPAdminDescription = NSLocalizedString(
        "blogDetails.xmlrpcDisabled.modal.wpAdmin.description",
        value: "Enable XML-RPC in your site settings",
        comment: "Description for the wp-admin option in XML-RPC disabled modal"
    )
    static let learnMore = NSLocalizedString(
        "blogDetails.xmlrpcDisabled.modal.learnMore",
        value: "Learn more",
        comment: "Link text to learn more about XML-RPC being disabled"
    )
}

#Preview {
    XMLRPCDisabledModalView(
        onConnectJetpack: { print("Connect Jetpack tapped") },
        onGoToWPAdmin: { print("Go to WP Admin tapped") }
    )
}
