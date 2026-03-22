import SwiftUI
import DesignSystem

struct NewStatsAnnouncementView: View {
    var onDismiss: (() -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 32) {
                    headerSection
                    featuresSection
                }
                .padding(.horizontal, 32)
                .padding(.top, 32)
                .padding(.bottom, 32)
            }
            footerSection
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(UIAppColor.blue(.shade50)).gradient)
                    .frame(width: 80, height: 80)
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 40, weight: .medium))
                    .foregroundStyle(.white)
            }

            VStack(spacing: 3) {
                Text(Strings.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)

                Text(Strings.subtitle)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    // MARK: - Features

    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            ForEach(features, id: \.title) { feature in
                FeatureRow(feature: feature)
            }
        }
    }

    // MARK: - Footer

    private var footerSection: some View {
        VStack(spacing: 12) {
            Button(action: { onDismiss?() }) {
                Text(Strings.continueButton)
                    .bold()
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Text(Strings.disclosure)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 16)
        .background(.regularMaterial)
    }
}

// MARK: - Feature Row

private struct FeatureRow: View {
    let feature: FeatureItem

    var body: some View {
        HStack(alignment: .top, spacing: 20) {
            ZStack {
                RoundedRectangle(cornerRadius: 9)
                    .fill(Color.secondary.gradient)
                    .frame(width: 44, height: 44)
                Image(systemName: feature.icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(feature.title)
                    .font(.headline)
                Text(feature.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, 4)
        }
    }
}

// MARK: - Data

private struct FeatureItem {
    let icon: String
    let title: String
    let description: String
}

private let features: [FeatureItem] = [
    FeatureItem(
        icon: "calendar",
        title: Strings.Feature.datePickerTitle,
        description: Strings.Feature.datePickerDescription
    ),
    FeatureItem(
        icon: "globe",
        title: Strings.Feature.parityTitle,
        description: Strings.Feature.parityDescription
    ),
    FeatureItem(
        icon: "hand.tap.fill",
        title: Strings.Feature.bottomNavTitle,
        description: Strings.Feature.bottomNavDescription
    ),
    FeatureItem(
        icon: "chart.line.uptrend.xyaxis",
        title: Strings.Feature.trendsTitle,
        description: Strings.Feature.trendsDescription
    ),
]

// MARK: - Strings

private enum Strings {
    static let title = NSLocalizedString(
        "newStats.announcement.title",
        value: "New Stats",
        comment: "Title for the New Stats announcement screen"
    )
    static let subtitle = NSLocalizedString(
        "newStats.announcement.subtitle",
        value: "A better way to understand your site's performance - now on by default.",
        comment: "Subtitle for the New Stats announcement screen"
    )
    static let continueButton = NSLocalizedString(
        "newStats.announcement.continueButton",
        value: "Get Started",
        comment: "Button to confirm to switch to the New Stats announcement screen"
    )
    static let disclosure = NSLocalizedString(
        "newStats.announcement.disclosure",
        value: "Not ready to switch? You can turn off New Stats from the More menu in the Stats tab.",
        comment: "Disclosure at the bottom of the New Stats announcement screen, informing users they can opt out"
    )

    enum Feature {
        static let bottomNavTitle = NSLocalizedString(
            "newStats.announcement.feature.bottomNav.title",
            value: "Easier to Reach",
            comment: "Feature title: navigation moved to the bottom"
        )
        static let bottomNavDescription = NSLocalizedString(
            "newStats.announcement.feature.bottomNav.description",
            value: "Navigation and date picker are now at the bottom of the screen - right where your thumb is.",
            comment: "Feature description: navigation moved to the bottom for thumb-friendly access"
        )
        static let datePickerTitle = NSLocalizedString(
            "newStats.announcement.feature.datePicker.title",
            value: "Any Period, Any Range",
            comment: "Feature title: flexible date picker"
        )
        static let datePickerDescription = NSLocalizedString(
            "newStats.announcement.feature.datePicker.description",
            value: "Pick from common presets or set a custom date range with a comparison period - all in one tap.",
            comment: "Feature description: flexible date picker with presets, custom ranges, and comparisons"
        )
        static let parityTitle = NSLocalizedString(
            "newStats.announcement.feature.parity.title",
            value: "On Par with the Web",
            comment: "Feature title: feature parity with the web version of Stats"
        )
        static let parityDescription = NSLocalizedString(
            "newStats.announcement.feature.parity.description",
            value: "Devices, UTM, locations, WordAds - the same data you get on WordPress.com.",
            comment: "Feature description: feature parity with the web version of Stats"
        )
        static let trendsTitle = NSLocalizedString(
            "newStats.announcement.feature.trends.title",
            value: "Trends at a Glance",
            comment: "Feature title: trends visible for all metrics"
        )
        static let trendsDescription = NSLocalizedString(
            "newStats.announcement.feature.trends.description",
            value: "Every metric shows how it's trending compared to the previous period, so you always know if you're growing.",
            comment: "Feature description: trends shown for all metrics with comparison to previous period"
        )
    }
}

#Preview {
    NewStatsAnnouncementView()
}
