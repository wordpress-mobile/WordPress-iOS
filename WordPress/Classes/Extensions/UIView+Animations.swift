import Foundation


/// Encapsulates UIView Animation Helpers
///
extension UIView
{
    /// Applies a "Shrink to 80%" animation
    ///
    func depressAnimation() {
        let parameters = ScaleParameters(0.8, 0.0, 0.4)
        scaleAnimation(parameters)
    }

    /// Applies a "Expand to 100%" animation
    ///
    func normalizeAnimation() {
        let parameters = ScaleParameters(1.0, 0.0, 0.4)
        scaleAnimation(parameters)
    }

    /// Applies a Scaling with Spring Animation.
    ///
    /// - Parameters:
    ///     - parameters: A tuple containing all of the required Scale Parameters.
    ///     - completion: Callback to be executed on completion.
    ///
    private func scaleAnimation(parameters: ScaleParameters, completion: (Bool -> Void)? = nil) {
        let damping = CGFloat(0.3)
        let velocity = CGFloat(0.1)

        let animations = {
            self.transform = CGAffineTransformMakeScale(parameters.scale, parameters.scale)
        }

        UIView.animateWithDuration(parameters.duration,
                                   delay:                   parameters.delay,
                                   usingSpringWithDamping:  damping,
                                   initialSpringVelocity:   velocity,
                                   options:                 .CurveEaseInOut,
                                   animations:              animations,
                                   completion:              completion)
    }

    /// Applies a spring animation, from size 0 to final size
    ///
    func springAnimation() {
        let duration        = 0.5
        let delay           = 0.2
        let damping         = CGFloat(0.7)
        let velocity        = CGFloat(0.5)
        let scaleInitial    = CGFloat(0.0)
        let scaleFinal      = CGFloat(1.0)

        hidden              = false
        transform           = CGAffineTransformMakeScale(scaleInitial, scaleInitial)

        let animations = {
            self.transform  = CGAffineTransformMakeScale(scaleFinal, scaleFinal)
        }

        UIView.animateWithDuration(duration,
            delay:                  delay,
            usingSpringWithDamping: damping,
            initialSpringVelocity:  velocity,
            options:                .CurveEaseInOut,
            animations:             animations,
            completion:             nil
        )
    }

    /// Applies a fade in animation
    ///
    public func fadeInAnimation() {
        alpha = Animations.alphaMid

        UIView.animateWithDuration(Animations.duration) { [weak self] in
            self?.alpha = Animations.alphaFull
        }
    }


    }


    /// Private Constants
    ///
    private struct Animations {
        static let duration                 = NSTimeInterval(0.3)
        static let alphaZero                = CGFloat(0)
        static let alphaMid                 = CGFloat(0.5)
        static let alphaFull                = CGFloat(1)
    }

    /// MARK: - Private Typealiases
    private typealias ScaleParameters = (scale: CGFloat, delay: NSTimeInterval, duration: NSTimeInterval)
}
