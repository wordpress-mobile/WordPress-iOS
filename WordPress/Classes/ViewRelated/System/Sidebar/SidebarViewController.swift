import UIKit
import BuildSettingsKit
import SwiftUI
import Combine
import WordPressData
import WordPressKit
import WordPressUI

/// The sidebar for the iPad version of the app.
final class SidebarViewController: UIViewController, SiteMenuViewControllerDelegate {
    private let viewModel: SidebarViewModel
    private let segmentedControl = UISegmentedControl()
    private var currentChildViewController: UIViewController?
    private var cancellables: [AnyCancellable] = []
    private let notificationsButtonViewModel = NotificationsButtonViewModel()
    private var profileButtonController: ProfileButtonController?

    weak var topSplitViewController: UISplitViewController?

    init(viewModel: SidebarViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupSegmentedControl()
        setupBarButtonItems()
        setupObservers()
    }

    private func setupSegmentedControl() {
        for (index, item) in SidebarMode.allCases.enumerated() {
            let title = item.localizedTitle
            segmentedControl.insertSegment(withTitle: title, at: index, animated: false)
        }
        segmentedControl.addTarget(self, action: #selector(segmentedControlValueChanged), for: .valueChanged)

        view.addSubview(segmentedControl)
        segmentedControl.pinEdges([.horizontal, .bottom], to: view.safeAreaLayoutGuide, insets: UIEdgeInsets(.all, 16))
    }

    private func setupBarButtonItems() {
        let profileButton = UIBarButtonItem(
            image: UIImage(systemName: "person.crop.circle"),
            style: .plain,
            target: self,
            action: #selector(profileButtonTapped)
        )

        navigationItem.leftBarButtonItems = [profileButton]
        profileButtonController = ProfileButtonController(barButtonItem: profileButton)

        notificationsButtonViewModel.$image.sink { [weak self] image in
            guard let self else { return }

            let notificationsButton = UIBarButtonItem(
                image: image,
                style: .plain,
                target: self,
                action: #selector(self.notificationsButtonTapped)
            )

            var rightBarButtonItems = [notificationsButton]

            // Add Help button for Jetpack
            if BuildSettings.current.brand == .jetpack {
                let helpButton = UIBarButtonItem(
                    image: UIImage(systemName: "questionmark.circle"),
                    style: .plain,
                    target: self,
                    action: #selector(self.helpButtonTapped)
                )
                rightBarButtonItems.append(helpButton)
            }

            self.navigationItem.rightBarButtonItems = rightBarButtonItems
        }.store(in: &cancellables)
    }

    private func setupObservers() {
        viewModel.$mode.sink { [weak self] mode in
            self?.configure(for: mode)
        }.store(in: &cancellables)

        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in self?.applicationDidBecomeActive() }
            .store(in: &cancellables)
    }

    // MARK: - Actions

    @objc private func segmentedControlValueChanged(_ sender: UISegmentedControl) {
        viewModel.mode = SidebarMode.allCases[sender.selectedSegmentIndex]
    }

    @objc private func profileButtonTapped() {
        viewModel.navigate(.profile)
    }

    @objc private func helpButtonTapped() {
        viewModel.navigate(.help)
    }

    @objc private func notificationsButtonTapped(_ sender: UIBarButtonItem) {
        NotificationsViewController.showInPopover(from: self, sourceItem: sender)
    }

    @objc private func applicationDidBecomeActive() {
        trackAnalytics(for: viewModel.mode)
    }

    // MARK: - Modes

    private func configure(for mode: SidebarMode) {
        if let index = SidebarMode.allCases.firstIndex(of: mode) {
            if segmentedControl.selectedSegmentIndex != index {
                segmentedControl.selectedSegmentIndex = index
            }
        }

        switch mode {
        case .sites:
            if let site = viewModel.siteViewModel {
                let siteVC = SiteMenuViewController(viewModel: site)
                siteVC.delegate = self
                showChildViewController(siteVC)
            } else {
                // TODO: (kean) add empry state view
            }
        case .reader:
            showChildViewController(viewModel.readerPresenter.sidebar)
            viewModel.readerPresenter.showInitialSelection()
        }

        trackAnalytics(for: mode)
    }

    private func trackAnalytics(for mode: SidebarMode) {
        switch mode {
        case .sites: WPAnalytics.track(.mySitesTabAccessed)
        case .reader: WPAnalytics.track(.readerAccessed)
        }
    }

    private func showChildViewController(_ childViewController: UIViewController) {
        // Remove current child if exists
        if let currentChild = currentChildViewController {
            _removeChildViewController(currentChild)
        }

        // Add new child
        _addChildViewController(childViewController)
        currentChildViewController = childViewController
    }

    private func _addChildViewController(_ child: UIViewController) {
        addChild(child)
        view.insertSubview(child.view, belowSubview: segmentedControl)
        child.view.pinEdges()
        child.didMove(toParent: self)
    }

    private func _removeChildViewController(_ child: UIViewController) {
        child.willMove(toParent: nil)
        child.view.removeFromSuperview()
        child.removeFromParent()
    }

    // MARK: - SiteMenuViewControllerDelegate

    func siteMenuViewController(_ siteMenuViewController: SiteMenuViewController, showDetailsViewController viewController: UIViewController) {
        guard let splitVC = topSplitViewController else {
            return wpAssertionFailure("missing split view controller")
        }
        if viewController is UINavigationController || viewController is UISplitViewController {
            splitVC.setViewController(viewController, for: .secondary)
        } else {
            // Reset previous navigation or split stack
            let navigationVC = UINavigationController(rootViewController: viewController)
            splitVC.setViewController(navigationVC, for: .secondary)
        }
    }
}
