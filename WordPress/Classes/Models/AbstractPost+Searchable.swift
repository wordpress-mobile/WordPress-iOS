import Foundation

extension Post: SearchableItemConvertable {
    var searchIdentifier: String {
        if let postID = postID, postID.intValue > 0 {
            return postID.stringValue
        } else if let postTitle = postTitle {
            return postTitle.components(separatedBy: .whitespacesAndNewlines).joined()
        } else {
            return slugForDisplay()
        }
    }

    var searchDomain: String {
        return blog.displayURL as String? ?? String()
    }

    var searchTitle: String? {
        guard let postTitle = postTitle else {
            return nil
        }

        return postTitle
    }

    var searchDescription: String? {
        let postPreview = contentPreviewForDisplay()
        guard !postPreview.isEmpty else {
            return nil
        }

        return postPreview
    }

    var searchKeywords: [String]? {
        guard hasTags() else {
            return nil
        }

        return tags?.arrayOfTags()
    }
}
