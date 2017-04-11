//
// LLProgressHUD.m
//
//  Created by LianLeven on 2017/2/22.
//  Copyright © 2017年 LEVEN. All rights reserved.
//

#import "LLProgressHUD.h"
//#import <tgmath.h>
#import <pthread.h>
#import "LLActivityindicatorView.h"


#ifndef kCFCoreFoundationVersionNumber_iOS_7_0
    #define kCFCoreFoundationVersionNumber_iOS_7_0 847.20
#endif

#ifndef kCFCoreFoundationVersionNumber_iOS_8_0
    #define kCFCoreFoundationVersionNumber_iOS_8_0 1129.15
#endif

#define RCMainThreadAssert() NSAssert([NSThread isMainThread], @"LLProgressHUD needs to be accessed on the main thread.");

CGFloat const LLProgressMaxOffset = 1000000.f;

static const CGFloat RCDefaultPadding = 4.f;
static const CGFloat RCDefaultLabelFontSize = 16.f;
static const CGFloat RCDefaultDetailsLabelFontSize = 12.f;

static inline void dispatch_async_on_main_queue(void (^block)()) {
    if (pthread_main_np()) {
        block();
    } else {
        dispatch_async(dispatch_get_main_queue(), block);
    }
}

@interface LLProgressHUD ()

@property (nonatomic, assign) BOOL useAnimation;
@property (nonatomic, assign, getter=hasFinished) BOOL finished;
@property (nonatomic, strong) UIView *indicator;
@property (nonatomic, strong) NSDate *showStarted;
@property (nonatomic, strong) NSArray *paddingConstraints;
@property (nonatomic, strong) NSArray *bezelConstraints;
@property (nonatomic, strong) UIView *topSpacer;
@property (nonatomic, strong) UIView *bottomSpacer;
@property (nonatomic, weak) NSTimer *graceTimer;
@property (nonatomic, weak) NSTimer *minShowTimer;
@property (nonatomic, weak) NSTimer *hideDelayTimer;
@property (nonatomic, weak) CADisplayLink *progressObjectDisplayLink;

@property (strong, nonatomic) UIColor *activityIndicatorColor;
@property (assign, nonatomic) CGFloat opacity ;


@end


@interface LLProgressHUDRoundedButton : UIButton
@end


@implementation LLProgressHUD

#pragma mark - Class methods

+ (instancetype)HUDAddedToWindow{
    UIWindow *window = [[[UIApplication sharedApplication] delegate] window];
    LLProgressHUD *hud = [LLProgressHUD showHUDAddedTo:window animated:YES];
    return hud;
}
+ (instancetype)HUDForWindow{
    UIWindow *window = [[[UIApplication sharedApplication] delegate] window];
    LLProgressHUD *hud = [LLProgressHUD HUDForView:window];
    return hud;
}

+ (instancetype)showHUDAddedTo:(UIView *)view animated:(BOOL)animated {
    LLProgressHUD *hud = [[self alloc] initWithView:view];
    hud.removeFromSuperViewOnHide = YES;
    [view addSubview:hud];
    [hud showAnimated:animated];
    return hud;
}

+ (BOOL)hideHUDForView:(UIView *)view animated:(BOOL)animated {
    LLProgressHUD *hud = [self HUDForView:view];
    if (hud != nil) {
        hud.removeFromSuperViewOnHide = YES;
        [hud hideAnimated:animated];
        return YES;
    }
    return NO;
}

+ (LLProgressHUD *)HUDForView:(UIView *)view {
    NSEnumerator *subviewsEnum = [view.subviews reverseObjectEnumerator];
    for (UIView *subview in subviewsEnum) {
        if ([subview isKindOfClass:self]) {
            return (LLProgressHUD *)subview;
        }
    }
    return nil;
}

#pragma mark - Lifecycle

- (void)commonInit {
    // Set default values for properties
    _animationType = LLProgressHUDAnimationFade;
    _mode = LLProgressHUDModeIndeterminate;
//    _minSize = CGSizeMake(100, 100);
    _margin = 8.0f;
    _margin = 20.0f;
    _opacity = 1.f;
    _defaultMotionEffectsEnabled = YES;
    _contentColor = [UIColor whiteColor];
    // Transparent background
    self.opaque = NO;
    self.backgroundColor = [UIColor clearColor];
    // Make it invisible for now
    self.alpha = 0.0f;
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.layer.allowsGroupOpacity = NO;

    [self setupViews];
    [self updateIndicators];
    [self registerForNotifications];
}
- (instancetype)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if ((self = [super initWithCoder:aDecoder])) {
        [self commonInit];
    }
    return self;
}

- (id)initWithView:(UIView *)view {
    NSAssert(view, @"View must not be nil.");
    return [self initWithFrame:view.bounds];
}

- (void)dealloc {
    [self unregisterFromNotifications];
}

#pragma mark - Show & hide

