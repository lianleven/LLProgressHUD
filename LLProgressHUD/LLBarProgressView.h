//
//  LLBarProgressView.h
//  LLProgressHUD
//
//  Created by LianLeven on 2017/4/2.
//  Copyright © 2017年 LEVEN. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, LLBarProgressViewStyle) {
    LLBarProgressViewStyleLine,
    LLBarProgressViewStyleBarRadius,
};

@interface LLBarProgressView : UIView

@property (nonatomic, assign) float progress;                       ///< Progress (0.0 to 1.0)
@property (nonatomic, assign) LLBarProgressViewStyle progressStyle; ///< Defaults to LLBarProgressViewStyleBarRadius
@property (nonatomic, strong) UIColor *lineColor;               ///< Defaults to white [UIColor whiteColor].
@property (nonatomic, strong) UIColor *progressColor;      ///< Defaults to white [UIColor whiteColor].
@property (nonatomic, strong) UIColor *progressRemainingColor; ///< Defaults to clear [UIColor clearColor];


@end
