import SwiftUI

class BloganuaryOverlayViewController: UIViewController {

    private let blogID: Int

    private let promptsEnabled: Bool

    private lazy var viewModel: BloganuaryOverlayViewModel = {
        return BloganuaryOverlayViewModel(promptsEnabled: promptsEnabled, orientation: UIDevice.current.orientation)
    }()

    // MARK: Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupNavigationBar()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        // update view model state after the device has finished the orientation change animation.
        coordinator.animate(alongsideTransition: nil) { [weak self] _ in
            self?.viewModel.orientation = UIDevice.current.orientation
        }
    }

    init(blogID: Int, promptsEnabled: Bool) {
        self.blogID = blogID
        self.promptsEnabled = promptsEnabled
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Private Methods

    private func setupViews() {
        view.backgroundColor = .systemBackground

        let overlayView = BloganuaryOverlayView(viewModel: viewModel, onPrimaryButtonTapped: { [weak self] in
            guard let self else {
                return
            }

            // TODO: Tracks.

            self.dismiss(completion: {
                if self.promptsEnabled {
                    return
                }

                Task { @MainActor in
                    // enable prompts card on the dashboard.
                    BlogDashboardPersonalizationService(siteID: self.blogID).setEnabled(true, for: .prompts)
                }
            })
        })

        let swiftUIView = UIView.embedSwiftUIView(overlayView)
        view.addSubview(swiftUIView)
        view.pinSubviewToAllEdges(swiftUIView)
    }

    private func setupNavigationBar() {
        let appearance = UINavigationBarAppearance()
        appearance.backgroundColor = .systemBackground
        appearance.shadowColor = .clear
        navigationItem.scrollEdgeAppearance = appearance
        navigationItem.compactScrollEdgeAppearance = appearance

        // Set up the close button in the navigation bar.
        let dismissAction = UIAction { [weak self] _ in
            self?.dismiss()
        }
        navigationItem.rightBarButtonItem = UIBarButtonItem(systemItem: .close, primaryAction: dismissAction)
    }

    private func dismiss(completion: (() -> Void)? = nil) {
        navigationController?.dismiss(animated: true, completion: completion)
    }
}

// MARK: - SwiftUI

class BloganuaryOverlayViewModel: ObservableObject {
    let promptsEnabled: Bool
    @Published var orientation: UIDeviceOrientation

    init(promptsEnabled: Bool, orientation: UIDeviceOrientation) {
        self.promptsEnabled = promptsEnabled
        self.orientation = orientation
    }
}

private struct BloganuaryOverlayView: View {

    @ObservedObject var viewModel: BloganuaryOverlayViewModel

    @State var scrollViewHeight: CGFloat = 0.0

    var onPrimaryButtonTapped: (() -> Void)?

    @ScaledMetric(relativeTo: Constants.descriptionTextStyle)
    private var descriptionIconSize = 24.0

    @ScaledMetric(relativeTo: Constants.descriptionTextStyle)
    private var descriptionItemHSpacing = 16.0

    @ScaledMetric(relativeTo: Constants.descriptionTextStyle)
    private var descriptionItemVSpacing = 24.0

    var body: some View {
        VStack(spacing: .zero) {
            contentScrollView
            footerContainer
        }
    }

