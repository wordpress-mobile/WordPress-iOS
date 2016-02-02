import RxSwift

// MARK: - pausable

extension ObservableType {

    /**
     Pauses the underlying observable sequence based upon the observable sequence which yields true/false.

     - parameter pauser: The observable sequence used to pause the underlying sequence.
     - returns: An observable sequence that subscribes and emits the values of the source observable as long as the last emitted value of the condition observable is true.
     */
    public func pausable<ConditionO: ObservableConvertibleType where ConditionO.E == Bool>(pauser: ConditionO) -> Observable<E> {
        return Pausable(source: self, pauser: pauser.asObservable()).asObservable()
    }
}

class Pausable<S: ObservableType>: ObservableType {
    typealias E = S.E
    typealias DisposeKey = CompositeDisposable.DisposeKey

    private let _lock = NSRecursiveLock()

    private let _source: S
    private let _pauser: Observable<Bool>
    private let _group = CompositeDisposable()

    private var _connectionKey: DisposeKey? = nil

    init(source: S, pauser: Observable<Bool>) {
        _source = source
        _pauser = pauser
    }

    func subscribe<O: ObserverType where O.E == E>(observer: O) -> Disposable {
        let conn = _source.publish()
        let connection = conn.subscribe(observer)
        _group.addDisposable(connection)

        let subscription = _pauser
            .distinctUntilChanged()
            .subscribeNext { active in
                self._lock.lock(); defer { self._lock.unlock() } // lock {
                    if active {
                        self._connectionKey = self._group.addDisposable(conn.connect())
                    } else {
                        if let connectionKey = self._connectionKey {
                            self._group.removeDisposable(connectionKey)
                            self._connectionKey = nil
                        }
                    }
                // }
        }
        _group.addDisposable(subscription)

        return _group
    }
}

// MARK: - retryIf

extension ObservableType {
    /**
     Repeats the source observable sequence on error if the given condition evaluates true.
     
     - parameter condition: A closure to be evaluated on error to decide if the source sequence should be retried. It takes two parameters: an incrementing `count` integer, and a `lastError` containing the latest error emitted.
     - returns: An observable sequence producing the elements of the given sequence repeatedly until it terminates successfully or the condition evaluates false.
     */
    public func retryIf(condition: (count: Int, lastError: NSError) -> Bool) -> Observable<E> {
        return retryWhen { (errors: Observable<NSError>) in
            errors.scan((0, nil)) { (accumulator: (Int, NSError!), error) in
                (accumulator.0 + 1, error)
            }
            .flatMap { (count, lastError) -> Observable<Int> in
                if condition(count: count, lastError: lastError) {
                    return Observable.just(count)
                } else {
                    return Observable.error(lastError)
                }
            }
        }
    }
}
