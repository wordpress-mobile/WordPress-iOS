@objc class UntouchableWindow: UIWindow {
    override init(frame: CGRect) {
        super.init(frame: frame)
        rootViewController = UntouchableViewController()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        guard let view = rootViewController?.view as? UntouchableView else {
            return false
        }
        let relativePoint = convert(point, to: view)
        return view.point(inside: relativePoint, with: event)
    }
}

class UntouchableViewController: UIViewController {
    required init() {
        super.init(nibName: nil, bundle: nil)

        self.view = UntouchableView()
    }

    var botttomAnchor: NSLayoutAnchor<NSLayoutYAxisAnchor> {
        if #available(iOS 11, *) {
            return view.safeAreaLayoutGuide.bottomAnchor
        } else {
            return NSLayoutAnchor<NSLayoutYAxisAnchor>()
        }
    }

    var bottomOffset: CGFloat {
        // TODO: make this look at the other UIWindow 
        return 50
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private class UntouchableView: UIView {

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let visibleViews = subviews.filter { view -> Bool in
            return view.alpha >= 0.01 && !view.isHidden && view.isUserInteractionEnabled
        }
        for view in visibleViews {
            let relativePoint = convert(point, to: view)
            if view.point(inside: relativePoint, with: event) {
                return true
            }
        }
        return false
    }
}
