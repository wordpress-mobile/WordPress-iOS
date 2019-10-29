protocol AsyncBlocksLoadable {
    typealias AsyncBlock<Value> = () -> Value
    typealias CacheBlock = () -> Bool

    associatedtype CurrentStore
    associatedtype RowType

    /// The current Store used
    var currentStore: CurrentStore { get }

    /// This function returns the blocks to display during the Stats loading event
    /// - Parameter blockType: The block type
    /// - Parameter type: The Stats type
    /// - Parameter status: The block status
    /// - Parameter checkingCache: The block used to check if the data is cached and needs to be checked in a different way from the default implementation
    /// - Parameter block: The main block to display
    /// - Parameter loading: The loading block to display
    /// - Parameter error: The error block to display
    func blocks<Value>(for blockType: RowType,
                       type: StatType,
                       status: StoreFetchingStatus,
                       checkingCache: CacheBlock?,
                       block: AsyncBlock<Value>,
                       loading: AsyncBlock<Value>,
                       error: AsyncBlock<Value>) -> Value
}

extension AsyncBlocksLoadable where CurrentStore: StatsStoreCacheable, RowType == CurrentStore.StatsStoreType {
    func blocks<Value>(for blockType: RowType,
                       type: StatType,
                       status: StoreFetchingStatus,
                       checkingCache: CacheBlock? = nil,
                       block: AsyncBlock<Value>,
                       loading: AsyncBlock<Value>,
                       error: AsyncBlock<Value>) -> Value {
        let isFeatureEnabled = (type == .insights) ? true : Feature.enabled(.statsAsyncLoadingDWMY)
        let containsCachedData = checkingCache?() ?? currentStore.containsCachedData(for: blockType)

        if containsCachedData || !isFeatureEnabled {
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
