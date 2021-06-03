import SwiftUI
import UIKit


class BloggingRemindersFlowIntroViewController: UIViewController, DrawerPresentable {
    private let stackView = UIStackView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .basicBackground

        stackView.spacing = 20.0
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.distribution = .equalSpacing

        let imageView = UIImageView(image: UIImage(systemName: "star.circle"))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.tintColor = .systemYellow

        let titleLabel = UILabel()
        titleLabel.font = WPStyleGuide.serifFontForTextStyle(.title1, fontWeight: .semibold)
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .center

        if let account = try? WPAccount.lookupDefaultWordPressComAccount(in: ContextManager.shared.mainContext),
           let name = account.settings?.firstName,
           name.isEmpty == false {
            titleLabel.text = String(format: NSLocalizedString("%@, set your blogging goals", comment: ""), name)
        }

        if (titleLabel.text ?? "").isEmpty {
            titleLabel.text = "Set your blogging goals"
        }

        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .body)
        label.text = TextContent.introDescription
        label.numberOfLines = 0
        label.textAlignment = .center

        let button = FancyButton()
        button.isPrimary = true
        button.setTitle(TextContent.getStartedButtonTitle, for: .normal)

        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)

        stackView.addArrangedSubviews([
            imageView,
            titleLabel,
            label,
            button,
            UIView()
        ])

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16.0),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16.0),
            stackView.topAnchor.constraint(equalTo: view.topAnchor, constant: 16.0),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: view.safeBottomAnchor, constant: -16.0),
            imageView.heightAnchor.constraint(equalToConstant: 44.0),
            imageView.widthAnchor.constraint(equalToConstant: 44.0),
            button.heightAnchor.constraint(equalToConstant: 44.0),
            button.widthAnchor.constraint(equalTo: stackView.widthAnchor)
        ])

        view.layoutIfNeeded()
        calculatePreferredContentSize()

        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        calculatePreferredContentSize()
    }

    func calculatePreferredContentSize() {
        let size = CGSize(width: view.bounds.width, height: UIView.layoutFittingCompressedSize.height)
        preferredContentSize = stackView.systemLayoutSizeFitting(size)
    }

    var collapsedHeight: DrawerHeight {
        return .intrinsicHeight
    }
}

/// This allows us to dismiss the UIKit-presented SwiftUI flow.
/// We'll pass it through the screens as an environment object.
///
final class BlogRemindersCoordinator: ObservableObject {
    weak var presenter: UIViewController?

    func dismiss() {
        presenter?.dismiss(animated: true)
    }
}

/// UIKit container for the SwiftUI-based reminders setting flow.
///
class BloggingRemindersSettingsContainerViewController: UIViewController, DrawerPresentable {
    var coordinator: BlogRemindersCoordinator

    init(coordinator: BlogRemindersCoordinator) {
        self.coordinator = coordinator
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .basicBackground

        let rootView = BloggingRemindersSettingsIntroView().environmentObject(self.coordinator)
        let host = UIHostingController(rootView: rootView)
        host.view.translatesAutoresizingMaskIntoConstraints = false
        addChild(host)
        view.addSubview(host.view)

        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: host.view.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: host.view.trailingAnchor),
            view.topAnchor.constraint(equalTo: host.view.topAnchor),
            view.bottomAnchor.constraint(greaterThanOrEqualTo: host.view.bottomAnchor),
            ])

        host.didMove(toParent: self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let hostView = view.subviews.first {
            preferredContentSize = hostView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        }
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
                Spacer()
                    .frame(height: 200)
                NavigationLink(destination: BloggingRemindersSettingsView().environmentObject(coordinator)) {
                    Text(TextContent.getStartedButtonTitle)
                        .primaryButtonStyle()
                }
            }
            .fixedSize(horizontal: false, vertical: true)
        .padding()
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
            Spacer()
                .frame(height: 50)
            Button(action: {
                coordinator.dismiss()
            }) {
                Text(TextContent.doneButtonTitle)
                    .primaryButtonStyle()
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding()
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
