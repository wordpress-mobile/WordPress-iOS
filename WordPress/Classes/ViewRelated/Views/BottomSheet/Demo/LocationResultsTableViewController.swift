
import UIKit

// MARK: - SearchBarSansCancel

class SearchBarSansCancel: UISearchBar {
    override func setShowsCancelButton(_ showsCancelButton: Bool, animated: Bool) {
        super.setShowsCancelButton(false, animated: false)
    }
}

// MARK: - SearchControllerSansCancel

class SearchControllerSansCancel: UISearchController {
    lazy var searchBarSansCancel: SearchBarSansCancel = { [unowned self] in
        let searchBar = SearchBarSansCancel(frame: CGRect.zero)
        return searchBar
    }()

    override var searchBar: UISearchBar {
        get {
            return searchBarSansCancel
        }
    }
}

// MARK: - LocationResultsTableViewController

class LocationResultsTableViewController: UITableViewController {

    // MARK: Properties

    private struct Constants {
        static let defaultRowHeight         = CGFloat(60)
        static let searchBarTextPadding     = CGFloat(13)
        static let searchBarFontSize        = CGFloat(17)
        static let separatorInsetLeading    = CGFloat(15)
        static let summaryAnimationDuration = TimeInterval(0.3)
        static let summaryFontSize          = CGFloat(22)
        static let summaryLabelWidth        = CGFloat(300)
        static let summaryTopInset          = CGFloat(64)
    }

    private let searchController = SearchControllerSansCancel(searchResultsController: nil)

    private(set) var searchQuery = ""

    private let resultsProvider = LocationResultsTableViewProvider()

    private lazy var resultSummaryLabel: UILabel = {
        let label = UILabel()

        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0

        label.preferredMaxLayoutWidth = CGFloat(Constants.summaryLabelWidth)
        label.font = UIFont.systemFont(ofSize: Constants.summaryFontSize)
        label.textColor = WPStyleGuide.greyDarken10()
        label.textAlignment = .center

        label.text = LocationResultsMessages.noSearch.rawValue
        label.sizeToFit()

        return label
    }()

    // MARK: Initialization

    init() {
        super.init(style: .plain)
    }

    // MARK: UIViewController lifecycle

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupView()
        definesPresentationContext = true
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        searchController.isActive = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if self.searchController.searchBar.canResignFirstResponder {
            self.searchController.searchBar.resignFirstResponder()
        }
    }
}

// MARK: - UISearchBarDelegate

extension LocationResultsTableViewController: UISearchBarDelegate {

    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        configure(searchBar: searchBar)
        return true
    }
}

// MARK: - UISearchControllerDelegate

extension LocationResultsTableViewController: UISearchControllerDelegate {

    func willPresentSearchController(_ searchController: UISearchController) {}

    func didPresentSearchController(_ searchController: UISearchController) {
        DispatchQueue.main.async {
            if self.searchController.searchBar.canBecomeFirstResponder {
                self.searchController.searchBar.becomeFirstResponder()
            }
        }
    }

    func willDismissSearchController(_ searchController: UISearchController) {}

    func didDismissSearchController(_ searchController: UISearchController) {}
}

// MARK: - UISearchResultsUpdating

extension LocationResultsTableViewController: UISearchResultsUpdating {

    func updateSearchResults(for searchController: UISearchController) {
        guard let currentQuery = searchController.searchBar.text, currentQuery.isEmpty == false, currentQuery != searchQuery else {
            return
        }
        searchQuery = currentQuery

        resultsProvider.performSearch(query: searchQuery) { [resultSummaryLabel] resultSummary in
            let destinationAlpha: CGFloat
            if resultSummary != nil {
                destinationAlpha = 1
            } else {
                destinationAlpha = 0
            }

            UIView.animate(withDuration: Constants.summaryAnimationDuration) {
                resultSummaryLabel.text = resultSummary
                resultSummaryLabel.alpha = destinationAlpha
            }
        }
    }
}

