
import SwiftUI


struct BloggingRemindersCard: View {

    var getStartedButtonAction: () -> Void
    var ellipsisButtonAction: () -> Void

    var body: some View {
        VStack {
            HStack {
                Text(TextContent.cardTitle)
                    .font(TextContent.cardTitleFont)
                Spacer()
                Button(action: {
                    ellipsisButtonAction()
                }) {
                    Image(Images.ellipsisImageName)
                        .foregroundColor(.black)
                }

            }
            HStack {
                VStack {
                    Image(Images.calendarImageName)
                        .padding(Metrics.calendarImageInsets)
                    Spacer()
                }
                Spacer()
                VStack(alignment: .leading) {
                    Text(TextContent.cardDescription)
                        .font(TextContent.cardDescriptionFont)
                        .lineLimit(nil)
                        .padding()
                    Spacer()
                    Button(action: {
                        getStartedButtonAction()
                    }) {
                        Text(TextContent.getStartedButtonTitle)
                            .font(TextContent.getStartedButtonFont)
                            .padding(Metrics.getStartedButtonTextInsets)
                            .foregroundColor(.white)
                            .background(Color(UIColor.muriel(name: .blue, .shade30))
                                            .clipShape(Capsule())
                            )
                    }
                    .fixedSize(horizontal: true, vertical: true)
                    .padding(Metrics.getStartedButtonInsets)
                }
                Spacer()
            }
        }
        .padding()
    }
}


private enum TextContent {

    static let cardTitle = NSLocalizedString("Set your blogging goals",
                                             comment: "Title of the Blogging Reminders card in My Site.")

    static let cardTitleFont = Font.system(size: 22, weight: .regular, design: .serif)

    static let cardDescription = NSLocalizedString("Make the most of your site by setting goals and tracking your progress.",
                                                   comment: "Description of the Blogging Reminders card in My Site.")

    static let cardDescriptionFont = Font.system(size: 16, weight: .regular, design: .default)

    static let getStartedButtonTitle = NSLocalizedString("Get Started",
                                                         comment: "Title of the Get Started button of the Blogging Reminders card in My Site.")

    static let getStartedButtonFont = Font.system(size: 16, weight: .regular, design: .default)
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
