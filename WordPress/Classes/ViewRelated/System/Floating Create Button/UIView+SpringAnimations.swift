extension FloatingActionButton {

    private enum Constants {
        enum Maximize {
            static let damping: CGFloat = 0.7
            static let duration: TimeInterval = 0.5
            static let initialScale: CGFloat = 0.0
            static let finalScale: CGFloat = 1.0
        }
        enum Minimize {
            static let damping: CGFloat = 0.9
            static let duration: TimeInterval = 0.25
            static let initialScale: CGFloat = 1.0
            static let finalScale: CGFloat = 0.001
        }
    }

    /// Animates the showing and hiding of a view using a spring animation
    /// - Parameter toShow: Whether to show the view
    func springAnimation(toShow: Bool) {
        if toShow {
            guard isHidden == true else { return }
            maximizeSpringAnimation()
        } else {
            guard isHidden == false else { return }
            minimizeSpringAnimation()
        }
    }

    /// Applies a spring animation, from size 1 to 0
    func minimizeSpringAnimation() {
        let damping = Constants.Minimize.damping
        let scaleInitial = Constants.Minimize.initialScale
        let scaleFinal = Constants.Minimize.finalScale
        let duration = Constants.Minimize.duration

        scaleAnimation(duration: duration, damping: damping, scaleInitial: scaleInitial, scaleFinal: scaleFinal) { [weak self] success in
            self?.transform = .identity
            self?.isHidden = true
        }
    }

    /// Applies a spring animation, from size 0 to 1
    func maximizeSpringAnimation() {
        let damping = Constants.Maximize.damping
        let scaleInitial = Constants.Maximize.initialScale
        let scaleFinal = Constants.Maximize.finalScale
        let duration = Constants.Maximize.duration

        scaleAnimation(duration: duration, damping: damping, scaleInitial: scaleInitial, scaleFinal: scaleFinal)
    }

    func scaleAnimation(duration: TimeInterval, damping: CGFloat, scaleInitial: CGFloat, scaleFinal: CGFloat, completion: ((Bool) -> Void)? = nil) {
        setNeedsDisplay() // Make sure we redraw so that corners are rounded
        transform = CGAffineTransform(scaleX: scaleInitial, y: scaleInitial)
        isHidden = false

        let animator = UIViewPropertyAnimator(duration: duration, dampingRatio: damping) {
            self.transform  = CGAffineTransform(scaleX: scaleFinal, y: scaleFinal)
        }

        animator.addCompletion { (position) in
            completion?(true)
        }

        animator.startAnimation()
    }
}
