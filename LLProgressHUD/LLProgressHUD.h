//
//  LLProgressHUD.h
//
//  Created by LianLeven on 2017/2/22.
//  Copyright © 2017年 LEVEN. All rights reserved.
//



#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "LLRoundProgressView.h"
#import "LLBarProgressView.h"
#import "LLTextLabel.h"

@interface LLProgressHUDConfigure : NSObject

+ (nonnull instancetype)sharedConfigure;

@property (nullable, nonatomic, strong) UIImage *indicatorImage;

@end

@class LLBackgroundView;
@protocol LLProgressHUDDelegate;


extern CGFloat const LLProgressMaxOffset;

typedef NS_ENUM(NSInteger, LLProgressHUDMode) {
    /// LLActivityindicatorView.
    LLProgressHUDModeIndeterminate,
    /// A round, pie-chart like, progress view.
    LLProgressHUDModeDeterminate,
    /// Horizontal progress bar.
    LLProgressHUDModeDeterminateHorizontalBar,
    /// Ring-shaped progress view.
    LLProgressHUDModeAnnularDeterminate,
    /// Shows a custom view.
    LLProgressHUDModeCustomView,
    /// Shows only labels.
    LLProgressHUDModeText
};

typedef NS_ENUM(NSInteger, LLProgressHUDAnimation) {
    /// Opacity animation
    LLProgressHUDAnimationFade,
    /// Opacity + scale animation (zoom in when appearing zoom out when disappearing)
    LLProgressHUDAnimationZoom,
    /// Opacity + scale animation (zoom out style)
    LLProgressHUDAnimationZoomOut,
    /// Opacity + scale animation (zoom in style)
    LLProgressHUDAnimationZoomIn
};
typedef void (^LLProgressHUDCompletionBlock)();


NS_ASSUME_NONNULL_BEGIN




@interface LLProgressHUD : UIView


#pragma mark -
+ (instancetype)showHUDAddedTo:(UIView *)view animated:(BOOL)animated;
+ (BOOL)hideHUDForView:(UIView *)view animated:(BOOL)animated;

/**
 * Finds the top-most HUD subview and returns it. 
 *
 * @param view The view that is going to be searched.
 * @return A reference to the last HUD subview discovered.
 */
+ (nullable LLProgressHUD *)HUDForView:(UIView *)view;
+ (nullable LLProgressHUD *)HUDForWindow;

/**
 * A convenience constructor that initializes the HUD with the view's bounds. Calls the designated constructor with
 * view.bounds as the parameter.
 *
 * @param view The view instance that will provide the bounds for the HUD. Should be the same instance as
 * the HUD's superview (i.e., the view that the HUD will be added to).
 */
- (instancetype)initWithView:(UIView *)view;

/** 
 * Displays the HUD. 
 *
 * @note You need to make sure that the main thread completes its run loop soon after this method call so that
 * the user interface can be updated. Call this method when your task is already set up to be executed in a new thread
 * (e.g., when using something like NSOperation or making an asynchronous call like NSURLRequest).
 *
 * @param animated If set to YES the HUD will appear using the current animationType. If set to NO the HUD will not use
 * animations while appearing.
 *
 * @see animationType
 */
- (void)showAnimated:(BOOL)animated;

/** 
 * Hides the HUD. This still calls the hudWasHidden: delegate. This is the counterpart of the show: method. Use it to
 * hide the HUD when your task completes.
 *
 * @param animated If set to YES the HUD will disappear using the current animationType. If set to NO the HUD will not use
 * animations while disappearing.
 *
 * @see animationType
 */
- (void)hideAnimated:(BOOL)animated;

/** 
 * Hides the HUD after a delay. This still calls the hudWasHidden: delegate. This is the counterpart of the show: method. Use it to
 * hide the HUD when your task completes.
 *
 * @param animated If set to YES the HUD will disappear using the current animationType. If set to NO the HUD will not use
 * animations while disappearing.
 * @param delay Delay in seconds until the HUD is hidden.
 *
 * @see animationType
 */
- (void)hideAnimated:(BOOL)animated afterDelay:(NSTimeInterval)delay;

/**
 * The HUD delegate object. Receives HUD state notifications.
 */
@property (weak, nonatomic) id<LLProgressHUDDelegate> delegate;

/**
 * Called after the HUD is hiden.
 */
@property (copy, nullable) LLProgressHUDCompletionBlock completionBlock;

/*
 * Grace period is the time (in seconds) that the invoked method may be run without
 * showing the HUD. If the task finishes before the grace time runs out, the HUD will
 * not be shown at all.
 * This may be used to prevent HUD display for very short tasks.
 * Defaults to 0 (no grace time).
 */
@property (assign, nonatomic) NSTimeInterval graceTime;

/**
 * The minimum time (in seconds) that the HUD is shown.
 * This avoids the problem of the HUD being shown and than instantly hidden.
 * Defaults to 0 (no minimum show time).
 */
@property (assign, nonatomic) NSTimeInterval minShowTime;

/**
 * Removes the HUD from its parent view when hidden.
 * Defaults to NO.
 */
@property (assign, nonatomic) BOOL removeFromSuperViewOnHide;

/// @name Appearance

/** 
 * LLProgressHUD operation mode. The default is LLProgressHUDModeIndeterminate.
 */
@property (assign, nonatomic) LLProgressHUDMode mode;

/**
 * A color that gets forwarded to all labels and supported indicators. Also sets the tintColor
 * for custom views on iOS 7+. Set to nil to manage color individually.
 * Defaults to semi-translucent black on iOS 7 and later and white on earlier iOS versions.
 */
