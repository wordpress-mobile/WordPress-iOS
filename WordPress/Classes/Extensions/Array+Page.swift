import Foundation

// Array etension to handle Pages on a Page list
//
extension Array where Element == Page {
    /// Return the first index
    var firstIndex: Int {
        return 0
    }

    /// Return the last index
    var lastIndex: Int {
        return isEmpty ? 0 : count - 1
    }

    /// Check if the Array contains a specific Page for a specific `id`
    ///
    /// - Parameter pageId: Page id
    /// - Returns: If the Page exists or not
    func containsPage(for pageId: Int?) -> Bool {
        guard let pageId = pageId else {
            return false
        }

        return contains { $0.postID?.intValue == pageId }
    }

    /// A map function where transform closure receives the Element and Array
    ///
    /// - Parameter transform: Closure accepting the Element and the Array
    /// - Returns: An transformed array of Elements
    func map<T>(_ transform: (Element, [Element]) -> T) -> [T] {
        var result: [T] = []
        result.reserveCapacity(count)
        forEach {
            result.append(transform($0, self))
        }
        return result
    }

    /// DFS sort where the pages are hierarchly ordered in a flat list
    ///
    /// - Parameters:
    ///   - parent: A parent Element
    ///   - consideringTopLevel: Force to check if the pages are visually top levels
    /// - Returns: An Array of Elements
    func sort(by parent: Element? = nil, consideringTopLevel: Bool = true) -> [Element] {
        var sortedList: [Element] = []
        let block = { (row: Element) -> Bool in
            return consideringTopLevel ? row.hasVisibleParent : row.parentID?.intValue == parent?.postID?.intValue
        }
        filter(block).forEach {
            sortedList.append($0)
            sortedList.append(contentsOf: sort(by: $0, consideringTopLevel: false))
        }
        return sortedList
    }

    /// Set indexes for a hierarchy list
    ///
    /// - Returns: An Array of Elements
    func hierachyIndexes() -> [Element] {
        var index = 0
        forEach {
            if $0.hasVisibleParent {
                $0.hierarchyIndex = 0
            } else {
                let parentId = $0.parentID?.intValue
                let parent = self.reversed().first { parentId == $0.postID?.intValue }
                $0.hierarchyIndex = (parent != nil) ? parent!.hierarchyIndex + 1 : index
            }

            index += 1
        }

        return self
    }

    /// Sort and set indexes for a hierarchy list
    ///
    /// - Returns: An Array of Elements
    func hierarchySort() -> [Element] {
        return map {
            $0.hasVisibleParent = !$1.containsPage(for: $0.parentID?.intValue)
            return $0
            }
            .sort()
            .hierachyIndexes()
    }

    /// Moves the homepage first if it is on the top level
    ///
    /// - Returns: An Array of Elements
    func setHomePageFirst() -> [Element] {
        if let homepageIndex = self.firstIndex(where: { $0.isSiteHomepage }) {
            var pages: [Page] = Array(self)
            let homepage = pages.remove(at: homepageIndex)
            pages.insert(homepage, at: 0)
            return pages
        }
        return self
    }

    /// Remove Elements from a specific index
    ///
    /// - Parameter index: The starting index
    /// - Returns: An Array of Elements
    func remove(from index: Int) -> [Element] {
        if isEmpty || index < firstIndex || index > lastIndex {
            return self
        }

        var left: ArraySlice<Element> = []
        var right: ArraySlice<Element> = []

        switch index {
        case firstIndex:
            right = dropFirst()

        case lastIndex:
            return Array<Element>(dropLast())

        default:
            left = self[0...(index - 1)]
            right = self[(index + 1)...]
        }

        for element in right {
            if element.hasVisibleParent {
                break
            }

            if let index = right.firstIndex(of: element),
                !(left.contains { $0.postID == element.parentID }) {
                right.remove(at: index)
            }
        }

        return Array(left + right)
    }
}
