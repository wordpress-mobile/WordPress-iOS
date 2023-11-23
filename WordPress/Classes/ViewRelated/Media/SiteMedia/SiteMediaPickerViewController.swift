import UIKit

protocol SiteMediaPickerViewControllerDelegate: AnyObject {
    /// If the user cancels the flow, the selection is empty.
    func siteMediaPickerViewController(_ viewController: SiteMediaPickerViewController, didFinishWithSelection selection: [Media])
}

/// The media picker for your site media.
final class SiteMediaPickerViewController: UIViewController, SiteMediaCollectionViewControllerDelegate {
    private let blog: Blog
    private let allowsMultipleSelection: Bool

    private let collectionViewController: SiteMediaCollectionViewController
    private let toolbarItemTitle = SiteMediaSelectionTitleView()
    private lazy var buttonDone = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(buttonDoneTapped))

    weak var delegate: SiteMediaPickerViewControllerDelegate?

    /// Initializes the media picker with the given parameters.
    ///
    /// - parameters:
    ///   - blog: The site that contains the media
    ///   - filter: The types of media to display. By default, `nil` (show everything).
    ///   - allowsMultipleSelection: `false` by default.
    init(blog: Blog, filter: Set<MediaType>? = nil, allowsMultipleSelection: Bool = false) {
        self.blog = blog
        self.allowsMultipleSelection = allowsMultipleSelection
        self.collectionViewController = SiteMediaCollectionViewController(blog: blog, filter: filter, isShowingPendingUploads: false)

        super.init(nibName: nil, bundle: nil)

        title = Strings.title
        extendedLayoutIncludesOpaqueBars = true
        modalPresentationStyle = .formSheet
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        collectionViewController.embed(in: self)
        collectionViewController.delegate = self

        configureDefaultNavigationBarAppearance()
        configureNavigationItems()
        startSelection()
    }

    // MARK: - Configuration

    private func configureNavigationItems() {
        let buttonCancel = UIBarButtonItem(systemItem: .cancel, primaryAction: UIAction { [weak self] _ in
            self?.buttonCancelTapped()
        })

        navigationItem.leftBarButtonItem = buttonCancel
        if allowsMultipleSelection {
            navigationItem.rightBarButtonItems = [buttonDone]
        }

        navigationItem.hidesSearchBarWhenScrolling = false
    }

    // MARK: - Actions

    private func buttonCancelTapped() {
        delegate?.siteMediaPickerViewController(self, didFinishWithSelection: [])
    }

    @objc private func buttonDoneTapped() {
        delegate?.siteMediaPickerViewController(self, didFinishWithSelection: collectionViewController.selectedMedia)
    }

    // MARK: - Selection

    private func startSelection() {
        collectionViewController.setEditing(true, allowsMultipleSelection: allowsMultipleSelection, isSelectionOrdered: true)

        if allowsMultipleSelection, toolbarItems == nil {
            var toolbarItems: [UIBarButtonItem] = []
            toolbarItems.append(UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil))
            toolbarItems.append(UIBarButtonItem(customView: toolbarItemTitle))
            toolbarItems.append(UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil))
            self.toolbarItems = toolbarItems

            self.navigationController?.setToolbarHidden(false, animated: false)
        }

        didUpdateSelection([])
    }

    private func didUpdateSelection(_ selection: [Media]) {
        toolbarItemTitle.setSelection(selection)
        buttonDone.isEnabled = !selection.isEmpty
    }

    // MARK: - SiteMediaCollectionViewControllerDelegate

    func siteMediaViewController(_ viewController: SiteMediaCollectionViewController, contextMenuFor media: Media) -> UIMenu? {
        let title = viewController.isSelected(media) ? Strings.deselect : Strings.select
        UIMenu(children: [UIAction(title: title, image: UIImage(systemName: "checkmark.circle")) { [weak self] _ in
            self?.collectionViewController.toggleSelection(for: media)
        }])
    }

    func siteMediaViewController(_ viewController: SiteMediaCollectionViewController, didUpdateSelection selection: [Media]) {
        if !allowsMultipleSelection {
            if !selection.isEmpty {
                delegate?.siteMediaPickerViewController(self, didFinishWithSelection: selection)
            }
        } else {
            didUpdateSelection(selection)
        }
    }
}

private enum Strings {
    static let title = NSLocalizedString("siteMediaPicker.title", value: "Media", comment: "Media screen navigation title")
    static let select = NSLocalizedString("siteMediaPicker.select", value: "Select", comment: "Button selection media in media picker")
    static let deselect = NSLocalizedString("siteMediaPicker.deselect", value: "Deselect", comment: "Button selection media in media picker")
}
