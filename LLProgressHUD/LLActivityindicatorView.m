//
//  LLActivityindicatorView.m
//  LLProgressHUD
//
//  Created by LianLeven on 2017/2/22.
//  Copyright © 2017年 LEVEN. All rights reserved.
//

#import "LLActivityindicatorView.h"

@interface LLActivityindicatorView ()

@property (nonatomic, strong) UIView *indicatorView;
@property (nonatomic, weak) CADisplayLink *loadingDisplayLink;

@end

@implementation LLActivityindicatorView
@synthesize loadingImage = _loadingImage;

- (instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        _hidesWhenStopped = YES;
        _color = [UIColor whiteColor];
        _activityIndicatorViewStyle = LLActivityindicatorViewStyleCustom;
        [self setActivityIndicatorViewStyle:LLActivityindicatorViewStyleCustom];
        
    }
    return self;
}
- (void)layoutSubviews{
    [super layoutSubviews];
    self.indicatorView.frame = self.bounds;
}
- (CGSize)intrinsicContentSize{
    return CGSizeMake(35, 35);
}
- (void)startAnimating{
    UIView *indicator = self.indicatorView;
    if ([indicator isKindOfClass:[UIImageView class]]) {
        if (!self.loadingDisplayLink) {
            CADisplayLink *displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(transformCircle)];
    
            [displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
            self.loadingDisplayLink = displayLink;
        }
    }else if ([indicator isKindOfClass:[UIActivityIndicatorView class]]){
        [((UIActivityIndicatorView *)indicator) startAnimating];
    }
}
- (void)stopAnimating{
    UIView *indicator = self.indicatorView;
    if ([indicator isKindOfClass:[UIImageView class]]) {
        if (self.loadingDisplayLink) {
            self.transform = CGAffineTransformIdentity;
            [_loadingDisplayLink invalidate];
            _loadingDisplayLink = nil;
        }
    }else if ([indicator isKindOfClass:[UIActivityIndicatorView class]]){
        [((UIActivityIndicatorView *)indicator) stopAnimating];
    }
    self.hidden = YES;
}
-(void)transformCircle{
    self.transform = CGAffineTransformRotate(self.transform, M_PI / 30.0);
}
#pragma mark - Getters and Setters
- (UIImage *)loadingImage{
    if (_loadingImage) {
        return _loadingImage;
    }
    NSBundle *buddle = [NSBundle bundleWithPath:[[NSBundle bundleForClass:[LLActivityindicatorView class]] pathForResource:@"LLProgressHUD" ofType:@"bundle"]];
    UIImage *image = [UIImage imageWithContentsOfFile:[buddle pathForResource:@"Loading@2x" ofType:@"png"]];
    image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    return image;
}
- (void)setActivityIndicatorViewStyle:(LLActivityindicatorViewStyle)activityIndicatorViewStyle{
    _activityIndicatorViewStyle = activityIndicatorViewStyle;
    UIView *indicator = self.indicatorView;
    if (activityIndicatorViewStyle == LLActivityindicatorViewStyleSystem) {
        [indicator removeFromSuperview];
        indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        [self addSubview:_indicatorView=indicator];
    }else{
        [indicator removeFromSuperview];
        indicator = [UIImageView new];
        UIImageView *indic = (UIImageView *)indicator;
        indic.tintColor = _color;
        indic.image = self.loadingImage;
        [self addSubview:_indicatorView = indic];
    }
    [self startAnimating];
}
- (void)setLoadingImage:(UIImage *)loadingImage{
    _loadingImage = loadingImage;
    UIView *indicator = self.indicatorView;
    if (loadingImage) {
        if ([indicator isKindOfClass:[UIImageView class]]) {
            ((UIImageView *)indicator).image = loadingImage;
        }else if([indicator isKindOfClass:[UIActivityIndicatorView class]]){
            self.activityIndicatorViewStyle = LLActivityindicatorViewStyleCustom;
        }
    }
}
- (void)setColor:(UIColor *)color{
    UIView *indicator = self.indicatorView;
    if (![_color isEqual:color] ) {
        _color = color;
        if ([indicator isKindOfClass:[UIImageView class]]) {
            ((UIImageView *)indicator).tintColor = color;
        }else if ([indicator isKindOfClass:[UIActivityIndicatorView class]]){
            ((UIActivityIndicatorView *)indicator).color = color;
        }
        
    }
    
}
- (BOOL)isAnimating{
    if (_loadingDisplayLink) return YES;
    UIView *indicator = self.indicatorView;
    if (indicator && [indicator isKindOfClass:[UIActivityIndicatorView class]]){
        return ((UIActivityIndicatorView *)indicator).isAnimating;
    }
    return NO;
}

@end