- (void)showAnimated:(BOOL)animated {
    dispatch_async_on_main_queue(^{
        [self.minShowTimer invalidate];
        self.useAnimation = animated;
        self.finished = NO;
        // If the grace time is set, postpone the HUD display
        if (self.graceTime > 0.0) {
            NSTimer *timer = [NSTimer timerWithTimeInterval:self.graceTime target:self selector:@selector(handleGraceTimer:) userInfo:nil repeats:NO];
            [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
            self.graceTimer = timer;
        }
        // ... otherwise show the HUD immediately
        else {
            [self showUsingAnimation:self.useAnimation];
        }
    });
    
}

- (void)hideAnimated:(BOOL)animated {
    dispatch_async_on_main_queue(^{
        [self.graceTimer invalidate];
        self.useAnimation = animated;
        self.finished = YES;
        // If the minShow time is set, calculate how long the HUD was shown,
        // and postpone the hiding operation if necessary
        if (self.minShowTime > 0.0 && self.showStarted) {
            NSTimeInterval interv = [[NSDate date] timeIntervalSinceDate:self.showStarted];
            if (interv < self.minShowTime) {
                NSTimer *timer = [NSTimer timerWithTimeInterval:(self.minShowTime - interv) target:self selector:@selector(handleMinShowTimer:) userInfo:nil repeats:NO];
                [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
                self.minShowTimer = timer;
                return;
            }
        }
        // ... otherwise hide the HUD immediately
        [self hideUsingAnimation:self.useAnimation];
    });
    
}

- (void)hideAnimated:(BOOL)animated afterDelay:(NSTimeInterval)delay {
    NSTimer *timer = [NSTimer timerWithTimeInterval:delay target:self selector:@selector(handleHideTimer:) userInfo:@(animated) repeats:NO];
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
    self.hideDelayTimer = timer;
}

#pragma mark - Timer callbacks

- (void)handleGraceTimer:(NSTimer *)theTimer {
    // Show the HUD only if the task is still running
    if (!self.hasFinished) {
        [self showUsingAnimation:self.useAnimation];
    }
}

- (void)handleMinShowTimer:(NSTimer *)theTimer {
    [self hideUsingAnimation:self.useAnimation];
}

- (void)handleHideTimer:(NSTimer *)timer {
    [self hideAnimated:[timer.userInfo boolValue]];
}

#pragma mark - View Hierrarchy

- (void)didMoveToSuperview {
    [self updateForCurrentOrientationAnimated:NO];
}

#pragma mark - Internal show & hide operations

- (void)showUsingAnimation:(BOOL)animated {
    // Cancel any previous animations
    [self.bezelView.layer removeAllAnimations];
    [self.backgroundView.layer removeAllAnimations];

    // Cancel any scheduled hideDelayed: calls
    [self.hideDelayTimer invalidate];

    self.showStarted = [NSDate date];
    self.alpha = 1.f;

    // Needed in case we hide and re-show with the same NSProgress object attached.
    [self setNSProgressDisplayLinkEnabled:YES];

    if (animated) {
        [self animateIn:YES withType:self.animationType completion:NULL];
    } else {
        self.bezelView.alpha = self.opacity;
        self.backgroundView.alpha = 1.f;
    }
}

- (void)hideUsingAnimation:(BOOL)animated {
    if (animated && self.showStarted) {
        self.showStarted = nil;
        [self animateIn:NO withType:self.animationType completion:^(BOOL finished) {
            [self done];
        }];
    } else {
        self.showStarted = nil;
        self.bezelView.alpha = 0.f;
        self.backgroundView.alpha = 1.f;
        [self done];
    }
}

- (void)animateIn:(BOOL)animatingIn withType:(LLProgressHUDAnimation)type completion:(void(^)(BOOL finished))completion {
    // Automatically determine the correct zoom animation type
    if (type == LLProgressHUDAnimationZoom) {
        type = animatingIn ? LLProgressHUDAnimationZoomIn : LLProgressHUDAnimationZoomOut;
    }

    CGAffineTransform small = CGAffineTransformMakeScale(0.5f, 0.5f);
    CGAffineTransform large = CGAffineTransformMakeScale(1.5f, 1.5f);

    // Set starting state
    UIView *bezelView = self.bezelView;
    if (animatingIn && bezelView.alpha == 0.f && type == LLProgressHUDAnimationZoomIn) {
        bezelView.transform = small;
    } else if (animatingIn && bezelView.alpha == 0.f && type == LLProgressHUDAnimationZoomOut) {
        bezelView.transform = large;
    }

    // Perform animations
    dispatch_block_t animations = ^{
        if (animatingIn) {
            bezelView.transform = CGAffineTransformIdentity;
        } else if (!animatingIn && type == LLProgressHUDAnimationZoomIn) {
            bezelView.transform = large;
        } else if (!animatingIn && type == LLProgressHUDAnimationZoomOut) {
            bezelView.transform = small;
        }
        bezelView.alpha = animatingIn ? self.opacity : 0.f;
        self.backgroundView.alpha = animatingIn ? 1.f : 0.f;
    };

    // Spring animations are nicer, but only available on iOS 7+
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 70000 || TARGET_OS_TV
    if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_7_0) {
        [UIView animateWithDuration:0.3 delay:0. usingSpringWithDamping:1.f initialSpringVelocity:0.f options:UIViewAnimationOptionBeginFromCurrentState animations:animations completion:completion];
        return;
    }
#endif
    [UIView animateWithDuration:0.3 delay:0. options:UIViewAnimationOptionBeginFromCurrentState animations:animations completion:completion];
}

- (void)done {
    // Cancel any scheduled hideDelayed: calls
    [self.hideDelayTimer invalidate];
    [self setNSProgressDisplayLinkEnabled:NO];

    if (self.hasFinished) {
        self.alpha = 0.0f;
        if (self.removeFromSuperViewOnHide) {
            [self removeFromSuperview];
        }
    }
    LLProgressHUDCompletionBlock completionBlock = self.completionBlock;
    if (completionBlock) {
        completionBlock();
    }
    id<LLProgressHUDDelegate> delegate = self.delegate;
    if ([delegate respondsToSelector:@selector(hudWasHidden:)]) {
        [delegate performSelector:@selector(hudWasHidden:) withObject:self];
    }
    if (self.indicator && [self.indicator isKindOfClass:[LLActivityindicatorView class]]) {
        [(LLActivityindicatorView *)self.indicator stopAnimating];
    }
}

#pragma mark - UI

- (void)setupViews {
    UIColor *defaultColor = self.contentColor;

    LLBackgroundView *backgroundView = [[LLBackgroundView alloc] initWithFrame:self.bounds];
    backgroundView.style = LLProgressHUDBackgroundStyleSolidColor;
    backgroundView.backgroundColor = [UIColor clearColor];
    backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    backgroundView.alpha = 0.f;
    [self addSubview:backgroundView];
    _backgroundView = backgroundView;

    LLBackgroundView *bezelView = [LLBackgroundView new];
    bezelView.translatesAutoresizingMaskIntoConstraints = NO;
    bezelView.layer.cornerRadius = 5.f;
    bezelView.alpha = 0.f;
    [self addSubview:bezelView];
    _bezelView = bezelView;
    [self updateBezelMotionEffects];

    LLTextLabel *label = [LLTextLabel new];
    label.adjustsFontSizeToFitWidth = NO;
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = defaultColor;
    label.font = [UIFont boldSystemFontOfSize:RCDefaultLabelFontSize];
    label.opaque = NO;
    label.backgroundColor = [UIColor clearColor];
    _label = label;

    LLTextLabel *detailsLabel = [LLTextLabel new];
    detailsLabel.adjustsFontSizeToFitWidth = NO;
    detailsLabel.textAlignment = NSTextAlignmentCenter;
    detailsLabel.textColor = defaultColor;
    detailsLabel.numberOfLines = 0;
    detailsLabel.font = [UIFont boldSystemFontOfSize:RCDefaultDetailsLabelFontSize];
    detailsLabel.opaque = NO;
    detailsLabel.backgroundColor = [UIColor clearColor];
    _detailsLabel = detailsLabel;

    UIButton *button = [LLProgressHUDRoundedButton buttonWithType:UIButtonTypeCustom];
    button.titleLabel.textAlignment = NSTextAlignmentCenter;
    button.titleLabel.font = [UIFont boldSystemFontOfSize:RCDefaultDetailsLabelFontSize];
    [button setTitleColor:defaultColor forState:UIControlStateNormal];
    _button = button;

    for (UIView *view in @[label, detailsLabel, button]) {
        view.translatesAutoresizingMaskIntoConstraints = NO;
        [view setContentCompressionResistancePriority:998.f forAxis:UILayoutConstraintAxisHorizontal];
        [view setContentCompressionResistancePriority:998.f forAxis:UILayoutConstraintAxisVertical];
        [bezelView addSubview:view];
    }

    UIView *topSpacer = [UIView new];
    topSpacer.translatesAutoresizingMaskIntoConstraints = NO;
    topSpacer.hidden = YES;
    [bezelView addSubview:topSpacer];
    _topSpacer = topSpacer;

    UIView *bottomSpacer = [UIView new];
    bottomSpacer.translatesAutoresizingMaskIntoConstraints = NO;
    bottomSpacer.hidden = YES;
    [bezelView addSubview:bottomSpacer];
    _bottomSpacer = bottomSpacer;
}

- (void)updateIndicators {
    UIView *indicator = self.indicator;
    BOOL isActivityIndicator = [indicator isKindOfClass:[LLActivityindicatorView class]];
    BOOL isRoundIndicator = [indicator isKindOfClass:[LLRoundProgressView class]];

    LLProgressHUDMode mode = self.mode;
    if (mode == LLProgressHUDModeIndeterminate) {
        if (!isActivityIndicator) {
            // Update to indeterminate indicator
            [indicator removeFromSuperview];
            indicator = [[LLActivityindicatorView alloc] init];
            [(LLActivityindicatorView *)indicator startAnimating];
            [self.bezelView addSubview:indicator];
        }
    }
    else if (mode == LLProgressHUDModeDeterminateHorizontalBar) {
        // Update to bar determinate indicator
        [indicator removeFromSuperview];
        indicator = [[LLBarProgressView alloc] init];
        [self.bezelView addSubview:indicator];
    }
    else if (mode == LLProgressHUDModeDeterminate || mode == LLProgressHUDModeAnnularDeterminate) {
        if (!isRoundIndicator) {
            // Update to determinante indicator
            [indicator removeFromSuperview];
            indicator = [[LLRoundProgressView alloc] init];
            [self.bezelView addSubview:indicator];
        }
        if (mode == LLProgressHUDModeAnnularDeterminate) {
            [(LLRoundProgressView *)indicator setAnnular:YES];
        }
    } 
    else if (mode == LLProgressHUDModeCustomView && self.customView != indicator) {
        // Update custom view indicator
        [indicator removeFromSuperview];
        indicator = self.customView;
        [self.bezelView addSubview:indicator];
    }
    else if (mode == LLProgressHUDModeText) {
        [indicator removeFromSuperview];
        indicator = nil;
    }
    indicator.translatesAutoresizingMaskIntoConstraints = NO;
    self.indicator = indicator;

    if ([indicator respondsToSelector:@selector(setProgress:)]) {
        [(id)indicator setValue:@(self.progress) forKey:@"progress"];
    }

    [indicator setContentCompressionResistancePriority:998.f forAxis:UILayoutConstraintAxisHorizontal];
    [indicator setContentCompressionResistancePriority:998.f forAxis:UILayoutConstraintAxisVertical];

    [self updateViewsForColor:self.contentColor];
    [self setNeedsUpdateConstraints];
}

- (void)updateViewsForColor:(UIColor *)color {
    if (!color) return;

    self.label.textColor = color;
    self.detailsLabel.textColor = color;
    [self.button setTitleColor:color forState:UIControlStateNormal];
    if (self.indicator && [self.indicator isKindOfClass:[LLActivityindicatorView class]]) {
        ((LLActivityindicatorView *)self.indicator).color = color;
    }

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    if (self.activityIndicatorColor) {
        color = self.activityIndicatorColor;
    }
#pragma clang diagnostic pop

    // UIAppearance settings are prioritized. If they are preset the set color is ignored.

    UIView *indicator = self.indicator;
    if ([indicator isKindOfClass:[LLActivityindicatorView class]]) {
        LLActivityindicatorView *appearance = nil;
#if __IPHONE_OS_VERSION_MIN_REQUIRED < 90000
        appearance = [LLActivityindicatorView appearanceWhenContainedIn:[LLProgressHUD class], nil];
#else
        // For iOS 9+
        appearance = [LLActivityindicatorView appearanceWhenContainedInInstancesOfClasses:@[[LLProgressHUD class]]];
#endif
        
        if (appearance.color == nil) {
            ((LLActivityindicatorView *)indicator).color = color;
        }
    } else if ([indicator isKindOfClass:[LLRoundProgressView class]]) {
        LLRoundProgressView *appearance = nil;
#if __IPHONE_OS_VERSION_MIN_REQUIRED < 90000
        appearance = [LLRoundProgressView appearanceWhenContainedIn:[LLProgressHUD class], nil];
#else
        appearance = [LLRoundProgressView appearanceWhenContainedInInstancesOfClasses:@[[LLProgressHUD class]]];
#endif
        if (appearance.progressTintColor == nil) {
            ((LLRoundProgressView *)indicator).progressTintColor = color;
        }
        if (appearance.backgroundTintColor == nil) {
            ((LLRoundProgressView *)indicator).backgroundTintColor = [color colorWithAlphaComponent:0.1];
        }
    } else if ([indicator isKindOfClass:[LLBarProgressView class]]) {
        LLBarProgressView *appearance = nil;
#if __IPHONE_OS_VERSION_MIN_REQUIRED < 90000
        appearance = [LLBarProgressView appearanceWhenContainedIn:[LLProgressHUD class], nil];
#else
        appearance = [LLBarProgressView appearanceWhenContainedInInstancesOfClasses:@[[LLProgressHUD class]]];
#endif
        if (appearance.progressColor == nil) {
            ((LLBarProgressView *)indicator).progressColor = color;
        }
        if (appearance.lineColor == nil) {
            ((LLBarProgressView *)indicator).lineColor = color;
        }
    } else {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 70000 || TARGET_OS_TV
        if ([indicator respondsToSelector:@selector(setTintColor:)]) {
            [indicator setTintColor:color];
        }
#endif
    }
}

- (void)updateBezelMotionEffects {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 70000 || TARGET_OS_TV
    LLBackgroundView *bezelView = self.bezelView;
    if (![bezelView respondsToSelector:@selector(addMotionEffect:)]) return;

    if (self.defaultMotionEffectsEnabled) {
        CGFloat effectOffset = 10.f;
        UIInterpolatingMotionEffect *effectX = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.x" type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
        effectX.maximumRelativeValue = @(effectOffset);
        effectX.minimumRelativeValue = @(-effectOffset);

        UIInterpolatingMotionEffect *effectY = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.y" type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
        effectY.maximumRelativeValue = @(effectOffset);
        effectY.minimumRelativeValue = @(-effectOffset);

        UIMotionEffectGroup *group = [[UIMotionEffectGroup alloc] init];
        group.motionEffects = @[effectX, effectY];

        [bezelView addMotionEffect:group];
    } else {
        NSArray *effects = [bezelView motionEffects];
        for (UIMotionEffect *effect in effects) {
            [bezelView removeMotionEffect:effect];
        }
    }
#endif
}

#pragma mark - Layout

- (void)updateConstraints {
    UIView *bezel = self.bezelView;
    UIView *topSpacer = self.topSpacer;
    UIView *bottomSpacer = self.bottomSpacer;
    CGFloat margin = self.margin;
    NSMutableArray *bezelConstraints = [NSMutableArray array];
    NSDictionary *metrics = @{@"margin": @(margin)};

    NSMutableArray *subviews = [NSMutableArray arrayWithObjects:self.topSpacer, self.label, self.detailsLabel, self.button, self.bottomSpacer, nil];
    if (self.indicator) [subviews insertObject:self.indicator atIndex:1];

    // Remove existing constraints
    [self removeConstraints:self.constraints];
    [topSpacer removeConstraints:topSpacer.constraints];
    [bottomSpacer removeConstraints:bottomSpacer.constraints];
    if (self.bezelConstraints) {
        [bezel removeConstraints:self.bezelConstraints];
        self.bezelConstraints = nil;
    }

    // Center bezel in container (self), applying the offset if set
    CGPoint offset = self.offset;
    NSMutableArray *centeringConstraints = [NSMutableArray array];
    [centeringConstraints addObject:[NSLayoutConstraint constraintWithItem:bezel attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterX multiplier:1.f constant:offset.x]];
    [centeringConstraints addObject:[NSLayoutConstraint constraintWithItem:bezel attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1.f constant:offset.y]];
    [self applyPriority:998.f toConstraints:centeringConstraints];
    [self addConstraints:centeringConstraints];

    // Ensure minimum side margin is kept
    NSMutableArray *sideConstraints = [NSMutableArray array];
    [sideConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"|-(>=margin)-[bezel]-(>=margin)-|" options:0 metrics:metrics views:NSDictionaryOfVariableBindings(bezel)]];
    [sideConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(>=margin)-[bezel]-(>=margin)-|" options:0 metrics:metrics views:NSDictionaryOfVariableBindings(bezel)]];
    [self applyPriority:999.f toConstraints:sideConstraints];
    [self addConstraints:sideConstraints];

    // Minimum bezel size, if set
    CGSize minimumSize = self.minSize;
    if (!CGSizeEqualToSize(minimumSize, CGSizeZero)) {
        NSMutableArray *minSizeConstraints = [NSMutableArray array];
        [minSizeConstraints addObject:[NSLayoutConstraint constraintWithItem:bezel attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.f constant:minimumSize.width]];
        [minSizeConstraints addObject:[NSLayoutConstraint constraintWithItem:bezel attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.f constant:minimumSize.height]];
        [self applyPriority:997.f toConstraints:minSizeConstraints];
        [bezelConstraints addObjectsFromArray:minSizeConstraints];
    }

    // Square aspect ratio, if set
    if (self.square) {
        NSLayoutConstraint *square = [NSLayoutConstraint constraintWithItem:bezel attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:bezel attribute:NSLayoutAttributeWidth multiplier:1.f constant:0];
        square.priority = 997.f;
        [bezelConstraints addObject:square];
    }

    // Top and bottom spacing
    [topSpacer addConstraint:[NSLayoutConstraint constraintWithItem:topSpacer attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.f constant:margin]];
    [bottomSpacer addConstraint:[NSLayoutConstraint constraintWithItem:bottomSpacer attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.f constant:margin]];
    // Top and bottom spaces should be equal
    [bezelConstraints addObject:[NSLayoutConstraint constraintWithItem:topSpacer attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:bottomSpacer attribute:NSLayoutAttributeHeight multiplier:1.f constant:0.f]];

    // Layout subviews in bezel
    NSMutableArray *paddingConstraints = [NSMutableArray new];
    [subviews enumerateObjectsUsingBlock:^(UIView *view, NSUInteger idx, BOOL *stop) {
        // Center in bezel
        [bezelConstraints addObject:[NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:bezel attribute:NSLayoutAttributeCenterX multiplier:1.f constant:0.f]];
        // Ensure the minimum edge margin is kept
        [bezelConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"|-(>=margin)-[view]-(>=margin)-|" options:0 metrics:metrics views:NSDictionaryOfVariableBindings(view)]];
        // Element spacing
        if (idx == 0) {
            // First, ensure spacing to bezel edge
            [bezelConstraints addObject:[NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:bezel attribute:NSLayoutAttributeTop multiplier:1.f constant:0.f]];
        } else if (idx == subviews.count - 1) {
            // Last, ensure spacing to bezel edge
            [bezelConstraints addObject:[NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:bezel attribute:NSLayoutAttributeBottom multiplier:1.f constant:0.f]];
        }
        if (idx > 0) {
            // Has previous
            NSLayoutConstraint *padding = [NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:subviews[idx - 1] attribute:NSLayoutAttributeBottom multiplier:1.f constant:0.f];
            [bezelConstraints addObject:padding];
            [paddingConstraints addObject:padding];
        }
    }];

    [bezel addConstraints:bezelConstraints];
    self.bezelConstraints = bezelConstraints;
    
    self.paddingConstraints = [paddingConstraints copy];
    [self updatePaddingConstraints];
    
    [super updateConstraints];
}