@property (strong, nonatomic, nullable) UIColor *contentColor UI_APPEARANCE_SELECTOR;

/**
 * The animation type that should be used when the HUD is shown and hidden.
 */
@property (assign, nonatomic) LLProgressHUDAnimation animationType UI_APPEARANCE_SELECTOR;

/**
 * The bezel offset relative to the center of the view. You can use LLProgressMaxOffset
 * and -LLProgressMaxOffset to move the HUD all the way to the screen edge in each direction.
 * E.g., CGPointMake(0.f, LLProgressMaxOffset) would position the HUD centered on the bottom edge.
 */
@property (assign, nonatomic) CGPoint offset UI_APPEARANCE_SELECTOR;

/**
 * The amount of space between the HUD edge and the HUD elements (labels, indicators or custom views).
 * This also represents the minimum bezel distance to the edge of the HUD view.
 * Defaults to 20.f
 */
@property (assign, nonatomic) CGFloat margin UI_APPEARANCE_SELECTOR;

/**
 * The minimum size of the HUD bezel. Defaults to CGSizeZero (no minimum size).
 */
@property (assign, nonatomic) CGSize minSize UI_APPEARANCE_SELECTOR;

/**
 * Force the HUD dimensions to be equal if possible.
 */
@property (assign, nonatomic, getter = isSquare) BOOL square UI_APPEARANCE_SELECTOR;

/**
 * When enabled, the bezel center gets slightly affected by the device accelerometer data.
 * Has no effect on iOS < 7.0. Defaults to YES.
 */
@property (assign, nonatomic, getter=areDefaultMotionEffectsEnabled) BOOL defaultMotionEffectsEnabled UI_APPEARANCE_SELECTOR;

/// @name Progress

/**
 * The progress of the progress indicator, from 0.0 to 1.0. Defaults to 0.0.
 */
@property (assign, nonatomic) float progress;

/// @name ProgressObject

/**
 * The NSProgress object feeding the progress information to the progress indicator.
 */
@property (strong, nonatomic, nullable) NSProgress *progressObject;

@property (nonatomic, strong) UIImage *indicatorImage;

/// @name Views

/**
 * The view containing the labels and indicator (or customView).
 */
@property (strong, nonatomic, readonly) LLBackgroundView *bezelView;

/**
 * View covering the entire HUD area, placed behind bezelView.
 */
@property (strong, nonatomic, readonly) LLBackgroundView *backgroundView;

/**
 * The UIView (e.g., a UIImageView) to be shown when the HUD is in LLProgressHUDModeCustomView.
 * The view should implement intrinsicContentSize for proper sizing. For best results use approximately 37 by 37 pixels.
 */
@property (strong, nonatomic, nullable) UIView *customView;

/**
 * A label that holds an optional short message to be displayed below the activity indicator. The HUD is automatically resized to fit
 * the entire text.
 */
@property (strong, nonatomic, readonly) LLTextLabel *label;

/**
 * A label that holds an optional details message displayed below the labelText message. The details text can span multiple lines.
 */
@property (strong, nonatomic, readonly) LLTextLabel *detailsLabel;

/**
 * A button that is placed below the labels. Visible only if a target / action is added. 
 */
@property (strong, nonatomic, readonly) UIButton *button;

@end


@protocol LLProgressHUDDelegate <NSObject>

@optional

/** 
 * Called after the HUD was fully hidden from the screen. 
 */
- (void)hudWasHidden:(LLProgressHUD *)hud;

@end


@interface LLBackgroundView : UIView

@property (nonatomic, strong) UIColor *color;

@end


#pragma mark - Show Simple Methods on window

@interface LLProgressHUD (Simple)

+ (instancetype)show;
+ (instancetype)showLoadingText:(NSString*)text;
+ (instancetype)showText:(NSString *)text;///< default delay 2.0 hide.
+ (instancetype)showText:(NSString *)text afterDelay:(NSTimeInterval)delay;
+ (instancetype)showSuccessText:(NSString*)text;///< default delay 2.0 hide.
+ (instancetype)showSuccessText:(NSString*)text afterDelay:(NSTimeInterval)delay;
+ (instancetype)showErrorText:(NSString*)text;///< default delay 2.0 hide.
+ (instancetype)showErrorText:(NSString*)text afterDelay:(NSTimeInterval)delay;
+ (instancetype)showWarningText:(NSString*)text;///< default delay 2.0 hide.
+ (instancetype)showWarningText:(NSString*)text afterDelay:(NSTimeInterval)delay;
+ (instancetype)showCustomView:(UIView *)view text:(NSString *)text afterDelay:(NSTimeInterval)delay;
+ (instancetype)showTextSuccess:(NSString*)text;///< default delay 1.5 hide.
+ (instancetype)showTextWarning:(NSString*)text;
+ (instancetype)showTextError:(NSString*)text;
+ (instancetype)showImage:(UIImage*)image text:(NSString*)text;
+ (instancetype)showImage:(UIImage*)image text:(NSString*)text afterDelay:(NSTimeInterval)delay;
+ (instancetype)showProgress;///< default mode
+ (instancetype)showProgressText:(NSString*)text;
+ (instancetype)showProgressText:(NSString*)text progressHUDMode:(LLProgressHUDMode)mode;
+ (instancetype)hide;

+ (instancetype)showText:(nullable NSString *)text
                progress:(float)progress
                   image:(nullable UIImage *)image
              customView:(nullable UIView *)view
                    mode:(LLProgressHUDMode)mode
              afterDelay:(NSTimeInterval)afterDelay;

@end
NS_ASSUME_NONNULL_END

