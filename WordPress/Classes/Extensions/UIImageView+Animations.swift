import Foundation


extension UIImageView
{
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
        
        var animations = {
            self.transform  = CGAffineTransformMakeScale(scaleFinal, scaleFinal)
        }
        
        UIView.animateWithDuration(duration,
            delay:                  delay,
            usingSpringWithDamping: damping,
            initialSpringVelocity:  velocity,
            options:                nil,
            animations:             animations,
            completion:             nil
        )
    }

    public func displayImageWithFadeInAnimation(newImage: UIImage) {

        let duration        = 0.3
        let alphaInitial    = CGFloat(0.5)
        let alphaFinal      = CGFloat(1.0)

        image               = newImage;
        alpha               = alphaInitial
        
        UIView.animateWithDuration(duration) { [weak self] in
            if let weakSelf = self {
                self?.alpha = alphaFinal
            }
        }
    }
}
