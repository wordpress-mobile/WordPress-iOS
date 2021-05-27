
import SwiftUI


struct BloggingRemindersCard: View {

    var getStartedButtonAction: () -> Void
    var ellipsisButtonAction: () -> Void

    var body: some View {
        VStack {
            HStack {
                // Title
                Text(TextContent.cardTitle)
                    .font(TextContent.cardTitleFont)
                Spacer()
                // Vertical ellipsis button
                makeEllipsisButton {
                    ellipsisButtonAction()
                }
            }

            HStack {
                // Calendar Image
                VStack {
                    Image(Images.calendarImageName)
                        .padding(Metrics.calendarImageInsets)
                    Spacer()
                }

                Spacer()

                VStack(alignment: .leading) {
                    // Description
                    Text(TextContent.cardDescription)
                        .font(TextContent.cardDescriptionFont)
                        .lineLimit(nil)
                        .padding()

                    Spacer()

                    // Get Started button
                    makeGetStartedButton {
                        getStartedButtonAction()
                    }
                }
                Spacer()
            }
        }
        .padding()
    }
}

// MARK: - UI Factory
private extension BloggingRemindersCard {

    /// builds the vertical ellipsis button
    func makeEllipsisButton(action: @escaping () -> Void) -> some View {
        Button(action: {
            action()
        }) {
            Image(Images.ellipsisImageName)
                .foregroundColor(Color(UIColor(light: .muriel(color: .gray, .shade50),
                                               dark: .textSubtle)))
        }
    }

    /// builds the get started button
    func makeGetStartedButton(action: @escaping () -> Void) -> some View {
        Button(action: {
            action()
        }) {
            Text(TextContent.getStartedButtonTitle)
                .font(TextContent.getStartedButtonFont)
                .padding(Metrics.getStartedButtonTextInsets)
                .foregroundColor(.white)
                .background(Color(UIColor.muriel(name: .blue, .shade30))
                                .clipShape(Capsule()))
        }
        .fixedSize(horizontal: true, vertical: true)
        .padding(Metrics.getStartedButtonInsets)
    }
}


private enum TextContent {

    static let cardTitle = NSLocalizedString("Set your blogging goals",
                                             comment: "Title of the Blogging Reminders card in My Site.")

    static let cardTitleFont = Font(WPStyleGuide.serifFontForTextStyle(.title3) as CTFont)

    static let cardDescription = NSLocalizedString("Make the most of your site by setting goals and tracking your progress.",
                                                   comment: "Description of the Blogging Reminders card in My Site.")

    static let cardDescriptionFont = Font.subheadline

    static let getStartedButtonTitle = NSLocalizedString("Get Started",
                                                         comment: "Title of the Get Started button of the Blogging Reminders card in My Site.")

    static let getStartedButtonFont = Font.subheadline
}

private enum Images {

    static let calendarImageName = "Hands-Calendar"
    static let ellipsisImageName = "icon-menu-vertical-ellipsis"
}

private enum Metrics {

    static let calendarImageInsets = EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 0)
    static let getStartedButtonTextInsets = EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16)
    static let getStartedButtonInsets = EdgeInsets(top: 0, leading: 16, bottom: 16, trailing: 16)
}
