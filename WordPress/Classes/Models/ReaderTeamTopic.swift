import Foundation

@objc public class ReaderTeamTopic : ReaderAbstractTopic
{
    @NSManaged public var slug: String

    override public class var TopicType: String {
        return "team"
    }

    public var icon: UIImage? {
        guard bundledTeamIcons.contains(slug) else {
            return nil
        }

        return UIImage(named: slug)
    }

    private let bundledTeamIcons: [String] = [
        "a8c"
    ]
}
