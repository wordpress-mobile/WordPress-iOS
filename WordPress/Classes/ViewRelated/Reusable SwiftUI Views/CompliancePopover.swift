import SwiftUI

struct CompliancePopover: View {
    @State
    private var isAnalyticsOn = true

    var body: some View {
        VStack(alignment: .leading, spacing: Length.Padding.double) {
            titleText
            subtitleText
            analyticsToggle
            footnote
            buttonsHStack
        }
        .padding(Length.Padding.small)
    }

    private var titleText: some View {
        Text(Strings.title)
            .font(.title3)
            .fontWeight(.semibold)
    }

    private var subtitleText: some View {
        Text(Strings.subtitle)
            .font(.body)
    }

    private var analyticsToggle: some View {
        Toggle(Strings.toggleTitle, isOn: $isAnalyticsOn)
            .foregroundColor(Color.DS.Foreground.primary)
            .toggleStyle(SwitchToggleStyle(tint: Color.DS.Background.brand))
            .padding(.vertical, Length.Padding.single)
    }

    private var footnote: some View {
        Text("")
            .foregroundColor(.secondary)
    }

    private var buttonsHStack: some View {
        HStack(spacing: Length.Padding.single) {
            settingsButton
            saveButton
        }.padding(.top, Length.Padding.small)
    }

    private var settingsButton: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Length.Padding.single)
                .stroke(Color.DS.Border.divider, lineWidth: Length.Border.thin)
            Button(action: {
                print("Settings tapped")
            }) {
                Text(Strings.settingsButtonTitle)
            }
            .foregroundColor(Color.DS.Background.brand)
        }
        .frame(height: Length.Hitbox.minTapDimension)
    }

    private var saveButton: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Length.Radius.minHeightButton)
                .fill(Color.DS.Background.brand)
            Button(action: {
                print("Save tapped")
            }) {
                Text(Strings.saveButtonTitle)
            }
            .foregroundColor(.white)
        }
        .frame(height: Length.Hitbox.minTapDimension)
    }
}

private enum Strings {
    static let title = NSLocalizedString(
        "compliance.analytics.popover.title",
        value: "Manage privacy",
        comment: "Title for the privacy compliance popover."
    )

    static let subtitle = NSLocalizedString(
        "compliance.analytics.popover.subtitle",
        value: """
                We process your personal data to optimize our website and
                marketing activities based on your consent and our legitimate interest.
                """,
        comment: "Subtitle for the privacy compliance popover."
    )

    static let toggleTitle = NSLocalizedString(
        "compliance.analytics.popover.toggle",
        value: "Analytics",
        comment: "Toggle Title for the privacy compliance popover."
    )

    static let footnote = NSLocalizedString(
        "compliance.analytics.popover.footnote",
        value: """
                These cookies allow us to optimize performance by collecting
                information on how users interact with our websites.
                """,
        comment: "Footnote for the privacy compliance popover."
    )

    static let settingsButtonTitle = NSLocalizedString(
        "compliance.analytics.popover.settings.button",
        value: "Go to Settings",
        comment: "Settings Button Title for the privacy compliance popover."
    )

    static let saveButtonTitle = NSLocalizedString(
        "compliance.analytics.popover.save.button",
        value: "Save",
        comment: "Save Button Title for the privacy compliance popover."
    )
}
