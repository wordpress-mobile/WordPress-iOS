import UIKit
import WordPressAuthenticator

class RegisterDomainDetailsViewController: NUXTableViewController {

    typealias Localized = RegisterDomainDetails.Localized
    typealias SectionIndex = RegisterDomainDetailsViewModel.SectionIndex
    typealias EditableKeyValueRow = RegisterDomainDetailsViewModel.Row.EditableKeyValueRow
    typealias CheckMarkRow = RegisterDomainDetailsViewModel.Row.CheckMarkRow
    typealias Tag = RegisterDomainDetailsViewModel.ValidationRuleTag
    typealias CellIndex = RegisterDomainDetailsViewModel.CellIndex

    enum Constants {
        static let estimatedRowHeight: CGFloat = 62
        static let buttonContainerHeight: CGFloat = 84
    }

    var viewModel: RegisterDomainDetailsViewModel!
    private var selectedItemIndex: [IndexPath: Int] = [:]
    private(set) var registerButtonTapped = false
    private(set) lazy var footerView: RegisterDomainDetailsFooterView = {
        let buttonView = RegisterDomainDetailsFooterView.loadFromNib()
        buttonView.nuxButton.isEnabled = false
        buttonView.nuxButton.addTarget(
            self,
            action: #selector(registerDomainButtonTapped(sender:)),
            for: .touchUpInside
        )
        buttonView.nuxButton.setTitle(Localized.buttonTitle, for: .normal)
        return buttonView
    }()

    init() {
        super.init(style: .grouped)
    }

    //Overriding this to be able to implement the empty init() otherwise compile error occurs
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
    }

    private func configure() {
        configureTableView()
        configureNavigationBar()
        WPStyleGuide.configureColors(for: view, andTableView: tableView)
        viewModel.onChange = { [unowned self] (change) in
            self.handle(change: change)
        }
        viewModel.prefill()
        setupEditingEndingTapGestureRecognizer()
    }

    private func configureTableView() {
        tableView.estimatedRowHeight = Constants.estimatedRowHeight
        configureTableFooterView()
        WPStyleGuide.configureColors(for: view, andTableView: tableView)
        tableView.register(
            UINib(nibName: RegisterDomainSectionHeaderView.identifier, bundle: nil),
            forHeaderFooterViewReuseIdentifier: RegisterDomainSectionHeaderView.identifier
        )
        tableView.register(
            UINib(nibName: EpilogueSectionHeaderFooter.identifier, bundle: nil),
            forHeaderFooterViewReuseIdentifier: EpilogueSectionHeaderFooter.identifier
        )
        tableView.register(
            RegisterDomainDetailsErrorSectionFooter.defaultNib,
            forHeaderFooterViewReuseIdentifier: RegisterDomainDetailsErrorSectionFooter.defaultReuseID
        )
        tableView.register(
            InlineEditableNameValueCell.defaultNib,
            forCellReuseIdentifier: InlineEditableNameValueCell.defaultReuseID
        )
        tableView.register(
            WPTableViewCellDefault.self,
            forCellReuseIdentifier: WPTableViewCellDefault.defaultReuseID
        )

        tableView.estimatedSectionHeaderHeight = Constants.estimatedRowHeight
        tableView.sectionHeaderHeight = UITableViewAutomaticDimension

        tableView.estimatedSectionFooterHeight = Constants.estimatedRowHeight
        tableView.sectionFooterHeight = UITableViewAutomaticDimension

        reloadViewModel()
    }

    private func handle(change: RegisterDomainDetailsViewModel.Change) {
        switch change {
        case let .wholeValidation(tag, isValid):
            switch tag {
            case .enableSubmit:
                footerView.nuxButton.isEnabled = isValid
            default:
                break
            }
            break
        case .registerFailedBecauseOfValidation:
            reloadDataSections()
        case .addNewAddressLineEnabled(let indexPath):
            tableView.insertRows(at: [indexPath], with: .none)
        case .addNewAddressLineReplaced(let indexPath):
            tableView.reloadRows(at: [indexPath], with: .none)
        case .checkMarkRowsUpdated(let sectionIndex):
            let indexes: IndexSet = [sectionIndex]
            tableView.reloadSections(indexes, with: .none)
        case .registerSucceeded(let items):
            //TODO: temporarily show as an alert
            showAlert(title: "Success", message: items.description)
        case .unexpectedError(let message):
            showAlert(message: message)
        case .loading(let isLoading):
            if isLoading {
                SVProgressHUD.show()
            } else {
                SVProgressHUD.dismiss()
            }
        case .prefillSuccess:
            reloadDataSections()
        case .prefillError(let message):
            showAlert(message: message)
        default:
            break
        }
    }

    private func reloadViewModel() {
        tableView.reloadData()
    }

    private func configureNavigationBar() {
        title = NSLocalizedString("Register domain",
                                  comment: "Title for the Register domain screen")
    }

    private func reloadDataSections() {
        let indexes: IndexSet = [SectionIndex.contactInformation.rawValue,
                                 SectionIndex.address.rawValue]
        tableView.reloadSections(indexes, with: .none)
    }

    private func showAlert(title: String? = nil, message: String) {
        let alertCancel = NSLocalizedString(
            "OK",
            comment: "Title of an OK button. Pressing the button acknowledges and dismisses a prompt."
        )
        let alertController = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        alertController.addCancelActionWithTitle(alertCancel, handler: nil)
        alertController.presentFromRootViewController()
        present(alertController, animated: true, completion: nil)
    }
}

