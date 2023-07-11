import Foundation

@objc public protocol ReaderStreamHeaderDelegate {
    func handleFollowActionForHeader(_ header: ReaderStreamHeader, completion: @escaping () -> Void)
}

@objc public protocol ReaderStreamHeader {
    weak var delegate: ReaderStreamHeaderDelegate? {get set}
    func enableLoggedInFeatures(_ enable: Bool)
    func configureHeader(_ topic: ReaderAbstractTopic)
}