- (void)layoutSubviews {
    // There is no need to update constraints if they are going to
    // be recreated in [super layoutSubviews] due to needsUpdateConstraints being set.
    // This also avoids an issue on iOS 8, where updatePaddingConstraints
    // would trigger a zombie object access.
    if (!self.needsUpdateConstraints) {
        [self updatePaddingConstraints];
    }
    [super layoutSubviews];
}

- (void)updatePaddingConstraints {
    // Set padding dynamically, depending on whether the view is visible or not
    __block BOOL hasVisibleAncestors = NO;
    [self.paddingConstraints enumerateObjectsUsingBlock:^(NSLayoutConstraint *padding, NSUInteger idx, BOOL *stop) {
        UIView *firstView = (UIView *)padding.firstItem;
        UIView *secondView = (UIView *)padding.secondItem;
        BOOL firstVisible = !firstView.hidden && !CGSizeEqualToSize(firstView.intrinsicContentSize, CGSizeZero);
        BOOL secondVisible = !secondView.hidden && !CGSizeEqualToSize(secondView.intrinsicContentSize, CGSizeZero);
        // Set if both views are visible or if there's a visible view on top that doesn't have padding
        // added relative to the current view yet
        padding.constant = (firstVisible && (secondVisible || hasVisibleAncestors)) ? RCDefaultPadding : 0.f;
        hasVisibleAncestors |= secondVisible;
    }];
}

