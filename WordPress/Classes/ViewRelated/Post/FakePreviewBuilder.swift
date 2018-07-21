import Foundation

class FakePreviewBuilder: NSObject {
    @objc let title: String?
    @objc let content: String?
    @objc let tags: [String]
    @objc let categories: [String]
    @objc let message: String?

    @objc init(title: String?, content: String?, tags: [String], categories: [String], message: String?) {
        self.title = title
        self.content = content
        self.tags = tags
        self.categories = categories
        self.message = message
        super.init()
    }

    @objc func build() -> String {
        let template = loadTemplate()
        let messageParagraph = message.map({ "<p>\($0)</p>" }) ?? ""
        return template
            .replacingOccurrences(of: "!$title$!", with: previewTitle)
            .replacingOccurrences(of: "!$text$!", with: previewContent)
            .replacingOccurrences(of: "!$mt_keywords$!", with: previewTags)
            .replacingOccurrences(of: "!$categories$!", with: previewCategories)
            .replacingOccurrences(of: "<div class=\"page\">", with: "<div class=\"page\">\(messageParagraph)")
    }

    private func loadTemplate() -> String {
        guard let path = Bundle.main.path(forResource: "defaultPostTemplate", ofType: "html"),
            let template = try? String(contentsOfFile: path, encoding: .utf8) else {
                assertionFailure("Unable to load preview template")
                return ""
        }
        return template
    }
}

// MARK: - Formatting Fields

private extension FakePreviewBuilder {
    var previewTitle: String {
        return title?.nonEmptyString() ?? NSLocalizedString("(no title)", comment: "Placeholder text shown when a post does not have a title.")
    }

    var previewContent: String {
        guard var contentText = content?.nonEmptyString() else {
            let placeholder = NSLocalizedString("No Description available for this Post", comment: "Informs the user there is no description for a post being previewed.")
            return "<h1>\(placeholder)</h1>"
        }
        contentText = contentText.replacingOccurrences(of: "\n", with: "<br>")
        return "<p>\(contentText)</p><br />"
    }

    var previewTags: String {
        let tagsLabel = NSLocalizedString("Tags: %@", comment: "A label title. Tags associated with a post are shown in order after the colon.  The %@ is a placeholder for the tags.")
        return String(format: tagsLabel, tags.joined(separator: ", "))
    }

    var previewCategories: String {
        let categoriesLabel = NSLocalizedString("Categories: %@", comment: "A label title. Categories associated with a post are shown in order after the colon.  The %@ is a placeholder for the categories.")
        return String(format: categoriesLabel, categories.joined(separator: ", "))
    }
}


// MARK: - Processing AbstractPost

extension FakePreviewBuilder {
    @objc convenience init(apost: AbstractPost, message: String?) {
        let title = apost.postTitle
        let content = apost.content
        let tags: [String]
        let categories: [String]
        if let post = apost as? Post {
            tags = post.tags?
                .components(separatedBy: ",")
                .map({ $0.trim() })
                ?? []
            categories = post.categories?
                .map({ $0.categoryName })
                ?? []
        } else {
            tags = []
            categories = []
        }

        self.init(title: title, content: content, tags: tags, categories: categories, message: message)
    }
}
