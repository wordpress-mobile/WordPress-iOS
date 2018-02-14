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

// MARK: - Implementation
public extension ControlEventBindable where Self: UIControl {
    private var controlEventHandlers: [ControlEventHandler<Self>] {
        get { return (objc_getAssociatedObject(self, &Keys.ControlEventHandlers) as? [ControlEventHandler<Self>]) ?? [] }
        set { objc_setAssociatedObject(self, &Keys.ControlEventHandlers, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    /// Listen for `UIControlEvents` executing the provided closure when triggered
    public func on(_ events: UIControlEvents, call closure: @escaping (Self) -> Void) {
        let handler = ControlEventHandler<Self>(sender: self, events: events, closure: closure)
        self.controlEventHandlers.append(handler)
    }
}

// MARK: - Private
private struct Keys {
    static var ControlEventHandlers = "_ControlEventHandlers"
}

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

// Adding UIBarButtonItem

private final class BarButtonItemEventHandler<Sender: UIBarButtonItem>: NSObject {
    let closure: (Sender) -> Void

    init(sender: Sender, events: UIControlEvents, closure: @escaping (Sender) -> Void) {
        self.closure = closure
        super.init()

        sender.target = self
        sender.action = #selector(self.action)
    }

    @objc private func action(sender: UIBarButtonItem) {
        guard let sender = sender as? Sender else { return }

        self.closure(sender)
    }
}

extension UIBarButtonItem: ControlEventBindable { }

// MARK: - Implementation
extension ControlEventBindable where Self: UIBarButtonItem {
    private var controlEventHandlers: [BarButtonItemEventHandler<Self>] {
        get { return (objc_getAssociatedObject(self, &Keys.ControlEventHandlers) as? [BarButtonItemEventHandler<Self>]) ?? [] }
        set { objc_setAssociatedObject(self, &Keys.ControlEventHandlers, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    /// Listen for `UIControlEvents` executing the provided closure when triggered
    public func on(call closure: @escaping (Self) -> Void) {
        let handler = BarButtonItemEventHandler<Self>(sender: self, events: .touchUpInside, closure: closure)
        self.controlEventHandlers.append(handler)
    }
}


// MARK: - Internationalization helper

extension UIControl {
    public enum NaturalContentHorizontalAlignment {
        case leading
        case trailing
    }

    /// iOS 10 compatible leading/trailing contentHorizontalAlignment. Prefer this to set content alignment to respect Right-to-Left language layouts.
    ///
    public var naturalContentHorizontalAlignment: NaturalContentHorizontalAlignment? {
        get {
            switch contentHorizontalAlignment {
            case .left, .leading:
                return .leading
            case .right, .trailing:
                return .trailing
            default:
                return nil
            }
        }

        set(alignment) {
            if #available(iOS 11.0, *) {
                contentHorizontalAlignment = (alignment == .leading) ? .leading : .trailing
            } else {
                if userInterfaceLayoutDirection() == .leftToRight {
                    contentHorizontalAlignment = (alignment == .leading) ? .left : .right
                } else {
                    contentHorizontalAlignment = (alignment == .leading) ? .right : .left
                }
            }
        }
    }
}
