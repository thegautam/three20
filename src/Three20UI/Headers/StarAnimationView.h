//
//  StarAnimationView.h
//  Three20UI
//
//  Created by Gautam Kedia on 1/9/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ProgressViewDelegate.h"

@interface StarAnimationView : UIView {
  id<ProgressStarViewDelegate> delegate;
}

+ (void)drawStarAtCenter:(CGPoint)center withRadius:(float)r asGhost:(BOOL)ghost;
@property (assign) id<ProgressStarViewDelegate> delegate;

@end
