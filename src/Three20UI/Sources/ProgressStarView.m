//
//  ProgressStarView.m
//  Happiness
//
//  Created by Gautam Kedia on 5/16/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "ProgressStarView.h"
#import "StarAnimationView.h"

@implementation ProgressStarView

@synthesize delegate;

///////////////////////////////////////////////////////////////////////////////////////////////////
- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
      self.clearsContextBeforeDrawing = YES;
      self.opaque = NO;
    }
    return self;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)drawRect:(CGRect)rect {
  int max = delegate.totalCount;
  float x = rect.size.width / max;
  float y = rect.size.height / 2;
  float r = (x/2 < y) ? x/2 : y;
  r = r - 1.5;
  for (float i = 0.5; i < max; i++) {
    // One star behind because current star is being animated.
    if (i < delegate.progressCount - 1) {
      [StarAnimationView drawStarAtCenter:CGPointMake(i*x, y) withRadius:r asGhost:NO];
    }
    else {
      [StarAnimationView drawStarAtCenter:CGPointMake(i*x, y) withRadius:r asGhost:YES];
    }
  }
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)dealloc {
    [super dealloc];
}


@end
