import SwiftUI
import UIKit

/// This allows us to dismiss the UIKit-presented SwiftUI flow.
/// We'll pass it through the screens as an environment object.
///
final class BlogRemindersCoordinator: ObservableObject {
    var presenter: UIViewController?

    func dismiss() {
        presenter?.dismiss(animated: true)
    }
}

/// UIKit container for the SwiftUI-based reminders setting flow.
///
class BloggingRemindersSettingsContainerViewController: UIViewController, DrawerPresentable {
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .basicBackground

        let rootView = BloggingRemindersSettingsIntroView().environmentObject(makeCoordinator())
        let host = UIHostingController(rootView: rootView)

        host.view.translatesAutoresizingMaskIntoConstraints = false
        addChild(host)
        view.addSubview(host.view)
        view.pinSubviewToAllEdges(host.view)
        host.didMove(toParent: self)
    }

    func makeCoordinator() -> BlogRemindersCoordinator {
        let coordinator = BlogRemindersCoordinator()
        coordinator.presenter = self
        return coordinator
    }

    var collapsedHeight: DrawerHeight {
        .intrinsicHeight
    }

    var allowsDragToDismiss: Bool {
        true
    }
}

struct BloggingRemindersSettingsIntroView: View {
    @EnvironmentObject var coordinator: BlogRemindersCoordinator

    var body: some View {
        VStack(spacing: Metrics.introStackSpacing) {
            Image(systemName: Images.starImageName)
                .resizable().frame(width: Metrics.topImageSize.width, height: Metrics.topImageSize.height, alignment: .center)
            Text(TextContent.introTitle)
                .font(TextContent.introTitleFont)
            Text(TextContent.introDescription)
            NavigationLink(destination: BloggingRemindersSettingsView().environmentObject(coordinator)) {
                Text(TextContent.getStartedButtonTitle)
                    .primaryButtonStyle()
            }
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationBarHidden(true)
    }
}

struct BloggingRemindersSettingsView: View {
    @EnvironmentObject var coordinator: BlogRemindersCoordinator

    // TODO: This will be replaced by some observable object or similar that
    // coordinates with our reminders store. @frosty
    @SwiftUI.State private var toggles: [Bool] = [false, false, false, false, false, false, false]

    let days: [String] = {
        var calendar = Calendar.current
        calendar.locale = Locale.autoupdatingCurrent
        let firstWeekday = calendar.firstWeekday
        var symbols = calendar.shortWeekdaySymbols

        let localizedWeekdays: [String] = Array(symbols[firstWeekday - 1 ..< Calendar.current.shortWeekdaySymbols.count] + symbols[0 ..< firstWeekday - 1])

        return localizedWeekdays
    }()

    var body: some View {
        VStack(spacing: Metrics.settingsStackSpacing) {
            Spacer()
            Image(systemName: Images.calendarImageName)
                .resizable()
                .frame(width: Metrics.topImageSize.width, height: Metrics.topImageSize.height, alignment: .center)
            VStack(spacing: Metrics.settingsInnerStackSpacing) {
                Text(TextContent.settingsPrompt)
                    .font(TextContent.settingsPromptFont)
                    .fontWeight(.semibold)
                    .lineLimit(nil)
                    .multilineTextAlignment(.center)
                Text(TextContent.settingsUpdatePrompt)
                    .foregroundColor(.gray)
                    .lineLimit(2)
            }
            HStack {
                ForEach(days.indices, id: \.self) { index in
                    Toggle(days[index].uppercased(), isOn: $toggles[index])
                        .toggleStyle(CheckboxToggleStyle())
                        .frame(minWidth: 0, maxWidth: .infinity)
                }
            }
            Spacer()
                .frame(maxHeight: .infinity)
            NavigationLink(destination: BloggingRemindersSettingsCompletionView().environmentObject(coordinator)) {
                Text(TextContent.nextButtonTitle)
                    .primaryButtonStyle()
            }
            Spacer()
        }
        .padding()
        .navigationBarHidden(true)
    }
}

struct BloggingRemindersSettingsCompletionView: View {
    @EnvironmentObject var coordinator: BlogRemindersCoordinator

    var body: some View {
        VStack(spacing: Metrics.completionStackSpacing) {
            Image(systemName: Images.clockImageName)
            Text(TextContent.completionTitle)
                .font(TextContent.completionTitleFont)
                .bold()
            // TODO: This needs to be constructed with the correct information in it
            // based on the user's choices. @frosty
            Text("You'll get reminders to blog 2 times a week on Wednesday and Thursday.")
            Text(TextContent.completionUpdatePrompt)
                .foregroundColor(.gray)
                .lineLimit(2)
            Button(action: {
                coordinator.dismiss()
            }) {
                Text(TextContent.doneButtonTitle)
                    .primaryButtonStyle()
            }
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationBarHidden(true)
    }
}

/// A custom checkbox style show a label in the center of a circle.
///
struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        return Circle()
            .fill(configuration.isOn ? Color.green : Color(UIColor.lightGray))
            .frame(width: Metrics.checkboxSize.width, height: Metrics.checkboxSize.height)
            .onTapGesture { configuration.isOn.toggle() }
            .overlay(
                configuration.label
                    .foregroundColor(configuration.isOn ? .white : Color(UIColor.darkGray))
            )
    }
}

private enum TextContent {

    static let introTitle = NSLocalizedString("Set your blogging goals",
                                              comment: "Title of the Blogging Reminders Settings screen.")

    static let introTitleFont = Font.system(.title, design: .serif).bold()

    static let introDescription = NSLocalizedString("Well done on your first post! Keep it going. You can now set your blogging goals, get reminders, and track your progress.",
                                                    comment: "Description on the first screen of the Blogging Reminders Settings flow.")

    static let getStartedButtonTitle = NSLocalizedString("Get Started",
                                                         comment: "Title of the Get Started button in the Blogging Reminders Settings flow.")

    static let settingsPrompt = NSLocalizedString("Select the days you want to blog on",
                                                  comment: "Prompt shown on the Blogging Reminders Settings screen.")
    static let settingsPromptFont = Font.system(.largeTitle, design: .serif)

    static let settingsUpdatePrompt = NSLocalizedString("You can update this any time.",
                                                        comment: "Prompt shown on the Blogging Reminders Settings screen.")

    static let nextButtonTitle = NSLocalizedString("Next", comment: "Title of button to navigate to the next screen.")

    static let completionTitle = NSLocalizedString("All set!", comment: "Title of the completion screen of the Blogging Reminders Settings screen.")

    static let completionTitleFont = Font.system(.title, design: .serif)

    static let completionUpdatePrompt = NSLocalizedString("You can update this any time via My Site > Site Settings",
                                                          comment: "Prompt shown on the completion screen of the Blogging Reminders Settings screen.")

    static let doneButtonTitle = NSLocalizedString("Done", comment: "Title for a Done button.")
}

private enum Images {

    static let starImageName = "star.circle"
    static let calendarImageName = "calendar"
    static let clockImageName = "deskclock"
}

private enum Metrics {

    static let introStackSpacing: CGFloat = 10.0
    static let topImageSize = CGSize(width: 66.0, height: 66.0)
    static let settingsStackSpacing: CGFloat = 50.0
    static let settingsInnerStackSpacing: CGFloat = 50.0
    static let completionStackSpacing: CGFloat = 10.0
    static let checkboxSize = CGSize(width: 44.0, height: 44.0)
}
