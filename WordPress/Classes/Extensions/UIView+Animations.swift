import Foundation


/// Encapsulates UIView Animation Helpers
///
extension UIView
{
    /// Applies a "Shrink to 80%" animation
    ///
    public func depressAnimation() {
        let parameters = ScaleParameters(0.8, 0.0, 0.4)
        scaleAnimation(parameters)
    }

    /// Applies a "Expand to 100%" animation
    ///
    public func normalizeAnimation() {
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
        let damping         = CGFloat(0.3)
        let velocity        = CGFloat(0.1)

        let animations = {
            self.transform  = CGAffineTransformMakeScale(parameters.scale, parameters.scale)
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
    public func displayWithSpringAnimation() {

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
    public func displayWithFadeInAnimation() {

        let duration        = 0.3
        let alphaInitial    = CGFloat(0.5)
        let alphaFinal      = CGFloat(1.0)

        alpha               = alphaInitial

        UIView.animateWithDuration(duration) { [weak self] in
            self?.alpha = alphaFinal
        }
    }


    /// MARK: - Private Typealiases
    private typealias ScaleParameters = (scale: CGFloat, delay: NSTimeInterval, duration: NSTimeInterval)
}
