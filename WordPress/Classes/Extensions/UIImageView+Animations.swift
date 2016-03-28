import Foundation


/// Encapsulates UIView Animation Helpers
///
extension UIImageView
{
    /// Applies a bounce animation over the receiver
    ///
    public func bounceAnimation() {
        typealias Parameters = (scale: CGFloat, delay: NSTimeInterval, duration: NSTimeInterval)
        let first : Parameters = (0.7, 0.0, 0.4)
        let second : Parameters = (1.0, 0.1, 0.2)
        
        scaleAnimation(first.scale, delay: first.delay, duration: first.duration)
        scaleAnimation(second.scale, delay: second.delay, duration: second.duration)
    }
    
    /// Applies a Scaling with Spring Animation.
    ///
    /// - Parameters:
    ///     - scale: The target scale
    ///     - delay: Amount of time to wait before applying
    ///     - duration: The length of the animation
    ///     - completion: Callback to be executed on completion.
    ///
    private func scaleAnimation(scale: CGFloat, delay: NSTimeInterval, duration: NSTimeInterval, completion: (Bool -> Void)? = nil) {
        let damping         = CGFloat(0.3)
        let velocity        = CGFloat(0.1)
        
        let animations = {
            self.transform  = CGAffineTransformMakeScale(scale, scale)
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
    public func displayImageWithSpringAnimation(newImage: UIImage) {

        let duration        = 0.5
        let delay           = 0.2
        let damping         = CGFloat(0.7)
        let velocity        = CGFloat(0.5)
        let scaleInitial    = CGFloat(0.0)
        let scaleFinal      = CGFloat(1.0)

        image               = newImage
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
    public func displayImageWithFadeInAnimation(newImage: UIImage) {

        let duration        = 0.3
        let alphaInitial    = CGFloat(0.5)
        let alphaFinal      = CGFloat(1.0)

        image               = newImage;
        alpha               = alphaInitial
        
        UIView.animateWithDuration(duration) { [weak self] in
            self?.alpha = alphaFinal
        }
    }
}
