import Foundation
import WordPressData

extension AbstractPost {
    /// The parsed components of a post's composite Spotlight identifier
    /// (`abstractPost|~~~|<dotComID or xmlrpc>|~~~|<postID>`).
    struct SearchIdentifier {
        /// A WP.com site ID when numeric, the site's xmlrpc URL otherwise,
        /// matching the Spotlight identifier convention.
        let domain: String
        let postID: Int

        init?(identifier: String) {
            guard
                let (itemType, domain, postIDString) = SearchIdentifierGenerator.decomposeFromUniqueIdentifier(
                    identifier
                ),
                itemType == .abstractPost,
                let postID = Int(postIDString)
            else {
                return nil
            }
            self.domain = domain
            self.postID = postID
        }

        /// Whether the post lives on a WP.com site.
        var isDotCom: Bool {
            Int(domain) != nil
        }

        /// The site the identifier belongs to, if it is in the local store.
        func blog(in context: NSManagedObjectContext) -> Blog? {
            if let siteID = Int(domain) {
                return try? Blog.lookup(withID: siteID, in: context)
            }
            return try? BlogQuery().hostedByWPCom(false).xmlrpc(matching: domain).blog(in: context)
        }

        /// The post the identifier refers to, if it is in the local store.
        /// Resolution never falls back to another post.
        func post(in context: NSManagedObjectContext) -> AbstractPost? {
            blog(in: context)?.lookupPost(withID: postID, in: context)
        }
    }
}
