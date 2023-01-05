import Foundation

protocol JetpackBrandedScreen {
    var featureName: String? { get }
    var isPlural: Bool { get }
    var analyticsId: String { get }
}