// MARK: - Private behavior

private extension LocationResultsTableViewController {

    func setupView() {
        title = NSLocalizedString("Location", comment: "Title of Location search in/on Bottom Sheet")

        tableView.backgroundColor = .white

        let cancelItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelTapped))
        navigationItem.leftBarButtonItem = cancelItem

        let saveText = NSLocalizedString("Save", comment: "Save button.")
        let saveItem = UIBarButtonItem(title: saveText, style: .done, target: self, action: #selector(saveTapped))
        navigationItem.rightBarButtonItem = saveItem

        let barButtonItemColor = WPStyleGuide.wordPressBlue()

        let barButtonItems = [ navigationItem.leftBarButtonItem, navigationItem.rightBarButtonItem ].compactMap { $0 }

        for item in barButtonItems {
            item.tintColor = barButtonItemColor
            item.setTitleTextAttributes([.foregroundColor: barButtonItemColor], for: .normal)
        }

        configure(searchController: searchController)
        configure(tableView: tableView)
        configure(summaryLabel: resultSummaryLabel)
    }

    func configure(searchController: UISearchController) {
        if #available(iOS 11.0, *) {
            navigationItem.searchController = searchController
            navigationItem.hidesSearchBarWhenScrolling = false
        }
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = false

        searchController.delegate = self
        searchController.searchResultsUpdater = self

        configure(searchBar: searchController.searchBar)
    }

    func configure(searchBar: UISearchBar) {
        searchBar.delegate = self

        if let background = UIImage(named: "searchField") {
            searchBar.setSearchFieldBackgroundImage(background, for: .normal)
        }

        searchBar.placeholder = NSLocalizedString("Search", comment: "Location search placeholder text")

        searchBar.tintColor = WPStyleGuide.wordPressBlue()

        searchBar.searchTextPositionAdjustment = UIOffset(horizontal: Constants.searchBarTextPadding, vertical: 0)

        searchBar.autocapitalizationType = .words
        searchBar.autocorrectionType = .no
        searchBar.enablesReturnKeyAutomatically = true
        searchBar.returnKeyType = .search

        if let textField = searchBar.value(forKey: "searchField") as? UITextField {
            textField.textColor = WPStyleGuide.darkGrey()
            textField.font = UIFont.systemFont(ofSize: Constants.searchBarFontSize)
            textField.clearButtonMode = .never

            let searchColor = UIColor(red: 135/255.0, green: 166/255.0, blue: 188/255.0, alpha: 1.0)
            if let iconView = textField.leftView as? UIImageView {
                iconView.tintColor = searchColor
            }

            if let placeholderLabel = textField.value(forKey: "placeholderLabel") as? UILabel {
                placeholderLabel.textColor = searchColor
                placeholderLabel.font = UIFont.systemFont(ofSize: Constants.searchBarFontSize)
            }
        }

        searchBar.sizeToFit()
    }

    func configure(tableView: UITableView) {
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = Constants.defaultRowHeight

        tableView.separatorInset = UIEdgeInsets(top: 0, left: Constants.separatorInsetLeading, bottom: 0, right: 0)
        tableView.separatorColor = WPStyleGuide.grey()

        if #available(iOS 11.0, *) {} else {
            tableView.tableHeaderView = searchController.searchBar
        }
        tableView.tableFooterView = UIView(frame: .zero)

        resultsProvider.tableView = tableView
    }

    func configure(summaryLabel: UILabel) {
        view.addSubview(summaryLabel)

        NSLayoutConstraint.activate([
            summaryLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: Constants.summaryTopInset),
            summaryLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
    }

    func performDismissal() {
        presentingViewController?.dismiss(animated: true)
    }
}

// MARK: - Objective-C

@objc
extension LocationResultsTableViewController {
    func cancelTapped() {
        performDismissal()
    }

    func saveTapped() {
        performDismissal()
    }
}