- (void)applyPriority:(UILayoutPriority)priority toConstraints:(NSArray *)constraints {
    for (NSLayoutConstraint *constraint in constraints) {
        constraint.priority = priority;
    }
}

#pragma mark - Properties

- (void)setMode:(LLProgressHUDMode)mode {
    if (mode != _mode) {
        _mode = mode;
        [self updateIndicators];
    }
}

- (void)setCustomView:(UIView *)customView {
    if (customView != _customView) {
        _customView = customView;
        if (self.mode == LLProgressHUDModeCustomView) {
            [self updateIndicators];
        }
    }
}

- (void)setOffset:(CGPoint)offset {
    if (!CGPointEqualToPoint(offset, _offset)) {
        _offset = offset;
        [self setNeedsUpdateConstraints];
    }
}

- (void)setMargin:(CGFloat)margin {
    if (margin != _margin) {
        _margin = margin;
        [self setNeedsUpdateConstraints];
    }
}

- (void)setMinSize:(CGSize)minSize {
    if (!CGSizeEqualToSize(minSize, _minSize)) {
        _minSize = minSize;
        [self setNeedsUpdateConstraints];
    }
}

- (void)setSquare:(BOOL)square {
    if (square != _square) {
        _square = square;
        [self setNeedsUpdateConstraints];
    }
}

