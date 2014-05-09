//
//  WPAnimatedImageResponseSerializer.h
//  WordPress
//
//  Created by Diego E. Rey Mendez on 5/9/14.
//  Copyright (c) 2014 WordPress. All rights reserved.
//

#import "AFURLResponseSerialization.h"

/**
 *	@brief		A custom response serializer to handle GIF animations.
 *	@details	The default serializer for AFNetworking does not contemplate animated images.  This
 *				class is a good replacement.  Most of its behaviour is inherited from
 *				AFImageResponseSerializer.
 */
@interface WPAnimatedImageResponseSerializer : AFImageResponseSerializer
@end
