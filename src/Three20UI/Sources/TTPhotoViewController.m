//
// Copyright 2009-2011 Facebook
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import "Three20UI/TTPhotoViewController.h"

// UI
#import "Three20UI/TTNavigator.h"
#import "Three20UI/TTThumbsViewController.h"
#import "Three20UI/TTNavigationController.h"
#import "Three20UI/TTPhotoSource.h"
#import "Three20UI/TTPhoto.h"
#import "Three20UI/TTPhotoView.h"
#import "Three20UI/TTActivityLabel.h"
#import "Three20UI/TTScrollView.h"
#import "Three20UI/UIViewAdditions.h"
#import "Three20UI/UINavigationControllerAdditions.h"
#import "Three20UI/UIToolbarAdditions.h"
#import "Three20UI/FaceView.h"

// UINavigator
#import "Three20UINavigator/TTGlobalNavigatorMetrics.h"
#import "Three20UINavigator/TTURLObject.h"
#import "Three20UINavigator/TTURLMap.h"
#import "Three20UINavigator/TTBaseNavigationController.h"

// UICommon
#import "Three20UICommon/TTGlobalUICommon.h"
#import "Three20UICommon/UIViewControllerAdditions.h"

// Style
#import "Three20Style/TTGlobalStyle.h"
#import "Three20Style/TTDefaultStyleSheet.h"

// Network
#import "Three20Network/TTGlobalNetwork.h"
#import "Three20Network/TTURLCache.h"

// Core
#import "Three20Core/TTCorePreprocessorMacros.h"
#import "Three20Core/TTGlobalCoreLocale.h"

// Audio
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>

// Quartz
#import "QuartzCore/QuartzCore.h"

static const NSTimeInterval kPhotoLoadLongDelay   = 0.5;
static const NSTimeInterval kPhotoLoadShortDelay  = 0.25;
static const NSTimeInterval kSlideshowInterval    = 2;
static const NSInteger kActivityLabelTag          = 96;

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@implementation TTPhotoViewController

@synthesize centerPhoto       = _centerPhoto;
@synthesize centerPhotoIndex  = _centerPhotoIndex;
@synthesize defaultImage      = _defaultImage;
@synthesize captionStyle      = _captionStyle;
@synthesize photoSource       = _photoSource;


