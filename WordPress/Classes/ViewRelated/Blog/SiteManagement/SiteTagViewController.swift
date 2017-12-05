import UIKit

final class SiteTagViewController: UITableViewController {
    private let blog: Blog
    private let tag: PostTag

    private let cellIdentifier = "TagEditorCell"

    fileprivate enum Sections: Int, CustomStringConvertible {
        case name
        case description
        case sectionCount

        static var count: Int {
            return sectionCount.rawValue
        }

        static func section(for index: Int) -> Sections {
            guard index < sectionCount.rawValue else {
                return .name
            }
            return Sections(rawValue: index)!
        }

        var description: String {
            switch self {
            case .name:
                return NSLocalizedString("Tag", comment: "Section header for tag name in Tag Details View.").uppercased()
            case .description:
                return NSLocalizedString("Description", comment: "Section header for tag name in Tag Details View.").uppercased()
            case .sectionCount:
                return ""
            }
        }
    }

    private lazy var textFieldCell: WPTableViewCell = {
        let returnValue = WPTableViewCell(style: .default, reuseIdentifier: nil)
        returnValue.selectionStyle = .none
        returnValue.contentView.addSubview(self.textField)

        let readableGuide = returnValue.contentView.readableContentGuide
        NSLayoutConstraint.activate([
            self.textField.leadingAnchor.constraint(equalTo: readableGuide.leadingAnchor),
            self.textField.trailingAnchor.constraint(equalTo: readableGuide.trailingAnchor),
            self.textField.topAnchor.constraint(equalTo: readableGuide.topAnchor),
            self.textField.bottomAnchor.constraint(equalTo: readableGuide.bottomAnchor)
            ])

        return returnValue
    }()

    private lazy var textField: UITextField = {
        let returnValue = UITextField(frame: .zero)
        returnValue.translatesAutoresizingMaskIntoConstraints = false
        returnValue.clearButtonMode = .always
        returnValue.font = WPStyleGuide.tableviewTextFont()
        returnValue.textColor = WPStyleGuide.darkGrey()
        //returnValue.text = self.tag.name
        returnValue.returnKeyType = .done
        returnValue.keyboardType = .default
        returnValue.delegate = self
        //returnValue.autocorrectionType =

        return returnValue
    }()

    public init(blog: Blog, tag: PostTag) {
        self.blog = blog
        self.tag = tag
        super.init(style: .grouped)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        configureTitle(text: tag.name)
        configureTable()
    }

    private func configureTitle(text: String?) {
        navigationItem.title = text
    }

    private func configureTable() {
        WPStyleGuide.configureColors(for: view, andTableView: tableView)
        tableView.tableFooterView = UIView(frame: .zero)
    }

}

// MARK: - Table view datasource
extension SiteTagViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return Sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return Sections.section(for: section).description
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let sectionForIndexPath = Sections.section(for: indexPath.row)

        switch sectionForIndexPath {
        case .name:
            let cell = textFieldCell
            return textFieldCell
        case .description:
            let cell = textFieldCell
            return textFieldCell
        case .sectionCount:
            return UITableViewCell()
        }
    }
}

extension SiteTagViewController: UITextFieldDelegate {

}
