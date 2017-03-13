import Foundation

class FakePreviewBuilder: NSObject {
    let title: String?
    let content: String?
    let tags: [String]
    let categories: [String]
    let message: String?

    init(title: String?, content: String?, tags: [String], categories: [String], message: String?) {
        self.title = title
        self.content = content
        self.tags = tags
        self.categories = categories
        self.message = message
        super.init()
    }

    func build() -> String {
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
        return title?.nonEmptyString() ?? NSLocalizedString("(no title)", comment: "")
    }

    var previewContent: String {
        guard var contentText = content?.nonEmptyString() else {
            let placeholder = NSLocalizedString("No Description available for this Post", comment: "")
            return "<h1>\(placeholder)</h1>"
        }
        contentText = contentText.replacingOccurrences(of: "\n", with: "<br>")
        return "<p>\(contentText)</p><br />"
    }

    var previewTags: String {
        let tagsLabel = NSLocalizedString("Tags: %@", comment: "")
        return String(format: tagsLabel, tags.joined(separator: ", "))
    }

    var previewCategories: String {
        let categoriesLabel = NSLocalizedString("Categories: %@", comment: "")
        return String(format: categoriesLabel, categories.joined(separator: ", "))
    }
}


// MARK: - Processing AbstractPost

extension FakePreviewBuilder {
    convenience init(apost: AbstractPost, message: String?) {
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
