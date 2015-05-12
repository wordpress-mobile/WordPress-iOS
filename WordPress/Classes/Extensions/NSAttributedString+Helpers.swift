import Foundation


extension NSAttributedString
{
    /**
        Note:
        This method will embed a collection of assets, in the specified NSRange's. Since NSRange is an ObjC struct,
        you'll need to wrap it up into a NSValue instance!
    */
    public func stringByEmbeddingImageAttachments(embeds: [NSValue: UIImage]?) -> NSAttributedString {
        // Allow nil embeds: behave as a simple NO-OP
        if embeds == nil {
            return self
        }
        
        // Proceed embedding!
        let unwrappedEmbeds = embeds!
        let theString       = self.mutableCopy() as! NSMutableAttributedString
        var rangeDelta      = 0
        
        for (value, image) in unwrappedEmbeds {
            let imageAttachment     = NSTextAttachment()
            imageAttachment.bounds  = CGRect(origin: CGPointZero, size: image.size)
            imageAttachment.image   = image
            
            // Each embed is expected to add 1 char to the string. Compensate for that
            let attachmentString    = NSAttributedString(attachment: imageAttachment)
            var correctedRange      = value.rangeValue
            correctedRange.location += rangeDelta
            
            // Bounds Safety
            let lastPosition        = correctedRange.location + correctedRange.length
            if lastPosition <= theString.length {
                theString.replaceCharactersInRange(correctedRange, withAttributedString: attachmentString)
            }
            
            rangeDelta += attachmentString.length

        }
        
        return theString
    }
}
