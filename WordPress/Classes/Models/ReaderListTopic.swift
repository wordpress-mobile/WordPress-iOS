import Foundation

@objc public class ReaderListTopic : ReaderAbstractTopic
{
    @NSManaged var isOwner: Bool
    @NSManaged var isPublic: Bool
    @NSManaged var listDescription: String
    @NSManaged var listID:NSNumber
    @NSManaged var owner: String
    @NSManaged var slug:String
}
