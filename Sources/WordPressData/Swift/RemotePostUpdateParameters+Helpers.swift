import WordPressKit

public extension RemotePostUpdateParameters {

    var isEmpty: Bool {
        self == RemotePostUpdateParameters()
    }

    /// Returns a diff between the original and the latest revision with the
    /// changes applied on top.
    static func changes(from original: AbstractPost, to latest: AbstractPost, with changes: RemotePostUpdateParameters? = nil) -> RemotePostUpdateParameters {
        guard original !== latest else {
            return changes ?? RemotePostUpdateParameters()
        }
        let parametersOriginal = RemotePostCreateParameters(post: original)
        var parametersLatest = RemotePostCreateParameters(post: latest)
        if let changes {
            parametersLatest.apply(changes)
        }
        return parametersLatest.changes(from: parametersOriginal)
    }
}
