//
//  ProgressStarView.h
//  Happiness
//
//  Created by Gautam Kedia on 5/16/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ProgressStarViewDelegate
@property (readonly) int progressCount;
@property (readonly) int totalCount;
@end


@interface ProgressStarView : UIView {
  id<ProgressStarViewDelegate> delegate;
}


@property (assign) id<ProgressStarViewDelegate> delegate; 

@end