// MARK: - Actions

extension RegisterDomainDetailsViewController {

    @objc private func registerDomainButtonTapped(sender: UIButton) {
        registerButtonTapped = true
        viewModel.register()
    }

    @objc func handleTermsAndConditionsTap(_ sender: UITapGestureRecognizer) {
        //TODO
    }

}

// MARK: - InlineEditableNameValueCellDelegate

extension RegisterDomainDetailsViewController: InlineEditableNameValueCellDelegate {

    func inlineEditableNameValueCell(_ cell: InlineEditableNameValueCell,
                                     valueTextFieldDidChange valueTextField: UITextField) {
        guard let indexPath = tableView.indexPath(for: cell),
            let sectionType = SectionIndex(rawValue: indexPath.section) else {
                return
        }
        viewModel.updateValue(valueTextField.text, at: indexPath)

        switch sectionType {
        case .address:
            let addressField = viewModel.addressSectionIndexHelper.addressField(for: indexPath.row)
            switch addressField {
            case .addressLine:
                if !(valueTextField.text?.isEmpty ?? true) && indexPath.row == viewModel.addressSectionIndexHelper.extraAddressLineCount {
                    viewModel.enableAddAddressRow()
                }
            default:
                break
            }
        default:
            break
        }
    }

    func inlineEditableNameValueCell(_ cell: InlineEditableNameValueCell,
                                     valueTextFieldEditingDidEnd valueTextField: UITextField) {
        guard let indexPath = tableView.indexPath(for: cell) else {
            return
        }
        if viewModel.sections[indexPath.section].isValid(forTag: .proceedSubmit) {
            tableView.reloadSections(IndexSet(integer: indexPath.section), with: .none)
        }
    }
}

// MARK: - UITableViewDelegate

extension RegisterDomainDetailsViewController {

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let sectionType = SectionIndex(rawValue: indexPath.section) else {
            return
        }
        switch sectionType {
        case .privacyProtection:
            viewModel.updateValue(true, at: indexPath)
        case .contactInformation:
            guard let field = CellIndex.ContactInformation(rawValue: indexPath.row) else {
                return
            }
            switch field {
            case .country:
                //TODO: fix mock data
                showItemSelectionPage(onSelectionAt: indexPath,
                                      title: Localized.ContactInformation.country,
                                      items: ["Country 1",
                                              "Country 2",
                                              "Country 3"])
            default:
                break
            }
        case .address:
            let addressField = viewModel.addressSectionIndexHelper.addressField(for: indexPath.row)
            switch addressField {
            case .addNewAddressLine:
                viewModel.replaceAddNewAddressLine()
            case .state:
                //TODO: fix mock data
                showItemSelectionPage(onSelectionAt: indexPath,
                                      title: Localized.Address.state,
                                      items: ["State 1",
                                              "State 2",
                                              "State 3"])
            default:
                break
            }
        }
    }

    private func showItemSelectionPage(onSelectionAt indexPath: IndexPath, title: String, items: [String]) {
        var options: [OptionsTableViewOption] = []
        for item in items {
            let attributedItem = NSAttributedString.init(
                string: item,
                attributes: [.font: WPStyleGuide.tableviewTextFont(),
                             .foregroundColor: WPStyleGuide.darkGrey()]
            )
            let option = OptionsTableViewOption(
                image: nil,
                title: attributedItem,
                accessibilityLabel: nil)
            options.append(option)
        }
        let viewController = OptionsTableViewController(options: options)
        if let selectedIndex = selectedItemIndex[indexPath] {
            viewController.selectRow(at: selectedIndex)
        }
        viewController.title = title
        viewController.onSelect = { [weak self] (index) in
            self?.navigationController?.popViewController(animated: true)
            self?.selectedItemIndex[indexPath] = index
            self?.viewModel.updateValue(items[index], at: indexPath)
            self?.tableView.reloadRows(at: [indexPath], with: .none)
        }
        navigationController?.pushViewController(viewController, animated: true)
    }
}

// MARK: - UITableViewDatasource

extension RegisterDomainDetailsViewController {

    override func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.sections[section].rows.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let rowType = viewModel.sections[indexPath.section].rows[indexPath.row]

        switch rowType {
        case .checkMark(let checkMarkRow):
            return checkMarkCell(with: checkMarkRow)
        case .inlineEditable(let editableRow):
            return editableKeyValueCell(with: editableRow, indexPath: indexPath)
        case .addAddressLine(let title):
            return addAdddressLineCell(with: title)
        }
    }

    // MARK: Section Header Footer

    open override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard let sectionType = SectionIndex(rawValue: section) else {
            return nil
        }
        switch sectionType {
        case .privacyProtection:
            return privacyProtectionSectionFooter()
        default:
            return errorShowingSectionFooter(section: section)
        }
    }

    open override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let sectionType = SectionIndex(rawValue: section) else {
            return nil
        }
        switch sectionType {
        case .privacyProtection:
            return privacyProtectionSectionHeader()
        case .contactInformation:
            return contactInformationSectionHeader()
        default:
            break
        }
        return nil
    }

    open override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let sectionType = SectionIndex(rawValue: section) else {
            return nil
        }
        switch sectionType {
        case .address:
            return Localized.Address.headerTitle
        default:
            break
        }
        return nil
    }
}