- (void)setProgressObjectDisplayLink:(CADisplayLink *)progressObjectDisplayLink {
    if (progressObjectDisplayLink != _progressObjectDisplayLink) {
        [_progressObjectDisplayLink invalidate];
        
        _progressObjectDisplayLink = progressObjectDisplayLink;
        
        [_progressObjectDisplayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    }
}

- (void)setProgressObject:(NSProgress *)progressObject {
    if (progressObject != _progressObject) {
        _progressObject = progressObject;
        [self setNSProgressDisplayLinkEnabled:YES];
    }
}

- (void)setProgress:(float)progress {
    if (progress != _progress) {
        _progress = progress;
        UIView *indicator = self.indicator;
        if ([indicator respondsToSelector:@selector(setProgress:)]) {
            [(id)indicator setValue:@(self.progress) forKey:@"progress"];
        }
    }
}

- (void)setContentColor:(UIColor *)contentColor {
    if (contentColor != _contentColor && ![contentColor isEqual:_contentColor]) {
        _contentColor = contentColor;
        [self updateViewsForColor:contentColor];
    }
}

- (void)setDefaultMotionEffectsEnabled:(BOOL)defaultMotionEffectsEnabled {
    if (defaultMotionEffectsEnabled != _defaultMotionEffectsEnabled) {
        _defaultMotionEffectsEnabled = defaultMotionEffectsEnabled;
        [self updateBezelMotionEffects];
    }
}

#pragma mark - NSProgress

- (void)setNSProgressDisplayLinkEnabled:(BOOL)enabled {
    // We're using CADisplayLink, because NSProgress can change very quickly and observing it may starve the main thread,
    // so we're refreshing the progress only every frame draw
    if (enabled && self.progressObject) {
        // Only create if not already active.
        if (!self.progressObjectDisplayLink) {
            self.progressObjectDisplayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateProgressFromProgressObject)];
        }
    } else {
        self.progressObjectDisplayLink = nil;
    }
}

