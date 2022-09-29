import Foundation

protocol AppIconListViewModelType {
    var icons: [AppIconListSection] { get }
}

struct AppIconListSection {
    let title: String?
    let items: [AppIcon]

    subscript(_ index: Int) -> AppIcon {
        return items[index]
    }
}
