MGImageUtilities
================

This is a demo project (for iPhone, but the code will work just fine on iPad too) showing two categories on UIImage, as described below.


UIImage+ProportionalFill
------------------------

This category lets you resize an arbitrary image to fit into an arbitrary size, using one of four resizing methods:

- Scale: scales the image proportionally to fit entirely into the required size.
- Crop: scales the image proportionally to completely fill the required size, cropping towards its center. This is the most useful method.
- Start: as for Crop, but crops towards the "start" of the image (the top or left, depending on relative aspect ratios).
- End: as for Crop, but crops towards the "end" of the image (the bottom or right, depending on relative aspect ratios).

This is very useful for caching on-screen-sized versions of images, and generating appropriate images for use on a Retina Display. The category will do the right thing based on the image's orientation metadata, and the scale factor of the device's main screen (i.e. it'll look sharp on high-resolution devices like an iPhone 4).


UIImage+Tint
------------

This category takes an image (presumably flat and solid-coloured, like a toolbar icon), and fills its non-transparent pixels with a given colour. You can optionally also specify a fractional opacity at which to composite the original image over the colour-filled region, to give a tinting effect.

This is very useful for generating multiple different-coloured versions of the same image, for example 'disabled' or 'highlighted' states of the same basic image, without having to make multiple different-coloured bitmap image files.


License
-------

The license for the code is included with this project; it's basically a BSD license with attribution.

I can't answer any questions about how to use the code, but I always welcome emails telling me that you're using it or just saying thanks. I hope you find it useful!


Cheers,  
Matt Legend Gemmell  
http://mattgemmell.com/  