- (void)updateProgressFromProgressObject {
    self.progress = self.progressObject.fractionCompleted;
}

#pragma mark - Notifications

- (void)registerForNotifications {
#if !TARGET_OS_TV
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];

    [nc addObserver:self selector:@selector(statusBarOrientationDidChange:)
               name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
#endif
}

- (void)unregisterFromNotifications {
#if !TARGET_OS_TV
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
#endif
}

#if !TARGET_OS_TV
- (void)statusBarOrientationDidChange:(NSNotification *)notification {
    UIView *superview = self.superview;
    if (!superview) {
        return;
    } else {
        [self updateForCurrentOrientationAnimated:YES];
    }
}
#endif

- (void)updateForCurrentOrientationAnimated:(BOOL)animated {
    // Stay in sync with the superview in any case
    if (self.superview) {
        self.frame = self.superview.bounds;
    }

    // Not needed on iOS 8+, compile out when the deployment target allows,
    // to avoid sharedApplication problems on extension targets
#if __IPHONE_OS_VERSION_MIN_REQUIRED < 80000
    // Only needed pre iOS 8 when added to a window
    BOOL iOS8OrLater = kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_8_0;
    if (iOS8OrLater || ![self.superview isKindOfClass:[UIWindow class]]) return;

    // Make extension friendly. Will not get called on extensions (iOS 8+) due to the above check.
    // This just ensures we don't get a warning about extension-unsafe API.
    Class UIApplicationClass = NSClassFromString(@"UIApplication");
    if (!UIApplicationClass || ![UIApplicationClass respondsToSelector:@selector(sharedApplication)]) return;

    UIApplication *application = [UIApplication performSelector:@selector(sharedApplication)];
    UIInterfaceOrientation orientation = application.statusBarOrientation;
    CGFloat radians = 0;
    
    if (UIInterfaceOrientationIsLandscape(orientation)) {
        radians = orientation == UIInterfaceOrientationLandscapeLeft ? -(CGFloat)M_PI_2 : (CGFloat)M_PI_2;
        // Window coordinates differ!
        self.bounds = CGRectMake(0, 0, self.bounds.size.height, self.bounds.size.width);
    } else {
        radians = orientation == UIInterfaceOrientationPortraitUpsideDown ? (CGFloat)M_PI : 0.f;
    }

    if (animated) {
        [UIView animateWithDuration:0.3 animations:^{
            self.transform = CGAffineTransformMakeRotation(radians);
        }];
    } else {
        self.transform = CGAffineTransformMakeRotation(radians);
    }
#endif
}

