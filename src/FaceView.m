//
//  FaceView.m
//  Happiness
//
//  Created by Gautam Kedia on 5/2/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//
#define pi 3.1417
#define R ((double)random()/(uint)(1<<32-1))

#import "FaceView.h"

@implementation FaceView

@synthesize delegate;

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        // Initialization code
    }
    return self;
}

- (void)drawCirclesAtBound:(CGRect)rect withRadius:(CGFloat)r {

	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextBeginPath(context);
	
	for (int i=0; i<100; i++) {
		NSLog(@"Random %g", R);
		CGFloat x = rect.origin.x + rect.size.width * R;
		CGFloat y = rect.origin.y + rect.size.height * R;		
		CGContextAddArc(context, x, y, r * R, 0, pi*2, 1);
		UIColor *c = [UIColor colorWithRed:R green:R blue:R alpha:R];

		if (R > 0.5) {
			[c setFill];
			CGContextFillPath(context);
		}
		else {
			[c setStroke];
			CGContextSetLineWidth(context, 10 * R);
			CGContextStrokePath(context);
		}
	}
}

- (void)drawRect:(CGRect)rect {
	[self drawCirclesAtBound:self.bounds withRadius:80];
}


- (void)dealloc {
    [super dealloc];
}


@end
