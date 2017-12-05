import UIKit

final class SiteTagViewController: UITableViewController {
    private let blog: Blog
    private let tag: PostTag

    private enum Sections: Int, CustomStringConvertible {
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

    public init(blog: Blog, tag: PostTag) {
        self.blog = blog
        self.tag = tag
        super.init(style: .grouped)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        print("Editing tag ", tag.name)
    }
}
