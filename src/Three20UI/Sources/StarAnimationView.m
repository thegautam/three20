//
//  StarAnimationView.m
//  Three20UI
//
//  Created by Gautam Kedia on 1/9/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "StarAnimationView.h"


@implementation StarAnimationView

@synthesize delegate;

+ (void)drawStarAtCenter:(CGPoint)center withRadius:(float)r asGhost:(BOOL)ghost {
  
  CGContextRef context = UIGraphicsGetCurrentContext();
  CGContextBeginPath(context);
  float size = -1 * r;
  
  // Add a star to the current path
  CGContextMoveToPoint(context, center.x, center.y + size);
  for(float i = 1; i < 12; ++i) {
    float s = (fmodf(i, 2.0) == 0.0) ? size : size / 2;
    CGFloat x = s * sinf(i * M_PI / 5.0);
    CGFloat y = s * cosf(i * M_PI / 5.0);
    CGContextAddLineToPoint(context, center.x + x, center.y + y);
  }

  if (ghost) {
    [[UIColor darkGrayColor] setStroke];
    CGContextDrawPath(context, kCGPathStroke); 
  }
  else {
    [[UIColor colorWithRed:1 green:215.0/255 blue:0 alpha:1] setFill];
    [[UIColor colorWithRed:215.0/255 green:175.0/255 blue:55.0/255 alpha:1] 
      setStroke];
    CGContextDrawPath(context, kCGPathFillStroke); 
  }
}

- (id)initWithFrame:(CGRect)frame {
  if ((self = [super initWithFrame:frame])) {
    self.backgroundColor = [UIColor clearColor];
    self.clearsContextBeforeDrawing = YES;
  }
  return self;
}


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
  int max = delegate.totalCount;
  float x = rect.size.width / max;
  float y = rect.size.height / 2;
  float r = (x/2 < y) ? x/2 : y;
  r = r - 1.5;

  [StarAnimationView drawStarAtCenter:CGPointMake((delegate.progressCount - 0.5) * x, y) withRadius:r asGhost:NO];
}

- (void)dealloc {
  [super dealloc];
}

@end
