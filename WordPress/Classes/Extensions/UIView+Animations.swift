import Foundation


// MARK: UIView Animation Helpers
//
extension UIView
{
    /// Applies a "Shrink to 80%" spring animation
    ///
    func depressSpringAnimation(completion: (Bool -> Void)? = nil) {
        scaleSpringAnimation(0.8, delay: 0.0, duration: Animations.duration)
    }

    /// Applies a "Expand to 100%" spring animation
    ///
    func normalizeSpringAnimation(completion: (Bool -> Void)? = nil) {
        scaleSpringAnimation(1.0, delay: 0.0, duration: Animations.duration)
    }

    /// Applies a Scaling with Spring Animation.
    ///
    /// - Parameters:
    ///     - scale: Target Scale
    ///     - delay: Time before the animation will be applied
    ///     - duration: Duration of the animation
    ///     - completion: Callback to be executed on completion.
    ///
    private func scaleSpringAnimation(scale: CGFloat, delay: NSTimeInterval, duration: NSTimeInterval, completion: (Bool -> Void)? = nil) {
        let damping = CGFloat(0.3)
        let velocity = CGFloat(0.1)

        let animations = {
            self.transform = CGAffineTransformMakeScale(scale, scale)
        }

        UIView.animateWithDuration(duration,
                                   delay:                   delay,
                                   usingSpringWithDamping:  damping,
                                   initialSpringVelocity:   velocity,
                                   options:                 .CurveEaseInOut,
                                   animations:              animations,
                                   completion:              completion)
    }

    /// Applies a spring animation, from size 0 to final size
    ///
    func expandSpringAnimation(completion: (Bool -> Void)? = nil) {
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
            completion:             completion
        )
    }

    /// Applies a fade in animation
    ///
    public func fadeInAnimation(completion: (Bool -> Void)? = nil) {
        alpha = Animations.alphaMid

        UIView.animateWithDuration(Animations.duration, animations: { [weak self] in
            self?.alpha = Animations.alphaFull
        }, completion: { success in
            completion?(success)
        })
    }

    /// Displays the current view with a Fade In / Rotation Animation
    ///
    func fadeInWithRotationAnimation(completion: (Bool -> Void)? = nil) {
        transform = CGAffineTransform.makeRotation(-270, scale: 3)
        alpha = Animations.alphaZero

        UIView.animateWithDuration(Animations.duration, animations: {
            self.transform = CGAffineTransform.makeRotation(0, scale: 0.75)
            self.alpha = Animations.alphaFull
        }, completion: { _ in
            UIView.animateWithDuration(Animations.duration, animations: {
                self.transform = CGAffineTransformMakeScale(1.0, 1.0)
            }, completion: { success in
                completion?(success)
            })
        })
    }

    /// Hides the current view with a Rotation / FadeOut Animation
    ///
    func fadeOutWithRotationAnimation(completion: (Bool -> Void)? = nil) {
        UIView.animateWithDuration(Animations.duration, animations: {
            self.transform = CGAffineTransform.makeRotation(120, scale: 3)
            self.alpha = Animations.alphaZero
        }, completion: { success in
            completion?(success)
        })
    }

    /// Applies an "Expand to 300%" animation + Fade Out
    ///
    func explodeAnimation(completion: (Bool -> Void)? = nil) {
        UIView.animateWithDuration(Animations.duration, animations: {
            self.transform = CGAffineTransformMakeScale(3.0, 3.0)
            self.alpha = Animations.alphaZero
        }, completion: { success in
            completion?(success)
        })
    }

    /// Applies an "Expand from 300% to 100" animation
    ///
    func implodeAnimation(completion: (Bool -> Void)? = nil) {
        transform = CGAffineTransformMakeScale(3.0, 3.0)
        alpha = Animations.alphaZero

        UIView.animateWithDuration(Animations.duration, animations: {
            self.alpha = Animations.alphaFull
            self.transform = CGAffineTransformMakeScale(1.0, 1.0)
        }, completion: { success in
            completion?(success)
        })
    }


    /// Private Constants
    ///
    private struct Animations {
        static let duration         = NSTimeInterval(0.3)
        static let alphaZero        = CGFloat(0)
        static let alphaMid         = CGFloat(0.5)
        static let alphaFull        = CGFloat(1)
    }
}
