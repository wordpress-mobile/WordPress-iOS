import SwiftUI
import FoundationModels

@available(iOS 26, *)
public struct LanguageModelUnavailableView: View {
    public let reason: SystemLanguageModel.Availability.UnavailableReason

    public var body: some View {
        makeUnavailableView(for: reason)
    }

    public init(reason: SystemLanguageModel.Availability.UnavailableReason) {
        self.reason = reason
    }

    @ViewBuilder
    private func makeUnavailableView(for reason: SystemLanguageModel.Availability.UnavailableReason) -> some View {
        switch reason {
        case .appleIntelligenceNotEnabled:
            EmptyStateView {
                Label(Strings.appleIntelligenceDisabledTitle, systemImage: "apple.intelligence")
            } description: {
                Text(Strings.appleIntelligenceDisabledMessage)
            } actions: {
                if let settingURL = URL(string: UIApplication.openSettingsURLString) {
                    Button(Strings.openAppleIntelligenceSettings) {
                        UIApplication.shared.open(settingURL)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppColor.primary)
                }
            }
        case .modelNotReady:
            EmptyStateView {
                Label(Strings.preparingModel, systemImage: "apple.intelligence")
            } description: {
                Text(Strings.preparingModelDescription)
            } actions: {
                EmptyView()
            }
        default:
            EmptyStateView {
                Label(Strings.appleIntelligenceUnavailableTitle, systemImage: "apple.intelligence")
            } description: {
                Text(Strings.appleIntelligenceUnavailableTitle)
            } actions: {
                EmptyView()
            }
        }
    }
}

@available(iOS 26, *)
#Preview {
    LanguageModelUnavailableView(reason: .appleIntelligenceNotEnabled)
}

private enum Strings {
    static let appleIntelligenceDisabledTitle = NSLocalizedString(
        "intelligence.unavailableView.appleIntelligenceDisabled.title",
        value: "Apple Intelligence Required",
        comment: "Title shown when Apple Intelligence is disabled"
    )

    static let appleIntelligenceDisabledMessage = NSLocalizedString(
        "intelligence.unavailableView.appleIntelligenceDisabled.message",
        value: "To generate excerpts with AI, please enable Apple Intelligence in Settings. This feature uses on-device processing to protect your privacy.",
        comment: "Message shown when Apple Intelligence is disabled"
    )

    static let openAppleIntelligenceSettings = NSLocalizedString(
        "intelligence.unavailableView.appleIntelligenceDisabled.openSettings",
        value: "Open Settings",
        comment: "Button to open Apple Intelligence settings"
    )

    static let preparingModel = NSLocalizedString(
        "intelligence.unavailableView.preparingModel.title",
        value: "Preparing model...",
        comment: "Title shown when the AI model is not ready"
    )

    static let preparingModelDescription = NSLocalizedString(
        "intelligence.unavailableView.preparingModel.description",
        value: "The AI model is downloading or being prepared. Please try again in a moment.",
        comment: "Description shown when the AI model is not ready"
    )

    static let appleIntelligenceUnavailableTitle = NSLocalizedString(
        "intelligence.unavailableView.appleIntelligenceUnvailable.title",
        value: "Apple Intelligence Unvailable",
        comment: "Title shown when Apple Intelligence is unavailable"
    )

    static let appleIntelligenceUnavailableMessage = NSLocalizedString(
        "intelligence.unavailableView.appleIntelligenceUnvailable.message",
        value: "Apple Intelligence is not available on this device",
        comment: "Message shown when Apple Intelligence is unavailable"
    )
}
