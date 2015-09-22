import Foundation

public protocol ReaderStreamHeaderDelegate: NSObjectProtocol
{
    func handleFollowActionForHeader(header:ReaderStreamHeader)
}

public protocol ReaderStreamHeader: NSObjectProtocol
{
    var delegate: ReaderStreamHeaderDelegate? {get set}
    func enableLoggedInFeatures(enable: Bool)
    func configureHeader(topic: ReaderAbstractTopic)
}