@end

@interface LLBackgroundView ()

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000 || TARGET_OS_TV
@property UIVisualEffectView *effectView;
#endif
#if !TARGET_OS_TV
@property UIToolbar *toolbar;
#endif

@end


@implementation LLBackgroundView

#pragma mark - Lifecycle

- (instancetype)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        _style = LLProgressHUDBackgroundStyleSolidColor;
        _color = [[UIColor blackColor] colorWithAlphaComponent:0.6];
        self.clipsToBounds = YES;

        [self updateForBackgroundStyle];
    }
    return self;
}

#pragma mark - Layout

- (CGSize)intrinsicContentSize {
    // Smallest size possible. Content pushes against this.
    return CGSizeZero;
}

#pragma mark - Appearance

- (void)setStyle:(LLProgressHUDBackgroundStyle)style {
    if (_style != style) {
        _style = style;
        [self updateForBackgroundStyle];
    }
}

- (void)setColor:(UIColor *)color {
    NSAssert(color, @"The color should not be nil.");
    if (color != _color && ![color isEqual:_color]) {
        _color = color;
        [self updateViewsForColor:color];
    }
}

///////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Views

- (void)updateForBackgroundStyle {
    
    self.backgroundColor = self.color;
    
}

- (void)updateViewsForColor:(UIColor *)color {
     {
        self.backgroundColor = self.color;
    }
}

@end

@implementation LLProgressHUDRoundedButton

#pragma mark - Lifecycle

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        CALayer *layer = self.layer;
        layer.borderWidth = 1.f;
    }
    return self;
}

#pragma mark - Layout

- (void)layoutSubviews {
    [super layoutSubviews];
    // Fully rounded corners
    CGFloat height = CGRectGetHeight(self.bounds);
    self.layer.cornerRadius = ceil(height / 2.f);
}

- (CGSize)intrinsicContentSize {
    // Only show if we have associated control events
    if (self.allControlEvents == 0) return CGSizeZero;
    CGSize size = [super intrinsicContentSize];
    // Add some side padding
    size.width += 20.f;
    return size;
}

#pragma mark - Color

