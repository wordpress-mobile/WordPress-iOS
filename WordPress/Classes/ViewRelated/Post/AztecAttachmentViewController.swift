import Foundation
import UIKit
import WordPressShared
import Aztec

protocol AztecAttachmentViewControllerDelegate: class {

    func aztecAttachmentViewController(_ viewController: AztecAttachmentViewController, changedAttachment: TextAttachment)

}

class AztecAttachmentViewController: UITableViewController {

    var attachment: TextAttachment? {
        didSet {
            if let attachment = attachment {
                alignment = attachment.alignment
                size = attachment.size
            }
        }
    }

    var alignment = TextAttachment.Alignment.none
    var size = TextAttachment.Size.full

    fileprivate var handler: ImmuTableViewHandler!

    weak var delegate: AztecAttachmentViewControllerDelegate?

    // MARK: - Initialization

    override init(style: UITableViewStyle) {
        super.init(style: style)
        navigationItem.title = NSLocalizedString("Media Settings", comment: "Media Settings Title")
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    required convenience init() {
        self.init(style: .grouped)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        ImmuTable.registerRows([
            EditableTextRow.self,
            ], tableView: self.tableView)

        handler = ImmuTableViewHandler(takeOver: self)
        handler.viewModel = tableViewModel()

        WPStyleGuide.configureColors(for: view, andTableView: tableView)

        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target:self, action: #selector(AztecAttachmentViewController.handleCancelButtonTapped))
        navigationItem.leftBarButtonItem = cancelButton

        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target:self, action: #selector(AztecAttachmentViewController.handleDoneButtonTapped))
        navigationItem.rightBarButtonItem = doneButton
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.handler.viewModel = self.tableViewModel()
    }

    // MARK: - Model mapping

    func tableViewModel() -> ImmuTable {
        let displaySettingsHeader = NSLocalizedString("Web Display Settings", comment: "The title of the option group for editing an image's size, alignment, etc. on the image details screen.")

        let alignmentRow = EditableTextRow(
            title: NSLocalizedString("Alignment", comment: "Image alignment option title."),
            value: alignTitles[alignment]!,
            action: displayAlignmentSelector)

        let sizeRow = EditableTextRow(
            title: NSLocalizedString("Size", comment: "Image size option title."),
            value: sizeTitles[size]!,
            action: displaySizeSelector)

        return ImmuTable(sections: [
            ImmuTableSection(
                headerText: displaySettingsHeader,
                rows: [
                    alignmentRow,
                    sizeRow,
                ],
                footerText: nil)
            ])
    }


    // MARK: - Actions

    func displayAlignmentSelector(row: ImmuTableRow) {

        let values = alignTitles.map { (key: TextAttachment.Alignment, value: String) -> TextAttachment.Alignment in
            return key
        }

        let titles = values.map { (value: TextAttachment.Alignment) -> String in
            return alignTitles[value]!
        }

        let currentValue = alignment

        let dict: [String: Any] = [
            "DefaultValue": alignment,
            "Title": NSLocalizedString("Alignment", comment:"Title of the screen for choosing an image's alignment."),
            "Titles": titles,
            "Values": values,
            "CurrentValue": currentValue
        ]

        guard let vc = SettingsSelectionViewController(dictionary: dict) else {
            return
        }

        vc.onItemSelected = { (status: Any) in
            if let newAlignment = status as? TextAttachment.Alignment {
                self.alignment = newAlignment
            }
            vc.dismiss()
            self.tableView.reloadData()
        }

        self.navigationController?.pushViewController(vc, animated: true)
    }

    func displaySizeSelector(row: ImmuTableRow) {
        let values = sizeTitles.map { (key: TextAttachment.Size, value: String) -> TextAttachment.Size in
            return key
        }

        let titles = values.map { (value: TextAttachment.Size) -> String in
            return sizeTitles[value]!
        }

        let currentValue = size

        let dict: [String: Any] = [
            "DefaultValue": size,
            "Title": NSLocalizedString("Image Size", comment: "Title of the screen for choosing an image's size."),
            "Titles": titles,
            "Values": values,
            "CurrentValue": currentValue
        ]

        guard let vc = SettingsSelectionViewController(dictionary: dict) else {
            return
        }
        vc.onItemSelected = { (status: Any) in
            // do interesting work here... like updating the value of image meta.
            if let newSize = status as? TextAttachment.Size {
                self.size = newSize
            }
            vc.dismiss()
            self.tableView.reloadData()
        }

        self.navigationController?.pushViewController(vc, animated: true)
    }

    // MARK: - Helper methods

    func handleCancelButtonTapped(sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }

    func handleDoneButtonTapped(sender: UIBarButtonItem) {
        if let attachment = self.attachment {
            attachment.alignment = alignment
            attachment.size = size
            delegate?.aztecAttachmentViewController(self, changedAttachment: attachment)
        }
        dismiss(animated: true, completion: nil)
    }

    private let alignTitles: [TextAttachment.Alignment: String] = [
        .left: NSLocalizedString("Left", comment: "Left alignment for an image. Should be the same as in core WP."),
        .center: NSLocalizedString("Center", comment: "Center alignment for an image. Should be the same as in core WP."),
        .right: NSLocalizedString("Right", comment: "Right alignment for an image. Should be the same as in core WP."),
        .none: NSLocalizedString("None", comment: "No alignment for an image (default). Should be the same as in core WP.")
    ]

    private let sizeTitles: [TextAttachment.Size: String] = [
        .thumbnail: NSLocalizedString("Thumbnail", comment: "Thumbnail image size. Should be the same as in core WP."),
        .medium: NSLocalizedString("Medium", comment: "Medium image size. Should be the same as in core WP."),
        .large: NSLocalizedString("Large", comment: "Large image size. Should be the same as in core WP."),
        .full: NSLocalizedString("Full Size", comment: "Full size image. (default). Should be the same as in core WP.")
    ]
}
