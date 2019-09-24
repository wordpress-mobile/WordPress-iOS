import UIKit
import WordPressAuthenticator
import WordPressEditor

class RegisterDomainDetailsViewController: NUXTableViewController {

    typealias Localized = RegisterDomainDetails.Localized
    typealias SectionIndex = RegisterDomainDetailsViewModel.SectionIndex
    typealias EditableKeyValueRow = RegisterDomainDetailsViewModel.Row.EditableKeyValueRow
    typealias CheckMarkRow = RegisterDomainDetailsViewModel.Row.CheckMarkRow
    typealias Context = RegisterDomainDetailsViewModel.ValidationRule.Context
    typealias CellIndex = RegisterDomainDetailsViewModel.CellIndex

    enum Constants {
        static let estimatedRowHeight: CGFloat = 62
        static let buttonContainerHeight: CGFloat = 84
    }

    var viewModel: RegisterDomainDetailsViewModel!

    private var selectedItemIndex: [IndexPath: Int] = [:]

    private(set) lazy var footerView: RegisterDomainDetailsFooterView = {
        let buttonView = RegisterDomainDetailsFooterView.loadFromNib()

        buttonView.submitButton.isEnabled = false
        buttonView.submitButton.addTarget(
            self,
            action: #selector(registerDomainButtonTapped(sender:)),
            for: .touchUpInside
        )

        buttonView.submitButton.setTitle(Localized.buttonTitle, for: .normal)

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
        configureView()
    }


    private func configureView() {
        title = NSLocalizedString("Register domain",
                                  comment: "Title for the Register domain screen")

        configureTableView()
        WPStyleGuide.configureColors(view: view, tableView: tableView)

        viewModel.onChange = { [weak self] (change) in
            self?.handle(change: change)
        }

        viewModel.prefill()

        changeBottomSafeAreaInset()
        setupEditingEndingTapGestureRecognizer()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        configureTableFooterView(width: size.width)

    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        changeBottomSafeAreaInset()
    }

    private func changeBottomSafeAreaInset() {
        // Footer in this case is the submit button. We want the background to extend under the home indicator.
        let safeAreaInsets = tableView.safeAreaInsets.bottom

        var newInsets = tableView.contentInset
        newInsets.bottom = -safeAreaInsets
        tableView.contentInset = newInsets
    }

    private func configureTableView() {
        configureTableFooterView()

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

        tableView.estimatedRowHeight = Constants.estimatedRowHeight

        tableView.estimatedSectionHeaderHeight = Constants.estimatedRowHeight
        tableView.sectionHeaderHeight = UITableView.automaticDimension

        tableView.estimatedSectionFooterHeight = Constants.estimatedRowHeight
        tableView.sectionFooterHeight = UITableView.automaticDimension

        tableView.cellLayoutMarginsFollowReadableWidth = false

        tableView.reloadData()
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
        present(alertController, animated: true, completion: nil)
    }

    /// Sets up a gesture recognizer to make tap gesture close the keyboard
    private func setupEditingEndingTapGestureRecognizer() {
        let gestureRecognizer = UITapGestureRecognizer()
        gestureRecognizer.cancelsTouchesInView = false

        gestureRecognizer.on { [weak self] (gesture) in
            self?.view.endEditing(true)
        }

        view.addGestureRecognizer(gestureRecognizer)
    }

    private func handle(change: RegisterDomainDetailsViewModel.Change) {
        switch change {
        case let .formValidated(context, isValid):
            switch context {
            case .clientSide:
                footerView.submitButton.isEnabled = isValid
            default:
                break
            }
            break
        case .addNewAddressLineEnabled(let indexPath):
            tableView.insertRows(at: [indexPath], with: .none)
        case .addNewAddressLineReplaced(let indexPath):
            tableView.reloadRows(at: [indexPath], with: .none)
        case .checkMarkRowsUpdated:
            tableView.reloadData()
        case .registerSucceeded(let domain):
            dismiss(animated: true) { [weak self] in
                self?.viewModel.domainPurchasedCallback(domain)
            }
        case .unexpectedError(let message):
            showAlert(message: message)
        case .loading(let isLoading):
            if isLoading {
                footerView.submitButton.isEnabled = false
                SVProgressHUD.setDefaultMaskType(.clear)
                SVProgressHUD.show()
            } else {
                footerView.submitButton.isEnabled = true
                SVProgressHUD.dismiss()
            }
        case .prefillSuccess:
            tableView.reloadData()
        case .prefillError(let message):
            showAlert(message: message)
        case .multipleChoiceRowValueChanged(let indexPath):
            tableView.reloadRows(at: [indexPath], with: .none)
        case .remoteValidationFinished:
            tableView.reloadData()
        default:
            break
        }
    }

}

// MARK: - Actions

extension RegisterDomainDetailsViewController {

    @objc private func registerDomainButtonTapped(sender: UIButton) {
        viewModel.register()
    }

    @objc func handleTermsAndConditionsTap(_ sender: UITapGestureRecognizer) {
        UIApplication.shared.open(URL(string: WPAutomatticTermsOfServiceURL)!, options: [:], completionHandler: nil)
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

        if sectionType == .address,
            viewModel.addressSectionIndexHelper.addressField(for: indexPath.row) == .addressLine,
            indexPath.row == viewModel.addressSectionIndexHelper.extraAddressLineCount,
            valueTextField.text?.isEmpty == false {
                viewModel.enableAddAddressRow()
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
                if viewModel.countryNames.count > 0 {
                    showItemSelectionPage(onSelectionAt: indexPath,
                                          title: Localized.ContactInformation.country,
                                          items: viewModel.countryNames)
                }
            default:
                break
            }
        case .address:
            let addressField = viewModel.addressSectionIndexHelper.addressField(for: indexPath.row)
            switch addressField {
            case .addNewAddressLine:
                viewModel.replaceAddNewAddressLine()
            case .state:
                if viewModel.stateNames.count > 0 {
                    showItemSelectionPage(onSelectionAt: indexPath,
                                          title: Localized.Address.state,
                                          items: viewModel.stateNames)
                }
            default:
                break
            }
        case .phone:
            break
        }
    }

    private func showItemSelectionPage(onSelectionAt indexPath: IndexPath, title: String, items: [String]) {
        var options: [OptionsTableViewOption] = []
        for item in items {
            let attributedItem = NSAttributedString.init(
                string: item,
                attributes: [.font: WPStyleGuide.tableviewTextFont(),
                             .foregroundColor: UIColor.text]
            )
            let option = OptionsTableViewOption(
                image: nil,
                title: attributedItem,
                accessibilityLabel: nil)
            options.append(option)
        }
        let viewController = OptionsTableViewController(options: options)
        viewController.cellBackgroundColor = .listForeground
        if let selectedIndex = selectedItemIndex[indexPath] {
            viewController.selectRow(at: selectedIndex)
        }
        viewController.title = title
        viewController.onSelect = { [weak self] (index) in
            self?.navigationController?.popViewController(animated: true)
            self?.selectedItemIndex[indexPath] = index
            if let section = SectionIndex(rawValue: indexPath.section) {
                switch section {
                case .address:
                    self?.viewModel.selectState(at: index)
                case .contactInformation:
                    self?.viewModel.selectCountry(at: index)
                default:
                    break
                }
            }
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
        case .phone:
            return Localized.PhoneNumber.headerTitle
        default:
            break
        }
        return nil
    }
}