    var contentScrollView: some View {
        ScrollView {
            VStack {
                content
                Spacer(minLength: 32.0)
                Text(stringForFooter)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, Constants.horizontalPadding)
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical, 18.0)
            .frame(minHeight: scrollViewHeight, maxHeight: .infinity)
        }
        .layoutPriority(1) // force the scroll view to fill most of the screen space.
        .background {
            // try to get the scrollView height and use it as the ideal height for its content view.
            GeometryReader { geo in
                Color.clear
                    .onAppear {
                        scrollViewHeight = geo.size.height
                    }
                    .onChange(of: viewModel.orientation) { _ in
                        // since onAppear is only called once, assign the value again every time the orientation changes.
                        scrollViewHeight = geo.size.height
                    }
            }
        }
    }

    var content: some View {
        VStack(alignment: .center, spacing: 24.0) {
            Image(Constants.bloganuaryImageName, bundle: nil)
                .resizable()
                .renderingMode(.template)
                .foregroundStyle(.primary)
                .scaledToFit()
                .frame(width: Constants.preferredLogoWidth, height: Constants.preferredLogoHeight)
            descriptionContainer
        }
        .padding(.horizontal, Constants.horizontalPadding)
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    var descriptionContainer: some View {
        VStack(alignment: .leading, spacing: 32.0) {
            Text(Strings.headline)
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .center)
            descriptionList
        }
    }

    var descriptionList: some View {
        HStack(spacing: .zero) {
            Spacer(minLength: .zero)
            VStack(alignment: .leading, spacing: descriptionItemVSpacing) {
                descriptionEntry(iconName: Constants.firstDescriptionIconName, text: Strings.firstDescriptionLine)
                descriptionEntry(iconName: Constants.secondDescriptionIconName, text: Strings.secondDescriptionLine)
                descriptionEntry(iconName: Constants.thirdDescriptionIconName, text: Strings.thirdDescriptionLine)
            }
            .padding(.horizontal, 16.0)
            .frame(maxWidth: 420.0)
            .layoutPriority(1)
            Spacer(minLength: .zero)
        }
    }

    func descriptionEntry(iconName: String, text: String) -> some View {
        HStack(alignment: .center, spacing: descriptionItemHSpacing) {
            descriptionIconView(for: iconName)
            Text(text)
                .font(.headline)
                .fontWeight(.semibold)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    var footerContainer: some View {
        VStack(spacing: .zero) {
            Divider()
                .frame(maxWidth: .infinity)
            Group {
                ctaButton
            }
            .padding(WPDeviceIdentification.isiPad() ? .vertical : .top, 24.0)
            .padding(.horizontal, Constants.horizontalPadding)
        }
    }

    var ctaButton: some View {
        Button {
            onPrimaryButtonTapped?()
        } label: {
            Text(viewModel.promptsEnabled ? Strings.buttonTitleForEnabledPrompts : Strings.buttonTitleForDisabledPrompts)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 14.0)
        .padding(.horizontal, 20.0)
        .frame(maxWidth: .infinity, alignment: .center)
        .foregroundStyle(Color(.systemBackground))
        .background(Color(.label))
        .clipShape(RoundedRectangle(cornerRadius: 12.0))
    }

    var stringForFooter: String {
        guard viewModel.promptsEnabled else {
            return "\(Strings.footer) \(Strings.footerAddition)"
        }
        return Strings.footer
    }

    func descriptionIconView(for iconName: String) -> some View {
        Image(iconName, bundle: nil)
            .resizable()
            .renderingMode(.template)
            .foregroundStyle(Color(.systemBackground))
            .flipsForRightToLeftLayoutDirection(true)
            .frame(width: descriptionIconSize, height: descriptionIconSize)
            .padding(12.0)
            .background {
                Circle().fill(.primary)
            }
    }

    // MARK: Constants

    struct Constants {
        static let horizontalPadding: CGFloat = 32.0
        static let preferredLogoWidth: CGFloat = 180.0
        static let preferredLogoHeight: CGFloat = 42.0
        static let bloganuaryImageName = "logo-bloganuary-large"
        static let descriptionTextStyle: Font.TextStyle = .headline

        static let firstDescriptionIconName = "bloganuary-icon-page"
        static let secondDescriptionIconName = "bloganuary-icon-verse"
        static let thirdDescriptionIconName = "bloganuary-icon-people"
    }

    struct Strings {
        static let headline = NSLocalizedString(
            "bloganuary.learnMore.modal.headline",
            value: "Join our month-long writing challenge",
            comment: "The headline text of the Bloganuary modal sheet."
        )

        static let firstDescriptionLine = NSLocalizedString(
            "bloganuary.learnMore.modal.descriptions.first",
            value: "Receive a new prompt to inspire you each day.",
            comment: "The first line of the description shown in the Bloganuary modal sheet."
        )

        static let secondDescriptionLine = NSLocalizedString(
            "bloganuary.learnMore.modal.description.second",
            value: "Publish your response.",
            comment: "The second line of the description shown in the Bloganuary modal sheet."
        )

        static let thirdDescriptionLine = NSLocalizedString(
            "bloganuary.learnMore.modal.description.third",
            value: "Read other bloggers’ responses to get inspiration and make new connections.",
            comment: "The third line of the description shown in the Bloganuary modal sheet."
        )

        static let footer = NSLocalizedString(
            "bloganuary.learnMore.modal.footer.text",
            value: "Bloganuary will use Daily Blogging Prompts to send you topics for the month of January.",
            comment: "An informative excerpt shown in a subtler tone."
        )

        static let footerAddition = NSLocalizedString(
            "bloganuary.learnMore.modal.footer.addition",
            value: "To join Bloganuary you need to enable Blogging Prompts.",
            comment: "An additional piece of information shown in case the user has the Blogging Prompts feature disabled."
        )

        static let buttonTitleForDisabledPrompts = NSLocalizedString(
            "bloganuary.learnMore.modal.button.promptsDisabled",
            value: "Turn on blogging prompts",
            comment: "Title of a button that calls the user to enable the Blogging Prompts feature."
        )

        static let buttonTitleForEnabledPrompts = NSLocalizedString(
            "bloganuary.learnMore.modal.button.promptsEnabled",
            value: "Let’s go!",
            comment: """
                Title of a button that will dismiss the Bloganuary modal when tapped.
                Note that the word 'go' here should have a closer meaning to 'start' rather than 'move forward'.
                """
        )
    }
}
