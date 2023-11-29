import SwiftUI

class BloganuaryOverlayViewController: UIViewController {

    private lazy var viewModel: BloganuaryOverlayViewModel = {
        return BloganuaryOverlayViewModel(orientation: UIDevice.current.orientation)
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

    // MARK: Private Methods

    private func setupViews() {
        view.backgroundColor = .systemBackground

        let swiftUIView = UIView.embedSwiftUIView(BloganuaryOverlayView(viewModel: viewModel))
        view.addSubview(swiftUIView)
        view.pinSubviewToAllEdges(swiftUIView)
    }

    private func setupNavigationBar() {
        let dismissAction = UIAction { [weak self] _ in
            self?.navigationController?.dismiss(animated: true)
        }
        navigationItem.rightBarButtonItem = UIBarButtonItem(systemItem: .close, primaryAction: dismissAction)
    }
}

// - MARK: SwiftUI

class BloganuaryOverlayViewModel: ObservableObject {
    @Published var orientation: UIDeviceOrientation

    init(orientation: UIDeviceOrientation) {
        self.orientation = orientation
    }
}

private struct BloganuaryOverlayView: View {

    @ObservedObject var viewModel: BloganuaryOverlayViewModel

    @State var scrollViewHeight: CGFloat = 0.0

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
                Spacer(minLength: 16.0)
                Text("Bloganuary will take over the normal blogging prompts you see from Day One for January. To join Bloganuary you need to enable Blogging Prompts.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, Metrics.horizontalPadding)
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
        VStack(alignment: .leading) {
            Image("logo-bloganuary", bundle: .main)
                .resizable()
                .frame(width: 42.0, height: 42.0) // TODO: Figure out aspect ratio sizing.
            Spacer(minLength: 16.0)
                .frame(maxHeight: 72.0)
            descriptionContainer
        }
        .padding(.horizontal, Metrics.horizontalPadding)
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    var descriptionContainer: some View {
        VStack(alignment: .leading, spacing: 24.0) {
            Text("Join our month-long writing challenge") // TODO: Localize
                .font(.largeTitle)
                .fontWeight(.bold)
            descriptionList
        }
    }

    // TODO: Localize
    var descriptionList: some View {
        VStack(alignment: .leading, spacing: 16.0) {
            Text("Receive a new prompt to inspire you each day.")
            Text("Publish your response.")
            Text("Read other bloggers’ responses to get inspiration and make new connections.")
        }
    }

    var footerContainer: some View {
        VStack(spacing: .zero) {
            Divider()
                .frame(maxWidth: .infinity)
            Group {
                button
            }
            .padding(.top, 24.0)
            .padding(.horizontal, Metrics.horizontalPadding)
        }
    }

    var button: some View {
        // TODO: Deal with the button style.
        Button {
            // TODO: Implement.
        } label: {
            Text("Turn on blogging prompts") // TODO: Variate based on blogging prompt status.
        }
        .padding(.vertical, 14.0)
        .padding(.horizontal, 20.0)
        .frame(maxWidth: .infinity, alignment: .center)
        .foregroundStyle(Color(.systemBackground))
        .background(Color(.label))
        .clipShape(RoundedRectangle(cornerRadius: 12.0))
    }

    // MARK: Constants

    struct Metrics {
        static let horizontalPadding: CGFloat = 32.0
    }

    struct Strings {
        // TODO
    }
}
