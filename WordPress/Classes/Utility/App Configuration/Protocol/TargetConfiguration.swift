import Foundation

protocol TargetConfiguration {
    static var isJetpack: Bool { get }
}

protocol TargetFontConfiguration {
    static var navigationBarStandardFont: UIFont { get }
    static var navigationBarLargeFont: UIFont { get }
    static var blogDetailHeaderTitleFont: UIFont { get }
}
