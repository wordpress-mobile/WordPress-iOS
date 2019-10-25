protocol AsyncBlocksLoadable {
    typealias CompletionBlock<Value> = () -> Value

    associatedtype CurrentStore
    associatedtype RowType

    var currentStore: CurrentStore { get }

    func blocks<Value>(for blockType: RowType,
                       type: StatType,
                       status: StoreFetchingStatus,
                       block: CompletionBlock<Value>,
                       loading: CompletionBlock<Value>,
                       error: CompletionBlock<Value>) -> Value
}

extension AsyncBlocksLoadable where CurrentStore: StatsStoreCacheable, RowType == CurrentStore.StatsStoreType {
    func blocks<Value>(for blockType: RowType,
                       type: StatType,
                       status: StoreFetchingStatus,
                       block: CompletionBlock<Value>,
                       loading: CompletionBlock<Value>,
                       error: CompletionBlock<Value>) -> Value {
        let featureFlag: FeatureFlag = type == .insights ? .statsAsyncLoading : .statsAsyncLoadingDWMY
        if currentStore.containsCachedData(for: blockType) || !Feature.enabled(featureFlag) {
            return block()
        }

        switch status {
        case .loading, .idle:
            return loading()
        case .success:
            return block()
        case .error:
            return error()
        }
    }
}
