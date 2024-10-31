import Foundation

struct CountriesMap: Hashable {
    let minViewsCount: Int
    let maxViewsCount: Int
    let data: [String: NSNumber]
}
