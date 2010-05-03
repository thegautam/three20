//
//  FaceView.h
//  Happiness
//
//  Created by Gautam Kedia on 5/2/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol FaceViewDelegate
@property (readonly) float happiness;
@end


@interface FaceView : UIView {
	id <FaceViewDelegate> delegate;
}

@property (assign) id <FaceViewDelegate> delegate;

@end
