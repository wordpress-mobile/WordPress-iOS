import Foundation

class ReaderInterest {
    var isSelected: Bool = false
    
    let title: String
    let slug: String

    init(title: String, slug: String) {
        self.title = title
        self.slug = slug
    }
}

class InterestsDataSource {
    private(set) var count: Int = 0
    private(set) var interests: [ReaderInterest] = []

    init(fileName: String) {
        parseJSON(fileName: fileName)
    }

    private func parseJSON(fileName: String) {
        guard
            let fileURL: URL = Bundle.main.url(forResource: fileName, withExtension: nil),
            let data: Data = try? Data(contentsOf: fileURL),
            let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: AnyObject],
            let interests = jsonObject["interests"] as? [[String: String]]
        else {
            return
        }

        var readerInterests: [ReaderInterest] = []
        interests.forEach { (dict) in
            guard
                let slug = dict["slug-en"],
                let title = dict["title"]
            else {
                return
            }

            readerInterests.append(ReaderInterest(title: title, slug: slug))
        }

        self.interests = readerInterests
        self.count = readerInterests.count
    }

    public func interest(for row: Int) -> ReaderInterest {
        return interests[row]
    }
}
