//
//

#import "JDStatusBarNotificationViewController.h"

#import "JDStatusBarStyle.h"
#import "JDStatusBarView.h"
#import "JDStatusBarView_Private.h"
#import "UIApplication+MainWindow.h"

@interface JDStatusBarNotificationViewController () <
CAAnimationDelegate,
JDStatusBarViewDelegate
>
@end

@implementation JDStatusBarNotificationViewController {
  NSTimer *_dismissTimer;
  JDStatusBarNotificationViewControllerCompletion _dismissCompletionBlock;
  JDStatusBarNotificationViewControllerCompletion _animateInCompletionBlock;
}

- (instancetype)initWithStyle:(JDStatusBarStyle *)style {
  self = [super init];
  if (self) {
    _statusBarView = [[JDStatusBarView alloc] initWithStyle:style];
    _statusBarView.delegate = self;
  }
  return self;
}

- (void)loadView {
  [super loadView];

  self.view.backgroundColor = [UIColor clearColor];
  [self.view addSubview:_statusBarView];
}

#pragma mark - Presentation

- (JDStatusBarView *)presentWithText:(NSString *)text
                               style:(JDStatusBarStyle *)style
                          completion:(JDStatusBarNotificationViewControllerCompletion)completion {
  JDStatusBarView *topBar = _statusBarView;
  [topBar resetSubviewsIfNeeded];

  // update status & style
  [topBar setText:text];
  [topBar setStyle:style];

  // reset progress & activity
  [topBar setProgressBarPercentage:0.0];
  [topBar setDisplaysActivityIndicator:NO];

  // cancel previous dismissing & remove animations
  [_dismissTimer invalidate];
  _dismissTimer = nil;
  _dismissCompletionBlock = nil;
  _animateInCompletionBlock = nil;
  [topBar.layer removeAllAnimations];

  // prepare animation
  if (style.animationType == JDStatusBarAnimationTypeFade) {
    topBar.alpha = 0.0;
    topBar.transform = CGAffineTransformIdentity;
  } else {
    topBar.alpha = 1.0;
    topBar.transform = CGAffineTransformMakeTranslation(0, -topBar.frame.size.height);
  }

  // animate in
  BOOL animationsEnabled = (style.animationType != JDStatusBarAnimationTypeNone);
  if (animationsEnabled && style.animationType == JDStatusBarAnimationTypeBounce) {
    _animateInCompletionBlock = completion;
    [self animateInWithBounceAnimation];
  } else {
    [UIView animateWithDuration:(animationsEnabled ? 0.4 : 0.0) animations:^{
      topBar.alpha = 1.0;
      topBar.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
      if (completion) {
        completion();
      }
    }];
  }

  return topBar;
}

#pragma mark - JDStatusBarViewDelegate

- (void)statusBarViewDidPanToDismiss {
  [self dismissWithDuration:0.25 completion:nil];
}

#pragma mark - Dismissal

- (void)dismissAfterDelay:(NSTimeInterval)delay
             completion:(JDStatusBarNotificationViewControllerCompletion)completion {
  [_dismissTimer invalidate];

  _dismissCompletionBlock = [completion copy];
  _dismissTimer = [NSTimer scheduledTimerWithTimeInterval:delay
                                                   target:self
                                                 selector:@selector(dismissTimerFired:)
                                                 userInfo:nil
                                                  repeats:NO];
}

- (void)dismissTimerFired:(NSTimer *)timer {
  JDStatusBarNotificationViewControllerCompletion block = _dismissCompletionBlock;
  _dismissCompletionBlock = nil;
  [self dismissWithDuration:0.4 completion:block];
}

- (void)dismissWithDuration:(CGFloat)duration
                 completion:(JDStatusBarNotificationViewControllerCompletion)completion {
  [_dismissTimer invalidate];
  _dismissTimer = nil;

  // disable pan gesture
  JDStatusBarView *topBar = self.statusBarView;
  topBar.panGestureRecognizer.enabled = NO;

  // check animation type
  if (_statusBarView.style.animationType == JDStatusBarAnimationTypeNone) {
    duration = 0.0;
  }

  // animate out
  dispatch_block_t animation = ^{
    if (self->_statusBarView.style.animationType == JDStatusBarAnimationTypeFade) {
      topBar.alpha = 0.0;
    } else {
      topBar.transform = CGAffineTransformMakeTranslation(0, - topBar.frame.size.height);
    }
  };

  __weak __typeof(self) weakSelf = self;
  void(^animationCompletion)(BOOL) = ^(BOOL finished) {
    [weakSelf.delegate didDismissStatusBar];
    if (completion != nil) {
      completion();
    }
  };

  if (duration > 0.0) {
    [UIView animateWithDuration:duration animations:animation completion:animationCompletion];
  } else {
    animation();
    animationCompletion(YES);
  }
}

