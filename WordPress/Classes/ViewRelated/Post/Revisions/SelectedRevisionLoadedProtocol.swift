import Foundation


protocol SelectedRevisionLoadedProtocol {
    typealias SelectedRevisionBlock = (AbstractPost) -> Void

    var selectedRevisionLoaded: SelectedRevisionBlock { get set }
}
