// From https://gist.github.com/IanKeen/57db93aee14b845f4090b1fcc048e94b
//
/* MIT License

 Copyright (c) 2017 Ian Keen

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
 */

public protocol ControlEventBindable: class { }

extension UIControl: ControlEventBindable { }

struct BlockEventKeys {
    static var ControlEventHandlers = "_ControlEventHandlers"
}

// MARK: - Implementation
public extension ControlEventBindable where Self: UIControl {
    private var controlEventHandlers: [ControlEventHandler<Self>] {
        get { return (objc_getAssociatedObject(self, &BlockEventKeys.ControlEventHandlers) as? [ControlEventHandler<Self>]) ?? [] }
        set { objc_setAssociatedObject(self, &BlockEventKeys.ControlEventHandlers, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    /// Listen for `UIControlEvents` executing the provided closure when triggered
    public func on(_ events: UIControlEvents, call closure: @escaping (Self) -> Void) {
        let handler = ControlEventHandler<Self>(sender: self, events: events, closure: closure)
        self.controlEventHandlers.append(handler)
    }
}

// MARK: - Private

private final class ControlEventHandler<Sender: UIControl>: NSObject {
    let closure: (Sender) -> Void

    init(sender: Sender, events: UIControlEvents, closure: @escaping (Sender) -> Void) {
        self.closure = closure
        super.init()

        sender.addTarget(self, action: #selector(self.action), for: events)
    }

    @objc private func action(sender: UIControl) {
        guard let sender = sender as? Sender else { return }

        self.closure(sender)
    }
}
