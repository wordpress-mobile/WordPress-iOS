import SwiftUI

/// Banner shown when a stats feature is gated behind a paid plan
struct FeatureGateBannerView: View {
    let error: StatsFeatureGateError

    @Environment(\.context) private var context
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "lock.fill")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            Text(Strings.FeatureGate.message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: 240)

            if let upgradeURL = context.upgradeURL {
                Button(Strings.FeatureGate.explorePlans) {
                    handleExplorePlansTapped(upgradeURL: upgradeURL)
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .padding(.top, 16)
            }
        }
        .padding(Constants.step2)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func handleExplorePlansTapped(upgradeURL: URL) {
        context.tracker?.send(.featureGateExplorePlansTapped, properties: [
            "feature": error.featureName,
            "source": "card"
        ])
        openURL(upgradeURL)
    }
}

#Preview("Feature Gate on Card") {
    FeatureGateBannerView(error: StatsFeatureGateError(
        message: "The plan for this site does not allow fetching Device stats",
        itemType: .devices
    ))
    .environment(\.context, .demo)
    .padding()
    .background(Color(uiColor: .secondarySystemBackground))
}
