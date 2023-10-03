import UIKit

final class SiteMediaSelectionTitleView: UIView {
    private let textLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(textLabel)
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        pinSubviewToAllEdges(textLabel)

        textLabel.font = WPStyleGuide.fontForTextStyle(.headline)
        textLabel.textAlignment = .center

        // Make sure it fits when displayed in `UIToolbar`.
        let textItems = String(format: Strings.toolbarSelectItemsPlural, 999999)
        let textImages = String(format: Strings.toolbarSelectImagesSingle, 999999)
        textLabel.text = textItems.count > textImages.count ? textItems : textImages
        textLabel.sizeToFit()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setSelection(_ selection: [Media]) {
        if selection.isEmpty {
            textLabel.text = Strings.toolbarSelectItems
        } else if selection.allSatisfy({ $0.mediaType == .image }) {
            textLabel.text = selection.count == 1 ? Strings.toolbarSelectImagesSingle : String(format: Strings.toolbarSelectImagesPlural, selection.count)
        } else {
            textLabel.text = selection.count == 1 ? Strings.toolbarSelectItemsSingle : String(format: Strings.toolbarSelectItemsPlural, selection.count)
        }
    }
}

private enum Strings {
    static let toolbarSelectItems = NSLocalizedString("mediaLibrary.toolbarSelectItemsPrompt", value: "Select Items", comment: "Bottom toolbar title in the selection mode")
    static let toolbarSelectItemsSingle = NSLocalizedString("mediaLibrary.toolbarSelectItemsOne", value: "1 Item Selected", comment: "Bottom toolbar title in the selection mode")
    static let toolbarSelectItemsPlural = NSLocalizedString("mediaLibrary.toolbarSelectItemsMany", value: "%d Items Selected", comment: "Bottom toolbar title in the selection mode")
    static let toolbarSelectImagesSingle = NSLocalizedString("mediaLibrary.toolbarSelectImagesOne", value: "1 Image Selected", comment: "Bottom toolbar title in the selection mode")
    static let toolbarSelectImagesPlural = NSLocalizedString("mediaLibrary.toolbarSelectImagesMany", value: "%d Images Selected", comment: "Bottom toolbar title in the selection mode")
}
