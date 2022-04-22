import Foundation

enum QuickStartType {
    case newUser
    case existingUser
}

class QuickStartFactory {
    static func collections(for blog: Blog) -> [QuickStartToursCollection] {
        // TODO: Save QuickStartType in blog. Retrieve it here and return collections accordingly
        return [QuickStartCustomizeToursCollection(blog: blog), QuickStartGrowToursCollection(blog: blog)]
    }
}
