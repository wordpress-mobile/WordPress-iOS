import UIKit

// MARK: - WPTableViewCell Classes

class InstructionTableViewCell: WPTableViewCell {

    @IBOutlet weak var stepLabel: UILabel!
    @IBOutlet weak var instr1Label: UILabel!
    @IBOutlet weak var instr2Label: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        assert(stepLabel != nil)
        assert(instr1Label != nil)
        assert(instr2Label != nil)
    }
}

class SiteTypeTableViewCell: WPTableViewCell {

    @IBOutlet weak var typeImageView: UIImageView!
    @IBOutlet weak var startWithLabel: UILabel!
    @IBOutlet weak var typeDescrLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        assert(typeImageView != nil)
        assert(startWithLabel != nil)
        assert(typeDescrLabel != nil)
    }
}

// MARK: - ImmuTableRow Structs

struct InstructionRow: ImmuTableRow {
    typealias CellType = InstructionTableViewCell

    static let cell: ImmuTableCell = {
        let nib = UINib(nibName: "InstructionTableViewCell", bundle: Bundle(for: CellType.self))
        return ImmuTableCell.nib(nib, CellType.self)
    }()

    let step: String
    let instr1: String
    let instr2: String?
    let action: ImmuTableAction?

    func configureCell(_ cell: UITableViewCell) {

        guard let cell = cell as? CellType else {
            return
        }

        cell.backgroundColor = UIColor.clear
        cell.stepLabel.text = step
        cell.instr1Label.text = instr1
        cell.selectionStyle = .none

        cell.instr2Label.isHidden = true
        if let instr2 = instr2, !instr2.isEmpty {
            cell.instr2Label.isHidden = false
            cell.instr2Label.text = instr2
        }
    }
}

struct SiteTypeRow: ImmuTableRow {
    typealias CellType = SiteTypeTableViewCell

    static let cell: ImmuTableCell = {
        let nib = UINib(nibName: "SiteTypeTableViewCell", bundle: Bundle(for: CellType.self))
        return ImmuTableCell.nib(nib, CellType.self)
    }()

    let startWith: String
    let typeDescr: String
    let typeImage: UIImage?
    let action: ImmuTableAction?

    func configureCell(_ cell: UITableViewCell) {

        guard let cell = cell as? CellType else {
            return
        }

        cell.accessoryType = .disclosureIndicator
        cell.selectionStyle = .none
        cell.startWithLabel.text = startWith
        cell.typeDescrLabel.text = typeDescr

        if let typeImage = typeImage {
            cell.typeImageView.image = typeImage
        }
    }
}
