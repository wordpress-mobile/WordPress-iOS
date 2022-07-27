import Foundation

public protocol ReaderStreamHeaderDelegate: NSObjectProtocol {
    func handleFollowActionForHeader(_ header: ReaderStreamHeader, completion: @escaping () -> Void)
}

public protocol ReaderStreamHeader: NSObjectProtocol {
    var delegate: ReaderStreamHeaderDelegate? {get set}
    func enableLoggedInFeatures(_ enable: Bool)
    func configureHeader(_ topic: ReaderAbstractTopic)
}