- (void)setTitleColor:(UIColor *)color forState:(UIControlState)state {
    [super setTitleColor:color forState:state];
    // Update related colors
    [self setHighlighted:self.highlighted];
    self.layer.borderColor = color.CGColor;
}

- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    UIColor *baseColor = [self titleColorForState:UIControlStateSelected];
    self.backgroundColor = highlighted ? [baseColor colorWithAlphaComponent:0.1f] : [UIColor clearColor];
}
@end
@implementation LLProgressHUD (Simple)

#pragma mark - Show Methods on window

+ (instancetype)show{
    return [LLProgressHUD showLoadingText:@""];
}
+ (instancetype)showLoadingText:(NSString*)text{
    return [self showText:text
          progress:0
             image:nil
        customView:nil
              mode:LLProgressHUDModeIndeterminate
        afterDelay:0];
}

+ (instancetype)showProgress:(float)progress{
    return [LLProgressHUD showProgress:progress text:@""];
    
}
+ (instancetype)showProgress:(float)progress text:(NSString*)text{
    return [LLProgressHUD showProgress:progress text:text progressHUDMode:LLProgressHUDModeAnnularDeterminate];
}
+ (instancetype)showProgress:(float)progress text:(NSString*)text progressHUDMode:(LLProgressHUDMode)mode{
    return [self showText:text progress:progress image:nil customView:nil mode:mode afterDelay:0];
}
// stops the activity indicator, shows a glyph + text, and dismisses the HUD a little bit later
+ (instancetype)showText:(NSString *)text{
    return [LLProgressHUD showText:text afterDelay:2.0];
}
+ (instancetype)showText:(NSString *)text afterDelay:(NSTimeInterval)delay{
    return [self showText:text
          progress:0
             image:nil
        customView:nil
              mode:LLProgressHUDModeText
        afterDelay:delay];
}
+ (instancetype)showSuccessText:(NSString*)text{
    return [LLProgressHUD showSuccessText:text afterDelay:2.0];
}
+ (instancetype)showSuccessText:(NSString*)text afterDelay:(NSTimeInterval)delay{
    UIImage *image = [LLProgressHUD imageBuddleName:@"Checkmark"];
    return [LLProgressHUD showCustomView:[[UIImageView alloc] initWithImage:image] text:text afterDelay:delay];
}
+ (instancetype)showErrorText:(NSString*)text{
    return [LLProgressHUD showErrorText:text afterDelay:2.0];
}
+ (instancetype)showErrorText:(NSString*)text afterDelay:(NSTimeInterval)delay;{
    UIImage *image = [LLProgressHUD imageBuddleName:@"error"];
    return [LLProgressHUD showCustomView:[[UIImageView alloc] initWithImage:image] text:text afterDelay:delay];
}
+ (instancetype)showWarningText:(NSString*)text{
    return [LLProgressHUD showWarningText:text afterDelay:2.0];
}
+ (instancetype)showWarningText:(NSString*)text afterDelay:(NSTimeInterval)delay;{
    UIImage *image = [LLProgressHUD imageBuddleName:@"warning"];
    return [LLProgressHUD showCustomView:[[UIImageView alloc] initWithImage:image] text:text afterDelay:delay];
}
+ (instancetype)showCustomView:(UIView *)view text:(NSString *)text afterDelay:(NSTimeInterval)delay{
    return [LLProgressHUD showText:text
                   progress:0
                      image:nil
                 customView:view
                       mode:LLProgressHUDModeCustomView
                 afterDelay:delay];
}

// shows a image + text
+ (instancetype)showImage:(UIImage*)image text:(NSString*)text;{
    return [self showText:text
          progress:0
             image:image
        customView:nil
              mode:LLProgressHUDModeText
        afterDelay:2.5];
}

+ (instancetype)hide{
    LLProgressHUD *hud = [LLProgressHUD HUDForWindow];
    [hud hideAnimated:YES];
    return hud;
}
#pragma mark - private
+ (void)setText:(NSString*)text;{
    
}
+ (instancetype)showText:(NSString *)text
        progress:(float)progress
           image:(UIImage *)image
      customView:(UIView *)view
            mode:(LLProgressHUDMode)mode
      afterDelay:(NSTimeInterval)afterDelay{
    LLProgressHUD *hud = [self HUDAddedToWindow];
    if (text && [text isKindOfClass:[NSString class]] && text.length > 0) {
        hud.label.text = text;
    }
    if (image) {
        hud.label.image = image;
    }
    hud.label.numberOfLines = 0;
    hud.progress = 0;
    hud.customView = view;
    hud.mode = mode;
    if (afterDelay > 0) {
        [hud hideAnimated:YES afterDelay:afterDelay];
    }
    return hud;
}
+ (UIImage *)imageBuddleName:(NSString *)imageName{
    NSBundle *buddle = [NSBundle bundleWithPath:[[NSBundle bundleForClass:[LLProgressHUD class]] pathForResource:@"LLProgressHUD" ofType:@"bundle"]];
    UIImage *image = [UIImage imageWithContentsOfFile:[buddle pathForResource:imageName ofType:@"png"]];
    image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    return image;
}

@end
