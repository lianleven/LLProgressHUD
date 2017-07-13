//
//  LLTextLabel.h
//  LLProgressHUD
//
//  Created by LianLeven on 2017/4/11.
//  Copyright © 2017年 LEVEN. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LLTextLabel : UILabel

@property (nonatomic, strong) UIImage *image;
@property (nonatomic, assign) CGSize imageSize;
@property (nonatomic, assign) CGFloat spacing; ///< default is " " width
@property (nonatomic, strong) UIColor *imageTintColor; ///< default is nil


@end
