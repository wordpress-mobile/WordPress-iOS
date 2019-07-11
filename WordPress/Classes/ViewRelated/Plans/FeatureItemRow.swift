import UIKit
import WordPressShared

struct FeatureItemRow: ImmuTableRow {
    static let cell = ImmuTableCell.class(FeatureItemCell.self)

    let title: String
    let description: String
    let iconURL: URL?
    let action: ImmuTableAction? = nil

    func configureCell(_ cell: UITableViewCell) {
        guard let cell = cell as? FeatureItemCell else { return }

        cell.featureTitleLabel?.text = title

        if let featureDescriptionLabel = cell.featureDescriptionLabel {
            cell.featureDescriptionLabel?.attributedText = attributedDescriptionText(description, font: featureDescriptionLabel.font)
        }

        cell.featureTitleLabel.textColor = .neutral(shade: .shade70)
        cell.featureDescriptionLabel.textColor = .neutral(shade: .shade30)
        WPStyleGuide.configureTableViewCell(cell)
    }

    fileprivate func attributedDescriptionText(_ text: String, font: UIFont) -> NSAttributedString {
        let lineHeight: CGFloat = 18

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.maximumLineHeight = lineHeight
        paragraphStyle.minimumLineHeight = lineHeight

        let attributedText = NSMutableAttributedString(string: text, attributes: [.paragraphStyle: paragraphStyle, .font: font])
        return attributedText
    }
}
