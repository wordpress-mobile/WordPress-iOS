import Foundation

@objc open class ReaderTeamTopic: ReaderAbstractTopic {
    @NSManaged open var slug: String

    override open class var TopicType: String {
        return "team"
    }

    @objc open var icon: UIImage? {
        guard bundledTeamIcons.contains(slug) else {
            return nil
        }

        return UIImage(named: slug)
    }

    fileprivate let bundledTeamIcons: [String] = [
        "a8c"
    ]
}
