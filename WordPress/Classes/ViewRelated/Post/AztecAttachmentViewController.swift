import Foundation
import UIKit
import WordPressShared
import Aztec

class AztecAttachmentViewController: UITableViewController {

    fileprivate var handler: ImmuTableViewHandler!
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
            value: alignTitles[.none]!,
            action: displayAlignmentSelector)

        let sizeRow = EditableTextRow(
            title: NSLocalizedString("Size", comment: "Image size option title."),
            value: sizeTitles[.full]!,
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

    }

    func displaySizeSelector(row: ImmuTableRow) {

    }

    // MARK: - Helper methods

    func handleCancelButtonTapped(sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }

    func handleDoneButtonTapped(sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }

    fileprivate let alignTitles: [TextAttachment.Alignment: String] = [
        .left: NSLocalizedString("Left", comment: "Left alignment for an image. Should be the same as in core WP."),
        .center: NSLocalizedString("Center", comment: "Center alignment for an image. Should be the same as in core WP."),
        .right: NSLocalizedString("Right", comment: "Right alignment for an image. Should be the same as in core WP."),
        .none: NSLocalizedString("None", comment: "No alignment for an image (default). Should be the same as in core WP.")
    ]

    fileprivate let sizeTitles: [TextAttachment.Size: String] = [
        .thumbnail: NSLocalizedString("Thumbnail", comment: "Thumbnail image size. Should be the same as in core WP."),
        .medium: NSLocalizedString("Medium", comment: "Medium image size. Should be the same as in core WP."),
        .large: NSLocalizedString("Large", comment: "Large image size. Should be the same as in core WP."),
        .full: NSLocalizedString("Full Size", comment: "Full size image. (default). Should be the same as in core WP.")
    ]
}
