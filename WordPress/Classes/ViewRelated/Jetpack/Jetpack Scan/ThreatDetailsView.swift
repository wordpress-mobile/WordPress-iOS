import UIKit
import Gridicons
import WordPressUI

class ThreatDetailsView: UIView, NibLoadable {

    // General info
    @IBOutlet private weak var generalInfoStackView: UIStackView!
    @IBOutlet private weak var icon: UIImageView!
    @IBOutlet private weak var generalInfoTitleLabel: UILabel!
    @IBOutlet private weak var generalInfoDescriptionLabel: UILabel!

    // Problem
    @IBOutlet private weak var problemStackView: UIStackView!
    @IBOutlet private weak var problemTitleLabel: UILabel!
    @IBOutlet private weak var problemDescriptionLabel: UILabel!

    // Fix
    @IBOutlet private weak var fixStackView: UIStackView!
    @IBOutlet private weak var fixTitleLabel: UILabel!
    @IBOutlet private weak var fixDescriptionLabel: UILabel!

    // Technical details
    @IBOutlet private weak var technicalDetailsStackView: UIStackView!
    @IBOutlet private weak var technicalDetailsTitleLabel: UILabel!
    @IBOutlet private weak var technicalDetailsDescriptionLabel: UILabel!
    @IBOutlet private weak var technicalDetailsFileContainerView: UIView!
    @IBOutlet private weak var technicalDetailsFileLabel: UILabel!
    @IBOutlet private weak var technicalDetailsContextLabel: UILabel!

    // Buttons
    @IBOutlet private weak var buttonsStackView: UIStackView!
    @IBOutlet private weak var primaryActionButton: FancyButton!
    @IBOutlet private weak var secondaryActionButton: FancyButton!

    // MARK: - Init

    override func awakeFromNib() {
        super.awakeFromNib()
        applyStyles()
    }

    // MARK: - Styling

    private func applyStyles() {
        backgroundColor = .basicBackground
        styleGeneralInfoSection()
        styleProblemSection()
        styleFixSection()
        styleTechnicalDetailsSection()
        styleButtons()
    }

    private func styleGeneralInfoSection() {
        generalInfoTitleLabel.font = WPStyleGuide.fontForTextStyle(.title3, fontWeight: .semibold)
        generalInfoTitleLabel.textColor = .error
        generalInfoTitleLabel.numberOfLines = 0

        generalInfoDescriptionLabel.font = WPStyleGuide.fontForTextStyle(.body)
        generalInfoDescriptionLabel.textColor = .text
        generalInfoDescriptionLabel.numberOfLines = 0
    }

    private func styleProblemSection() {
        problemTitleLabel.font = WPStyleGuide.fontForTextStyle(.title3, fontWeight: .semibold)
        problemTitleLabel.textColor = .text
        problemTitleLabel.numberOfLines = 0

        problemDescriptionLabel.font = WPStyleGuide.fontForTextStyle(.body)
        problemDescriptionLabel.textColor = .text
        problemDescriptionLabel.numberOfLines = 0
    }

    private func styleFixSection() {
        fixTitleLabel.font = WPStyleGuide.fontForTextStyle(.title3, fontWeight: .semibold)
        fixTitleLabel.textColor = .text
        fixTitleLabel.numberOfLines = 0

        fixDescriptionLabel.font = WPStyleGuide.fontForTextStyle(.body)
        fixDescriptionLabel.textColor = .text
        fixDescriptionLabel.numberOfLines = 0
    }

    private func styleTechnicalDetailsSection() {
        technicalDetailsTitleLabel.font = WPStyleGuide.fontForTextStyle(.title3, fontWeight: .semibold)
        technicalDetailsTitleLabel.textColor = .text
        technicalDetailsTitleLabel.numberOfLines = 0

        technicalDetailsFileContainerView.backgroundColor = .listBackground

        technicalDetailsFileLabel.font = WPStyleGuide.fontForTextStyle(.footnote)
        technicalDetailsFileLabel.textColor = .text

        technicalDetailsDescriptionLabel.font = WPStyleGuide.fontForTextStyle(.body)
        technicalDetailsDescriptionLabel.textColor = .text
        technicalDetailsDescriptionLabel.numberOfLines = 0
    }

    private func styleButtons() {
        primaryActionButton.isPrimary = true

        secondaryActionButton.isPrimary = false
    }

    // MARK: - Configure

    func configure(with viewModel: JetpackScanThreatViewModel) {
        icon.image = viewModel.detailIconImage
        icon.tintColor = viewModel.detailIconImageColor
        generalInfoTitleLabel.text = viewModel.title
        generalInfoDescriptionLabel.text = viewModel.description
        problemTitleLabel.text = viewModel.problemTitle
        problemDescriptionLabel.text = viewModel.problemDescription
        fixTitleLabel.text = viewModel.fixTitle
        fixDescriptionLabel.text = viewModel.fixDescription
        technicalDetailsTitleLabel.text = viewModel.technicalDetailsTitle
        technicalDetailsDescriptionLabel.text = viewModel.technicalDetailsDescription
        technicalDetailsFileLabel.text = viewModel.fileName
        technicalDetailsContextLabel.text = "" // FIXME
        primaryActionButton.setTitle(viewModel.primaryButtonTitle, for: .normal)
        secondaryActionButton.setTitle(viewModel.secondaryButtonTitle, for: .normal)
    }

    // MARK: - IBActions

    @IBAction private func primaryActionButtonTapped(_ sender: Any) {
    }

    @IBAction private func secondaryActionButtonTapped(_ sender: Any) {
    }
}
