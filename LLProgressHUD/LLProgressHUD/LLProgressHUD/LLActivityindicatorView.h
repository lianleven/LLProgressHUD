//
//  LLActivityindicatorView.h
//  LLProgressHUD
//
//  Created by LianLeven on 2017/2/22.
//  Copyright © 2017年 LEVEN. All rights reserved.
//

#import <UIKit/UIKit.h>
typedef NS_ENUM(NSInteger, LLActivityindicatorViewStyle) {
    LLActivityindicatorViewStyleCustom,
    LLActivityindicatorViewStyleSystem,
};
@interface LLActivityindicatorView : UIView

@property(nonatomic) LLActivityindicatorViewStyle activityIndicatorViewStyle; // default is LLActivityindicatorViewStyleCustom
@property (nonatomic, readonly, strong) UIActivityIndicatorView *activityIndicatorView;
@property(nonatomic) BOOL  hidesWhenStopped;           // default is YES.
@property (nonatomic, strong) UIColor *color;

- (void)startAnimating;
- (void)stopAnimating;
- (BOOL)isAnimating;


@end
