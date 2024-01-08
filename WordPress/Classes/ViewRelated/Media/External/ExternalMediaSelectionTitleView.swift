import UIKit

final class ExternalMediaSelectionTitleView: UIView {
    private let textLabel = UILabel()
    let buttonViewSelected = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)

        buttonViewSelected.titleLabel?.font = WPStyleGuide.fontForTextStyle(.headline)
        buttonViewSelected.tintColor = UIColor.primary

        textLabel.font = WPStyleGuide.fontForTextStyle(.headline)
        textLabel.textAlignment = .center

        addSubview(textLabel)
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        textLabel.text = Strings.toolbarSelectItems
        pinSubviewAtCenter(textLabel)

        addSubview(buttonViewSelected)
        buttonViewSelected.translatesAutoresizingMaskIntoConstraints = false
        pinSubviewToAllEdges(buttonViewSelected)

        // Make sure it fits when displayed in `UIToolbar`.
        buttonViewSelected.setTitle(String(format: Strings.toolbarViewSelected, String(999999)), for: [])
        buttonViewSelected.sizeToFit()

        setSelectionCount(0)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setSelectionCount(_ count: Int) {
        buttonViewSelected.isHidden = count == 0
        textLabel.isHidden = count != 0
        if count > 0 {
            UIView.performWithoutAnimation {
                buttonViewSelected.setTitle(String(format: Strings.toolbarViewSelected, String(count)), for: [])
                buttonViewSelected.layoutIfNeeded()
            }
        }
    }
}

private enum Strings {
    static let toolbarSelectItems = NSLocalizedString("externalMediaPicker.toolbarSelectItemsPrompt", value: "Select Images", comment: "Bottom toolbar title in the selection mode")
    static let toolbarViewSelected = NSLocalizedString("externalMediaPicker.toolbarViewSelected", value: "View Selected (%@)", comment: "Bottom toolbar title in the selection mode")
}
