import UIKit

final class SiteTagViewController: UITableViewController {
    private let blog: Blog
    private let tag: PostTag

    private let cellIdentifier = "TagEditorCell"

    fileprivate enum Sections: Int, CustomStringConvertible {
        case name
        case description

        static let count: Int = {
            var returnValue: Int = 0
            while let _ = Sections(rawValue: returnValue) {
                returnValue = returnValue + 1
            }
            return returnValue
        }()

        static func section(for index: Int) -> Sections {
            guard index < count else {
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
            }
        }

        var height: CGFloat {
            switch self {
            case .name:
                return 44.0
            case .description:
                return 132.0
            }
        }
    }

    private lazy var nameCell: WPTableViewCell = {
        return self.cell(content: self.nameTextField)
    }()

    private lazy var descriptionCell: WPTableViewCell = {
        return self.cell(content: self.descriptionTextField)
    }()

    private lazy var nameTextField: UITextField = {
        return self.textField()
    }()

    private lazy var descriptionTextField: UITextView = {
        return self.textView()
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
        setupTitle(text: tag.name)
        setupTable()
    }

    private func setupTitle(text: String?) {
        navigationItem.title = text
    }

    private func setupTable() {
        WPStyleGuide.configureColors(for: view, andTableView: tableView)
        tableView.tableFooterView = UIView(frame: .zero)
    }

    private func cell(content: UIView) -> WPTableViewCell {
        let returnValue = WPTableViewCell(style: .default, reuseIdentifier: nil)
        returnValue.selectionStyle = .none
        returnValue.contentView.addSubview(content)

        let readableGuide = returnValue.contentView.readableContentGuide
        NSLayoutConstraint.activate([
            content.leadingAnchor.constraint(equalTo: readableGuide.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: readableGuide.trailingAnchor),
            content.topAnchor.constraint(equalTo: readableGuide.topAnchor),
            content.bottomAnchor.constraint(equalTo: readableGuide.bottomAnchor)
            ])

        return returnValue
    }

    private func textField() -> UITextField {
        let returnValue = UITextField(frame: .zero)
        returnValue.translatesAutoresizingMaskIntoConstraints = false
        returnValue.font = WPStyleGuide.tableviewTextFont()
        returnValue.textColor = WPStyleGuide.darkGrey()
        returnValue.returnKeyType = .done
        returnValue.keyboardType = .default

        returnValue.addTarget(self, action: #selector(textChanged), for: .editingChanged)

        return returnValue
    }

    private func textView() -> UITextView {
        let returnValue = UITextView(frame: .zero, textContainer: nil)
        returnValue.translatesAutoresizingMaskIntoConstraints = false
        returnValue.font = WPStyleGuide.tableviewTextFont()
        returnValue.textColor = WPStyleGuide.darkGrey()

        return returnValue
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
        let sectionForIndexPath = Sections.section(for: indexPath.section)
        switch sectionForIndexPath {
        case .name:
            nameTextField.text = tag.name
            return nameCell
        case .description:
            descriptionTextField.text = tag.tagDescription
            return descriptionCell
        }
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let sectionForIndexPath = Sections.section(for: indexPath.section)
        return sectionForIndexPath.height
    }
}

extension SiteTagViewController {
    @objc
    fileprivate func textChanged(_ textField: UITextField) {
        setupTitle(text: textField.text)
    }
}