///////////////////////////////////////////////////////////////////////////////////////////////////
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    self.navigationItem.backBarButtonItem =
      [[[UIBarButtonItem alloc]
        initWithTitle:
        TTLocalizedString(@"Photo",
                          @"Title for back button that returns to photo browser")
        style: UIBarButtonItemStylePlain
        target: nil
        action: nil] autorelease];

    self.statusBarStyle = UIStatusBarStyleBlackTranslucent;
    self.navigationBarStyle = UIBarStyleBlackTranslucent;
    self.navigationBarTintColor = nil;
    self.wantsFullScreenLayout = YES;
    self.hidesBottomBarWhenPushed = YES;

    self.defaultImage = TTIMAGE(@"bundle://Three20.bundle/images/photoDefault.png");
  }

  return self;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (id)initWithPhoto:(id<TTPhoto>)photo {
	self = [self initWithNibName:nil bundle:nil];
  if (self) {
    self.centerPhoto = photo;
  }

  return self;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (id)initWithPhotoSource:(id<TTPhotoSource>)photoSource {
	self = [self initWithNibName:nil bundle:nil];
  if (self) {
    self.photoSource = photoSource;
  }

  return self;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (id)init {
	self = [self initWithNibName:nil bundle:nil];
  if (self) {
  }

  return self;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)dealloc {
  _thumbsController.delegate = nil;
  TT_INVALIDATE_TIMER(_slideshowTimer);
  TT_INVALIDATE_TIMER(_loadTimer);
  TT_RELEASE_SAFELY(_thumbsController);
  TT_RELEASE_SAFELY(_centerPhoto);
  TT_RELEASE_SAFELY(_photoSource);
  TT_RELEASE_SAFELY(_statusText);
  TT_RELEASE_SAFELY(_captionStyle);
  TT_RELEASE_SAFELY(_defaultImage);
  TT_RELEASE_SAFELY(_player)
  [super dealloc];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Private


///////////////////////////////////////////////////////////////////////////////////////////////////
- (TTPhotoView*)centerPhotoView {
  return (TTPhotoView*)_scrollView.centerPage;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)loadImageDelayed {
  _loadTimer = nil;
  [self.centerPhotoView loadImage];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)startImageLoadTimer:(NSTimeInterval)delay {
  [_loadTimer invalidate];
  _loadTimer = [NSTimer scheduledTimerWithTimeInterval:delay
                                                target:self
                                              selector:@selector(loadImageDelayed)
                                              userInfo:nil
                                               repeats:NO];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)cancelImageLoadTimer {
  [_loadTimer invalidate];
  _loadTimer = nil;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)loadImages {
  TTPhotoView* centerPhotoView = self.centerPhotoView;
  for (TTPhotoView* photoView in _scrollView.visiblePages.objectEnumerator) {
    if (photoView == centerPhotoView) {
      [photoView loadPreview:NO];

    } else {
      [photoView loadPreview:YES];
    }
  }

  if (_delayLoad) {
    _delayLoad = NO;
    [self startImageLoadTimer:kPhotoLoadLongDelay];

  } else {
    [centerPhotoView loadImage];
  }
    //to store previous index of the photo
    [_photoSource updatePreviousIndex:_centerPhotoIndex];

}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)animateStar {
  // Bounces the star back to the center.
  CALayer *welcomeLayer = _starAnimationView.layer;

  // Create a keyframe animation to follow a path back to the center.
  CAKeyframeAnimation *bounceAnimation = [CAKeyframeAnimation animationWithKeyPath:@"position"];
  bounceAnimation.removedOnCompletion = NO;

  CGFloat animationDuration = 0.5;

  // Create the path for the bounces.
  CGMutablePathRef thePath = CGPathCreateMutable();

  CGFloat midX = _progressStarView.center.x;
  CGFloat midY = _progressStarView.center.y;
  CGFloat originalOffsetX = _starAnimationView.center.x - midX;
  CGFloat originalOffsetY = _starAnimationView.center.y - midY;
  CGFloat offsetDivider = 4.0;

  BOOL stopBouncing = NO;

  // Start the path at the star's current location.
  CGPathMoveToPoint(thePath, NULL, _starAnimationView.center.x, _starAnimationView.center.y);
  CGPathAddLineToPoint(thePath, NULL, midX, midY);

  // Add to the bounce path in decreasing excursions from the center.
  while (stopBouncing != YES) {
    CGPathAddLineToPoint(thePath, NULL,
        midX + originalOffsetX/offsetDivider, midY + originalOffsetY/offsetDivider);
    CGPathAddLineToPoint(thePath, NULL, midX, midY);

    offsetDivider += 4;
    animationDuration += 1/offsetDivider;
    if ((abs(originalOffsetX/offsetDivider) < 6) && (abs(originalOffsetY/offsetDivider) < 6)) {
      stopBouncing = YES;
    }
  }

  bounceAnimation.path = thePath;
  bounceAnimation.duration = animationDuration;
  CGPathRelease(thePath);

  // Create a basic animation to restore the size of the view.
  CABasicAnimation *transformAnimation = [CABasicAnimation animationWithKeyPath:@"transform"];
  transformAnimation.removedOnCompletion = YES;
  transformAnimation.duration = animationDuration;
  transformAnimation.toValue = [NSValue valueWithCGRect:CGRectMake(0, 0, 20, 20)];

  // Create an animation group to combine the keyframe and basic animations.
  CAAnimationGroup *theGroup = [CAAnimationGroup animation];

  // Set self as the delegate to allow for a callback to reenable user interaction.
  theGroup.delegate = self;
  theGroup.duration = animationDuration;
  theGroup.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
  theGroup.animations = [NSArray arrayWithObjects:transformAnimation, bounceAnimation, nil];

  // Add the animation group to the layer.
  [welcomeLayer addAnimation:theGroup forKey:@"animatestarAnimationViewToCenter"];

  // Set the view's center and transformation to the original values
  // in preparation for the end of the animation.
  _starAnimationView.center = _progressStarView.center;
  _starAnimationView.transform = CGAffineTransformIdentity;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)updateChrome {
  if (_photoSource.numberOfPhotos < 2) {
    self.title = _photoSource.title;

  } else {
    self.title = [NSString stringWithFormat:
                  TTLocalizedString(@"%d of %d", @"Current page in photo browser (1 of 10)"),
                  _centerPhotoIndex+1, _photoSource.numberOfPhotos];
  }

  if (![self.ttPreviousViewController isKindOfClass:[TTThumbsViewController class]]) {
    if (_photoSource.numberOfPhotos > 1) {
        UIBarButtonItem *segmentBarButtonItem =
        [[UIBarButtonItem alloc] initWithCustomView:_segmentedControl];

        self.navigationItem.rightBarButtonItem = segmentBarButtonItem;
        [segmentBarButtonItem release];
    }

    else {
      self.navigationItem.rightBarButtonItem = nil;
    }

  } else {
    self.navigationItem.rightBarButtonItem = nil;
  }

  BOOL nextEnabled = _centerPhotoIndex >= 0 && _centerPhotoIndex < _photoSource.numberOfPhotos-1;
  [_segmentedControl setEnabled:_centerPhotoIndex > 0 forSegmentAtIndex:0];
  [_segmentedControl setEnabled:nextEnabled forSegmentAtIndex:1];

  // Reset the animation frame position.
  _starAnimationView.frame = _starAnimationFrame;

  // Refresh the animation and progress views.
  [_starAnimationView setNeedsDisplay];
  [_progressStarView setNeedsDisplay];

  // Animate.
  [self animateStar];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)updateToolbarWithOrientation:(UIInterfaceOrientation)interfaceOrientation {
  _toolbar.height = TTToolbarHeight();
  _toolbar.top = self.view.height - _toolbar.height;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)updatePhotoView {
  _scrollView.centerPageIndex = _centerPhotoIndex;
  [self loadImages];
  [self updateChrome];
  [self playSound:_centerPhotoIndex];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)moveToPhoto:(id<TTPhoto>)photo {
  id<TTPhoto> previousPhoto = [_centerPhoto autorelease];
  _centerPhoto = [photo retain];
  [self didMoveToPhoto:_centerPhoto fromPhoto:previousPhoto];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)moveToPhotoAtIndex:(NSInteger)photoIndex withDelay:(BOOL)withDelay {
  _centerPhotoIndex = photoIndex == TT_NULL_PHOTO_INDEX ? 0 : photoIndex;
  [self moveToPhoto:[_photoSource photoAtIndex:_centerPhotoIndex]];
  _delayLoad = withDelay;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)showPhoto:(id<TTPhoto>)photo inView:(TTPhotoView*)photoView {
  photoView.photo = photo;
  if (!photoView.photo && _statusText) {
    [photoView showStatus:_statusText];
  }
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)updateVisiblePhotoViews {
  [self moveToPhoto:[_photoSource photoAtIndex:_centerPhotoIndex]];

  NSDictionary* photoViews = _scrollView.visiblePages;
  for (NSNumber* key in photoViews.keyEnumerator) {
    TTPhotoView* photoView = [photoViews objectForKey:key];
    [photoView showProgress:-1];

    id<TTPhoto> photo = [_photoSource photoAtIndex:key.intValue];
    [self showPhoto:photo inView:photoView];
  }
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)resetVisiblePhotoViews {
  NSDictionary* photoViews = _scrollView.visiblePages;
  for (TTPhotoView* photoView in photoViews.objectEnumerator) {
    if (!photoView.isLoading) {
      [photoView showProgress:-1];
    }
  }
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL)isShowingChrome {
  UINavigationBar* bar = self.navigationController.navigationBar;
  return bar ? bar.alpha != 0 : 1;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (TTPhotoView*)statusView {
  if (!_photoStatusView) {
    _photoStatusView = [[TTPhotoView alloc] initWithFrame:_scrollView.frame];
    _photoStatusView.defaultImage = _defaultImage;
    _photoStatusView.photo = nil;
    [_innerView addSubview:_photoStatusView];
  }

  return _photoStatusView;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)showProgress:(CGFloat)progress {
  if ((self.hasViewAppeared || self.isViewAppearing) && progress >= 0 && !self.centerPhotoView) {
    [self.statusView showProgress:progress];
    self.statusView.hidden = NO;

  } else {
    _photoStatusView.hidden = YES;
  }
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)showStatus:(NSString*)status {
  [_statusText release];
  _statusText = [status retain];

  if ((self.hasViewAppeared || self.isViewAppearing) && status && !self.centerPhotoView) {
    [self.statusView showStatus:status];
    self.statusView.hidden = NO;

  } else {
    _photoStatusView.hidden = YES;
  }
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)showCaptions:(BOOL)show {
  for (TTPhotoView* photoView in _scrollView.visiblePages.objectEnumerator) {
    photoView.hidesCaption = !show;
  }
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (NSString*)URLForThumbnails {
  if ([self.photoSource respondsToSelector:@selector(URLValueWithName:)]) {
    return [self.photoSource performSelector:@selector(URLValueWithName:)
                                  withObject:@"TTThumbsViewController"];

  } else {
    return nil;
  }
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)showThumbnails {
  NSString* URL = [self URLForThumbnails];
  if (!_thumbsController) {
    if (URL) {
      // The photo source has a URL mapping in TTURLMap, so we use that to show the thumbs
      NSDictionary* query = [NSDictionary dictionaryWithObject:self forKey:@"delegate"];
      TTBaseNavigator* navigator = [TTBaseNavigator navigatorForView:self.view];
      _thumbsController = [[navigator viewControllerForURL:URL query:query] retain];
      [navigator.URLMap setObject:_thumbsController forURL:URL];

    } else {
      // The photo source had no URL mapping in TTURLMap, so we let the subclass show the thumbs
      _thumbsController = [[self createThumbsViewController] retain];
      _thumbsController.photoSource = _photoSource;
    }
  }

  if (URL) {
    TTOpenURLFromView(URL, self.view);

  } else {
    if ([self.navigationController isKindOfClass:[TTNavigationController class]]) {
      [(TTNavigationController*)self.navigationController
           pushViewController: _thumbsController
       animatedWithTransition: UIViewAnimationTransitionCurlDown];

    } else {
      [self.navigationController pushViewController:_thumbsController animated:YES];
    }
  }
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)slideshowTimer {
  if (_centerPhotoIndex == _photoSource.numberOfPhotos-1) {
    _scrollView.centerPageIndex = 0;

  } else {
    _scrollView.centerPageIndex = _centerPhotoIndex+1;
  }
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)playAction {
  if (!_slideshowTimer) {
    UIBarButtonItem* pauseButton =
      [[[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemPause
                                                     target: self
                                                     action: @selector(pauseAction)]
       autorelease];
    pauseButton.tag = 1;

    [_toolbar replaceItemWithTag:1 withItem:pauseButton];

    _slideshowTimer = [NSTimer scheduledTimerWithTimeInterval:kSlideshowInterval
                                                       target:self
                                                     selector:@selector(slideshowTimer)
                                                     userInfo:nil
                                                      repeats:YES];
  }
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)pauseAction {
  if (_slideshowTimer) {
    UIBarButtonItem* playButton =
      [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay
                                                     target:self
                                                     action:@selector(playAction)]
       autorelease];
    playButton.tag = 1;

    [_toolbar replaceItemWithTag:1 withItem:playButton];

    [_slideshowTimer invalidate];
    _slideshowTimer = nil;
  }
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)nextAction {
  [self pauseAction];
  if (_centerPhotoIndex < _photoSource.numberOfPhotos-1) {
    _scrollView.centerPageIndex = _centerPhotoIndex+1;
  }
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)previousAction {
  [self pauseAction];
  if (_centerPhotoIndex > 0) {
    _scrollView.centerPageIndex = _centerPhotoIndex-1;
  }
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)segmentAction:(id)sender {
  UISegmentedControl *segmentedControl = (UISegmentedControl *)sender;
  if (segmentedControl.selectedSegmentIndex == 0) {
    [self previousAction];
  }
  else if (segmentedControl.selectedSegmentIndex == 1) {
    [self nextAction];
  }
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)showBarsAnimationDidStop {
  // Hack to prevent hiding of navigation bar by status bar.
  self.navigationController.navigationBarHidden = YES;
  self.navigationController.navigationBarHidden = NO;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)hideBarsAnimationDidStop {
  self.navigationController.navigationBarHidden = YES;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark UIViewController


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)loadView {
  CGRect screenFrame = [UIScreen mainScreen].bounds;
  self.view = [[[UIView alloc] initWithFrame:screenFrame] autorelease];

  CGRect innerFrame = CGRectMake(0, 0,
                                 screenFrame.size.width, screenFrame.size.height);
  _innerView = [[UIView alloc] initWithFrame:innerFrame];
  _innerView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
  [self.view addSubview:_innerView];

  _faceView = [[FaceView alloc] initWithFrame:screenFrame];
  [_innerView addSubview:_faceView];

  int starViewHeight = 16;
  int progressFrameY = screenFrame.size.height - starViewHeight;
  CGRect progressFrame = CGRectMake(0, progressFrameY, screenFrame.size.width, starViewHeight);
  _progressView = [[UIImageView alloc] initWithImage:
                   TTIMAGE(@"bundle://Three20.bundle/images/wood.png")];
  _progressView.frame = progressFrame;
  [_innerView addSubview:_progressView];

  _progressStarView = [[ProgressStarView alloc] initWithFrame:progressFrame];
  _progressStarView.delegate = self;
  [_innerView addSubview:_progressStarView];

  // Animation view for stars.
  int starAnimationFrameY = screenFrame.size.height - (starViewHeight * 3);
  _starAnimationFrame = CGRectMake(0, starAnimationFrameY, screenFrame.size.width, starViewHeight);
  _starAnimationView = [[StarAnimationView alloc] initWithFrame:_starAnimationFrame];
  _starAnimationView.delegate = self;
  [_innerView addSubview:_starAnimationView];


  _scrollView = [[TTScrollView alloc] initWithFrame:screenFrame];
  _scrollView.delegate = self;
  _scrollView.dataSource = self;
  _scrollView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0];
  _scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
  [_innerView addSubview:_scrollView];

  _segmentedControl = [[UISegmentedControl alloc] initWithItems:
    [NSArray arrayWithObjects:
      TTIMAGE(@"bundle://Three20.bundle/images/previousIcon.png"),
      TTIMAGE(@"bundle://Three20.bundle/images/nextIcon.png"),
      nil]];
  _segmentedControl.frame = CGRectMake(0, 0, 90, 30);
  _segmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
  _segmentedControl.momentary = YES;
  [_segmentedControl addTarget:self action:@selector(segmentAction:)
    forControlEvents:UIControlEventValueChanged];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)viewDidUnload {
  [super viewDidUnload];
  _scrollView.delegate = nil;
  _scrollView.dataSource = nil;
  TT_RELEASE_SAFELY(_innerView);
  TT_RELEASE_SAFELY(_scrollView);
  TT_RELEASE_SAFELY(_faceView);
  TT_RELEASE_SAFELY(_progressView);
  TT_RELEASE_SAFELY(_progressStarView);
  TT_RELEASE_SAFELY(_starAnimationView);
  TT_RELEASE_SAFELY(_segmentedControl);
  TT_RELEASE_SAFELY(_photoStatusView);
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  [self updateToolbarWithOrientation:self.interfaceOrientation];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];

  [_scrollView cancelTouches];
  [self pauseAction];
  if (self.nextViewController) {
    [self showBars:YES animated:NO];
  }
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
  return TTIsSupportedOrientation(interfaceOrientation);
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
                                         duration:(NSTimeInterval)duration {
  [super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
  [self updateToolbarWithOrientation:toInterfaceOrientation];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (UIView *)rotatingFooterView {
  return _toolbar;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark UIViewController (TTCategory)


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)showBars:(BOOL)show animated:(BOOL)animated {
  [super showBars:show animated:animated];

  CGFloat alpha = show ? 1 : 0;
  if (alpha == _toolbar.alpha)
    return;

  if (animated) {
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:TT_TRANSITION_DURATION];
    [UIView setAnimationDelegate:self];
    if (show) {
      [UIView setAnimationDidStopSelector:@selector(showBarsAnimationDidStop)];

    } else {
      [UIView setAnimationDidStopSelector:@selector(hideBarsAnimationDidStop)];
    }

  } else {
    if (show) {
      [self showBarsAnimationDidStop];

    } else {
      [self hideBarsAnimationDidStop];
    }
  }

  [self showCaptions:show];

  _toolbar.alpha = alpha;

  if (animated) {
    [UIView commitAnimations];
  }
}


///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark TTModelViewController


///////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL)shouldLoad {
  return NO;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL)shouldLoadMore {
  return !_centerPhoto;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL)canShowModel {
  return _photoSource.numberOfPhotos > 0;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)didRefreshModel {
  [super didRefreshModel];
  [self updatePhotoView];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)didLoadModel:(BOOL)firstTime {
  [super didLoadModel:firstTime];
  if (firstTime) {
    [self updatePhotoView];
  }
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)showLoading:(BOOL)show {
  [self showProgress:show ? 0 : -1];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)showEmpty:(BOOL)show {
  if (show) {
    [_scrollView reloadData];
    [self showStatus:TTLocalizedString(@"This photo set contains no photos.", @"")];

  } else {
    [self showStatus:nil];
  }
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)showError:(BOOL)show {
  if (show) {
    [self showStatus:TTDescriptionForError(_modelError)];

  } else {
    [self showStatus:nil];
  }
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)moveToNextValidPhoto {
  if (_centerPhotoIndex >= _photoSource.numberOfPhotos) {
    // We were positioned at an index that is past the end, so move to the last photo
    [self moveToPhotoAtIndex:_photoSource.numberOfPhotos - 1 withDelay:NO];

  } else {
    [self moveToPhotoAtIndex:_centerPhotoIndex withDelay:NO];
  }
}


///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark TTModelDelegate


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)modelDidFinishLoad:(id<TTModel>)model {
  if (model == _model) {
    if (_centerPhotoIndex >= _photoSource.numberOfPhotos) {
      [self moveToNextValidPhoto];
      [_scrollView reloadData];
      [self resetVisiblePhotoViews];

    } else {
      [self updateVisiblePhotoViews];
    }
  }
  [super modelDidFinishLoad:model];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)model:(id<TTModel>)model didFailLoadWithError:(NSError*)error {
  if (model == _model) {
    [self resetVisiblePhotoViews];
  }
  [super model:model didFailLoadWithError:error];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)modelDidCancelLoad:(id<TTModel>)model {
  if (model == _model) {
    [self resetVisiblePhotoViews];
  }
  [super modelDidCancelLoad:model];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)model:(id<TTModel>)model didUpdateObject:(id)object atIndexPath:(NSIndexPath*)indexPath {
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)model:(id<TTModel>)model didInsertObject:(id)object atIndexPath:(NSIndexPath*)indexPath {
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)model:(id<TTModel>)model didDeleteObject:(id)object atIndexPath:(NSIndexPath*)indexPath {
  if (object == self.centerPhoto) {
    [self showActivity:nil];
    [self moveToNextValidPhoto];
    [_scrollView reloadData];
    [self refresh];
  }
}


///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark TTScrollViewDelegate


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)scrollView:(TTScrollView*)scrollView didMoveToPageAtIndex:(NSInteger)pageIndex {
  if (pageIndex != _centerPhotoIndex) {
    [self moveToPhotoAtIndex:pageIndex withDelay:YES];
    [self refresh];
  }
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)scrollViewWillBeginDragging:(TTScrollView *)scrollView {
  [self cancelImageLoadTimer];
  [self showCaptions:NO];
  [self showBars:NO animated:YES];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)scrollViewDidEndDecelerating:(TTScrollView*)scrollView {
  [self startImageLoadTimer:kPhotoLoadShortDelay];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)scrollViewWillRotate:(TTScrollView*)scrollView
               toOrientation:(UIInterfaceOrientation)orientation {
  self.centerPhotoView.hidesExtras = YES;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)scrollViewDidRotate:(TTScrollView*)scrollView {
  self.centerPhotoView.hidesExtras = NO;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL)scrollViewShouldZoom:(TTScrollView*)scrollView {
  return self.centerPhotoView.image != self.centerPhotoView.defaultImage;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)scrollViewDidBeginZooming:(TTScrollView*)scrollView {
  self.centerPhotoView.hidesExtras = YES;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)scrollViewDidEndZooming:(TTScrollView*)scrollView {
  self.centerPhotoView.hidesExtras = NO;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)scrollView:(TTScrollView*)scrollView tapped:(UITouch*)touch {
  if ([self isShowingChrome]) {
    [self showBars:NO animated:YES];

  } else {
    [self showBars:YES animated:NO];
  }
}


///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark TTScrollViewDataSource


///////////////////////////////////////////////////////////////////////////////////////////////////
- (NSInteger)numberOfPagesInScrollView:(TTScrollView*)scrollView {
  return _photoSource.numberOfPhotos;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (UIView*)scrollView:(TTScrollView*)scrollView pageAtIndex:(NSInteger)pageIndex {
  TTPhotoView* photoView = (TTPhotoView*)[_scrollView dequeueReusablePage];
  if (!photoView) {
    photoView = [self createPhotoView];
    photoView.captionStyle = _captionStyle;
    photoView.defaultImage = _defaultImage;
    photoView.hidesCaption = _toolbar.alpha == 0;
  }

  id<TTPhoto> photo = [_photoSource photoAtIndex:pageIndex];
  [self showPhoto:photo inView:photoView];

  return photoView;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (CGSize)scrollView:(TTScrollView*)scrollView sizeOfPageAtIndex:(NSInteger)pageIndex {
  id<TTPhoto> photo = [_photoSource photoAtIndex:pageIndex];
  return photo ? photo.size : CGSizeZero;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark TTThumbsViewControllerDelegate


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)thumbsViewController:(TTThumbsViewController*)controller didSelectPhoto:(id<TTPhoto>)photo {
  self.centerPhoto = photo;

  if ([self.navigationController isKindOfClass:[TTBaseNavigationController class]]) {
    [(TTBaseNavigationController*)self.navigationController
     popViewControllerAnimatedWithTransition:UIViewAnimationTransitionCurlUp];

  } else {
    [self.navigationController popViewControllerAnimated:YES];
  }
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL)thumbsViewController:(TTThumbsViewController*)controller
       shouldNavigateToPhoto:(id<TTPhoto>)photo {
  return NO;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Public


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setPhotoSource:(id<TTPhotoSource>)photoSource {
  if (_photoSource != photoSource) {
    [_photoSource release];
    _photoSource = [photoSource retain];

    [self moveToPhotoAtIndex:0 withDelay:NO];
    self.model = _photoSource;
  }
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setCenterPhoto:(id<TTPhoto>)photo {
  if (_centerPhoto != photo) {
    if (photo.photoSource != _photoSource) {
      [_photoSource release];
      _photoSource = [photo.photoSource retain];

      [self moveToPhotoAtIndex:photo.index withDelay:NO];
      self.model = _photoSource;

    } else {
      [self moveToPhotoAtIndex:photo.index withDelay:NO];
      [self refresh];
    }
  }
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (TTPhotoView*)createPhotoView {
  return [[[TTPhotoView alloc] init] autorelease];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (TTThumbsViewController*)createThumbsViewController {
  return [[[TTThumbsViewController alloc] initWithDelegate:self] autorelease];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)didMoveToPhoto:(id<TTPhoto>)photo fromPhoto:(id<TTPhoto>)fromPhoto {
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)showActivity:(NSString*)title {
  if (title) {
    TTActivityLabel* label = [[[TTActivityLabel alloc]
                               initWithStyle:TTActivityLabelStyleBlackBezel] autorelease];
    label.tag = kActivityLabelTag;
    label.text = title;
    label.frame = _scrollView.frame;
    [_innerView addSubview:label];

    _scrollView.scrollEnabled = NO;

  } else {
    UIView* label = [_innerView viewWithTag:kActivityLabelTag];
    if (label) {
      [label removeFromSuperview];
    }

    _scrollView.scrollEnabled = YES;
  }
}

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark ProgressStarViewDelegate


///////////////////////////////////////////////////////////////////////////////////////////////////
- (int)totalCount {
    return _photoSource.numberOfPhotos;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (int)progressCount {
    return _centerPhotoIndex + 1;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)playSound:(NSInteger)currentIndex {

    NSURL *voice = [_photoSource voiceAtIndex:currentIndex];

    if (!_player) {
      _player = [[AVAudioPlayer alloc] init];
    }
    else
    {
      if ([_player isPlaying])
      {
          [_player stop];
      }
    }

    NSError *error;
    if (![_player initWithContentsOfURL:voice error:&error])
    {
      NSLog(@"Can't play %@ %@", [voice path], [error localizedDescription]);
    }
    else
    {
      [_player play];
    }
}

///////////////////////////////////////////////////////////////////////////////////////////////////

@end
