//
//  ProgressStarView.m
//  Happiness
//
//  Created by Gautam Kedia on 5/16/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "ProgressStarView.h"


@implementation ProgressStarView

@synthesize delegate;

- (void)drawStarAtCenter:(CGPoint)center withRadius:(float)r asGhost:(BOOL)ghost {
  
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextBeginPath(context);
  float size = -1 * r;
  
  	// Add a star to the current path
	CGContextMoveToPoint(context, center.x, center.y + size);
	for(float i = 1; i < 12; ++i)
	{
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
    if (self = [super initWithFrame:frame]) {
      self.clearsContextBeforeDrawing = YES;
      self.opaque = NO;
    }
    return self;
}


- (void)drawRect:(CGRect)rect {
  int max = delegate.totalCount;
  float x = rect.size.width / max;
  float y = rect.size.height / 2;
  float r = (x/2 < y) ? x/2 : y;
  r = r - 1.5;
  for (float i = 0.5; i < max; i++) {
    if (i < delegate.progressCount) {
      [self drawStarAtCenter:CGPointMake(i*x, y) withRadius:r asGhost:NO];
    }
    else {
      [self drawStarAtCenter:CGPointMake(i*x, y) withRadius:r asGhost:YES];
    }
  }
}


- (void)dealloc {
    [super dealloc];
}


@end
