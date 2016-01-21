import RxSwift

// MARK: - forwardIf
// This has been proposed for inclusion in RxSwift
// https://github.com/ReactiveX/RxSwift/pull/422
// I can't copy the exact implementation here since it relies on internal classes
// I added an alternative implementation instead
// @koke 2016-01-21

extension ObservableType {

    /**
     Propagates the source observable sequence while the condition observable sequence last value is true.

     - parameter source: Source observable sequence to propagate
     - parameter condition: Boolean observable sequence that dictates if the source propagates.
     - returns: An observable sequence that subscribes and emits the values of the source observable as long as the last emitted value of the condition observable is true.
     */
    public func forwardIf<ConditionO: ObservableConvertibleType where ConditionO.E == Bool>(condition: ConditionO) -> Observable<E> {
        return ForwardIf(source: self, condition: condition.asObservable()).asObservable()
    }
}

class ForwardIf<S: ObservableType>: ObservableType {
    typealias E = S.E
    typealias DisposeKey = CompositeDisposable.DisposeKey

    private let _source: S
    private let _condition: Observable<Bool>
    private let _controller = PublishSubject<S.E>()
    private let _group = CompositeDisposable()

    private var _connectionKey: DisposeKey? = nil

    init(source: S, condition: Observable<Bool>) {
        _source = source
        _condition = condition
    }

    func subscribe<O: ObserverType where O.E == E>(observer: O) -> Disposable {
        let conn = _source.publish()
        let connection = conn.subscribe(observer)
        _group.addDisposable(connection)

        let subscription = _condition
            .distinctUntilChanged()
            .subscribeNext { active in
                if active {
                    self._connectionKey = self._group.addDisposable(conn.connect())
                } else {
                    if let connectionKey = self._connectionKey {
                        self._group.removeDisposable(connectionKey)
                        self._connectionKey = nil
                    }
                }
        }
        _group.addDisposable(subscription)

        return _group
    }
}
