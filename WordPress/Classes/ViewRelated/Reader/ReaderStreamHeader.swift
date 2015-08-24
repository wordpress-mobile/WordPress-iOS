import Foundation

@objc public protocol ReaderStreamHeaderDelegate: NSObjectProtocol
{
    optional
    func handleFollowActionForHeader(header:ReaderStreamHeader)
}

@objc public protocol ReaderStreamHeader: NSObjectProtocol
{
    var delegate: ReaderStreamHeaderDelegate? { get set }
    func configureHeader(topic: ReaderTopic)
}
