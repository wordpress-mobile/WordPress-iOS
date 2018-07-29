import UIKit
import WordPressAuthenticator

class RegisterDomainDetailsViewController: NUXTableViewController {

    private enum Constants {
        static let estimatedRowHeight: CGFloat = 62
    }

    private enum Section: Int {
        case privacyProtection = 0
        case contactInformation
        case address
    }

    private var tableHandler: ImmuTableViewHandler!
    var domain: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
    }

    static func instance() -> RegisterDomainDetailsViewController {
        let storyboard = UIStoryboard(name: "Domains", bundle: Bundle.main)
        let controller = storyboard.instantiateViewController(withIdentifier: "RegisterDomainDetailsViewController") as! RegisterDomainDetailsViewController
        return controller
    }

    private func configure() {
        configureTableView()
        configureNavigationBar()
        WPStyleGuide.configureColors(for: view, andTableView: tableView)
    }

    private func configureTableView() {
        tableView.estimatedRowHeight = Constants.estimatedRowHeight
        WPStyleGuide.configureColors(for: view, andTableView: tableView)
        tableView.register(
            UINib(nibName: RegisterDomainSectionHeaderView.identifier, bundle: nil),
            forHeaderFooterViewReuseIdentifier: RegisterDomainSectionHeaderView.identifier
        )
        tableView.register(
            UINib(nibName: EpilogueSectionHeaderFooter.identifier, bundle: nil),
            forHeaderFooterViewReuseIdentifier: EpilogueSectionHeaderFooter.identifier
        )

        ImmuTable.registerRows([EditableNameValueRow.self,
                                CheckmarkRow.self],
                               tableView: tableView)
        tableHandler = ImmuTableViewHandler(takeOver: self)
        // remove empty cells
        tableView.tableFooterView = UIView()

        tableView.estimatedSectionHeaderHeight = Constants.estimatedRowHeight
        tableView.sectionHeaderHeight = UITableViewAutomaticDimension

        tableView.estimatedSectionFooterHeight = Constants.estimatedRowHeight
        tableView.sectionFooterHeight = UITableViewAutomaticDimension

        reloadViewModel()
    }

    private func reloadViewModel() {
        tableHandler.viewModel = tableViewModel()
    }

    private func configureNavigationBar() {
        title = NSLocalizedString("Register domain",
                                  comment: "Title for the Register domain screen")
    }
}

// MARK: - Rows

extension RegisterDomainDetailsViewController {

    private func tableViewModel() -> ImmuTable {
        return ImmuTable(
            sections: [
                privacySection(),
                domainContactInformation()
            ]
        )
    }

    private func privacySection() -> ImmuTableSection {
        var rows = [ImmuTableRow]()

        rows.append(
            CheckmarkRow(
                title: Localized.PrivacySection.registerPrivatelyRowText,
                checked: true,
                action: { (row) in
                    //TODO
                }
            )
        )
        rows.append(
            CheckmarkRow(
                title: Localized.PrivacySection.registerPubliclyRowText,
                checked: false,
                action: { (row) in
                    //TODO
                }
            )
        )

        return ImmuTableSection(rows: rows)
    }

    private func domainContactInformation() -> ImmuTableSection {
        var rows = [ImmuTableRow]()

        for fieldName in Localized.ContactInformation.fields {
            rows.append(EditableNameValueRow(name: fieldName,
                                             value: nil,
                                             action: nil))
        }

        return ImmuTableSection(rows: rows)
    }
}

// MARK: - Section Header Footer

extension RegisterDomainDetailsViewController {

    open override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        guard let sectionType = Section(rawValue: section) else {
            return 0
        }
        switch sectionType {
        case .privacyProtection:
            return UITableViewAutomaticDimension
        default:
            break
        }
        return 0
    }

    open override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard let sectionType = Section(rawValue: section) else {
            return nil
        }
        switch sectionType {
        case .privacyProtection:
            return privacyProtectionSectionFooter()
        default:
            break
        }
        return nil
    }

    open override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let sectionType = Section(rawValue: section) else {
            return nil
        }
        switch sectionType {
        case .privacyProtection:
            return privacyProtectionSectionHeader()
        case .contactInformation:
            return ContactInformationSectionHeader()
        default:
            break
        }
        return nil
    }

    private func privacyProtectionSectionHeader() -> RegisterDomainSectionHeaderView? {
        return sectionHeader(title: Localized.PrivacySection.title,
                             description: Localized.PrivacySection.description)
    }

    private func ContactInformationSectionHeader() -> RegisterDomainSectionHeaderView? {
        return sectionHeader(title: Localized.ContactInformation.title,
                             description: Localized.ContactInformation.description)
    }

    private func sectionHeader(title: String, description: String) -> RegisterDomainSectionHeaderView? {
        guard let view = tableView.dequeueReusableHeaderFooterView(
            withIdentifier: RegisterDomainSectionHeaderView.identifier
            ) as? RegisterDomainSectionHeaderView else {
            return nil
        }
        view.setTitle(title)
        view.setDescription(description)
        return view
    }

    private func privacyProtectionSectionFooter() -> EpilogueSectionHeaderFooter? {
        guard let view = tableView.dequeueReusableHeaderFooterView(
            withIdentifier: EpilogueSectionHeaderFooter.identifier
            ) as? EpilogueSectionHeaderFooter else {
                return nil
        }
        view.titleLabel?.attributedText = termsAndConditionsFooterTitle
        view.titleLabel?.numberOfLines = 0
        view.titleLabel?.lineBreakMode = .byWordWrapping
        view.topConstraint.constant = 8
        view.contentView.backgroundColor = WPStyleGuide.greyLighten30()
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTermsAndConditionsTap(_:)))
        view.addGestureRecognizer(tap)
        return view
    }

    @objc func handleTermsAndConditionsTap(_ sender: UITapGestureRecognizer) {
        //TODO
    }

    private var termsAndConditionsFooterTitle: NSAttributedString {
        let bodyColor = WPStyleGuide.greyDarken20()
        let linkColor = WPStyleGuide.darkGrey()
        let font = UIFont.preferredFont(forTextStyle: .footnote)

        let attributes: StyledHTMLAttributes = [
            .BodyAttribute: [.font: font,
                             .foregroundColor: bodyColor],
            .ATagAttribute: [.underlineStyle: NSUnderlineStyle.styleSingle.rawValue,
                             .foregroundColor: linkColor]
        ]
        let attributedTerms = NSAttributedString.attributedStringWithHTML(
            Localized.PrivacySection.termsAndConditions,
            attributes: attributes
        )

        return attributedTerms
    }
}
