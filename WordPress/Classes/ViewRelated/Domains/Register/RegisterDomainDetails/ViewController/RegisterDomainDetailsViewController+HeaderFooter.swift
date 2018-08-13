import UIKit

extension RegisterDomainDetailsViewController {

    private enum Constant {
        static let privacyProtectionSectionTitleTopDistance: CGFloat = 8
    }

    func configureTableFooterView() {
        //Creating a UIView with a custom frame because table tableFooterView doesn't support autolayout
        let footer = UIView(frame: CGRect(x: 0,
                                          y: 0,
                                          width: view.frame.size.width,
                                          height: Constants.buttonContainerHeight))
        footerView.frame = footer.frame
        footer.addSubview(footerView)
        footer.pinSubviewToAllEdges(footerView)
        tableView.tableFooterView = footer
    }

    func privacyProtectionSectionHeader() -> RegisterDomainSectionHeaderView? {
        return sectionHeader(title: Localized.PrivacySection.title,
                             description: Localized.PrivacySection.description)
    }

    func contactInformationSectionHeader() -> RegisterDomainSectionHeaderView? {
        return sectionHeader(title: Localized.ContactInformation.title,
                             description: Localized.ContactInformation.description)
    }

    func sectionHeader(title: String, description: String) -> RegisterDomainSectionHeaderView? {
        guard let view = tableView.dequeueReusableHeaderFooterView(
            withIdentifier: RegisterDomainSectionHeaderView.identifier
            ) as? RegisterDomainSectionHeaderView else {
                return nil
        }
        view.setTitle(title)
        view.setDescription(description)
        return view
    }

    func privacyProtectionSectionFooter() -> EpilogueSectionHeaderFooter? {
        guard let view = tableView.dequeueReusableHeaderFooterView(
            withIdentifier: EpilogueSectionHeaderFooter.identifier
            ) as? EpilogueSectionHeaderFooter else {
                return nil
        }
        view.titleLabel?.attributedText = termsAndConditionsFooterTitle
        view.titleLabel?.numberOfLines = 0
        view.titleLabel?.lineBreakMode = .byWordWrapping
        view.topConstraint.constant = Constant.privacyProtectionSectionTitleTopDistance
        view.contentView.backgroundColor = WPStyleGuide.greyLighten30()
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTermsAndConditionsTap(_:)))
        view.addGestureRecognizer(tap)
        return view
    }

    func errorShowingSectionFooter(section: Int) -> RegisterDomainDetailsErrorSectionFooter? {
        let errors = viewModel.sections[section].validationErrors(forTag: .proceedSubmit)
        guard registerButtonTapped,
            let view = tableView.dequeueReusableHeaderFooterView(
                withIdentifier: RegisterDomainDetailsErrorSectionFooter.defaultReuseID
                ) as? RegisterDomainDetailsErrorSectionFooter else {
                    return nil
        }
        view.setErrorMessages(errors)
        return view
    }

    var termsAndConditionsFooterTitle: NSAttributedString {
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