#pragma mark - Bounce Animation

- (void)animateInWithBounceAnimation {
  JDStatusBarView *topBar = self.statusBarView;

  // easing function (based on github.com/robb/RBBAnimation)
  CGFloat(^RBBEasingFunctionEaseOutBounce)(CGFloat) = ^CGFloat(CGFloat t) {
    if (t < 4.0 / 11.0) return pow(11.0 / 4.0, 2) * pow(t, 2);
    if (t < 8.0 / 11.0) return 3.0 / 4.0 + pow(11.0 / 4.0, 2) * pow(t - 6.0 / 11.0, 2);
    if (t < 10.0 / 11.0) return 15.0 /16.0 + pow(11.0 / 4.0, 2) * pow(t - 9.0 / 11.0, 2);
    return 63.0 / 64.0 + pow(11.0 / 4.0, 2) * pow(t - 21.0 / 22.0, 2);
  };

  // create values
  int fromCenterY = -topBar.bounds.size.height, toCenterY=0, animationSteps=200;
  NSMutableArray *values = [NSMutableArray arrayWithCapacity:animationSteps];
  for (int t = 1; t<=animationSteps; t++) {
    float easedTime = RBBEasingFunctionEaseOutBounce((t*1.0)/animationSteps);
    float easedValue = fromCenterY + easedTime * (toCenterY-fromCenterY);
    [values addObject:[NSValue valueWithCATransform3D:CATransform3DMakeTranslation(0, easedValue, 0)]];
  }

  // build animation
  CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
  animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
  animation.duration = 0.75;
  animation.values = values;
  animation.removedOnCompletion = NO;
  animation.fillMode = kCAFillModeForwards;
  animation.delegate = self;
  [topBar.layer setValue:@(toCenterY) forKeyPath:animation.keyPath];
  [topBar.layer addAnimation:animation forKey:@"JDBounceAnimation"];
}

#pragma mark - CAAnimationDelegate

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
  JDStatusBarView *topBar = self.statusBarView;
  topBar.transform = CGAffineTransformIdentity;
  [topBar.layer removeAllAnimations];

  if (_animateInCompletionBlock) {
    JDStatusBarNotificationViewControllerCompletion completion = _animateInCompletionBlock;
    _animateInCompletionBlock = nil;
    completion();
  }
}

#pragma mark - Rotation handling

- (BOOL)shouldAutorotate {
  return [[[UIApplication sharedApplication] jdsb_mainControllerIgnoringViewController:self] shouldAutorotate];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
  return [[[UIApplication sharedApplication] jdsb_mainControllerIgnoringViewController:self] supportedInterfaceOrientations];
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
  return [[[UIApplication sharedApplication] jdsb_mainControllerIgnoringViewController:self] preferredInterfaceOrientationForPresentation];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
  [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];

  [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
    [self.delegate animationsForViewTransitionToSize:size];
  } completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
    //
  }];
}

#pragma mark - System StatusBar Management

static BOOL JDUIViewControllerBasedStatusBarAppearanceEnabled() {
  static BOOL enabled = YES;
  static dispatch_once_t onceToken;

  dispatch_once(&onceToken, ^{
    NSNumber *value = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"UIViewControllerBasedStatusBarAppearance"];
    if (value != nil) {
      enabled = [value boolValue];
    }
  });

  return enabled;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
  switch (_statusBarView.style.systemStatusBarStyle) {
    case JDStatusBarSystemStyleDefault:
      return [self defaultStatusBarStyle];
    case JDStatusBarSystemStyleLightContent:
      return UIStatusBarStyleLightContent;
    case JDStatusBarSystemStyleDarkContent:
      return UIStatusBarStyleDarkContent;
  }
}

- (UIStatusBarStyle)defaultStatusBarStyle {
  if(JDUIViewControllerBasedStatusBarAppearanceEnabled()) {
    return [[[UIApplication sharedApplication] jdsb_mainControllerIgnoringViewController:self] preferredStatusBarStyle];
  }

  return [super preferredStatusBarStyle];
}

- (BOOL)prefersStatusBarHidden {
  if(JDUIViewControllerBasedStatusBarAppearanceEnabled()) {
    return [[[UIApplication sharedApplication] jdsb_mainControllerIgnoringViewController:self] prefersStatusBarHidden];
  }
  return [super prefersStatusBarHidden];
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
  return UIStatusBarAnimationFade;
}

@end
