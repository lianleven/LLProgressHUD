//
//  LLActivityindicatorView.m
//  LLProgressHUD
//
//  Created by LianLeven on 2017/2/22.
//  Copyright © 2017年 LEVEN. All rights reserved.
//

#import "LLActivityindicatorView.h"

@interface LLActivityindicatorView ()

@property (nonatomic, strong) UIImageView *loadingView;
@property (nonatomic, weak) CADisplayLink *loadingDisplayLink;

@end

@implementation LLActivityindicatorView

- (instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        _hidesWhenStopped = YES;
        _color = [UIColor whiteColor];
        self.loadingView.tintColor = _color;
        [self addSubview:self.loadingView];
    }
    return self;
}
- (void)layoutSubviews{
    [super layoutSubviews];
    self.loadingView.frame = self.bounds;
}
- (CGSize)intrinsicContentSize{
    return CGSizeMake(30, 30);
}
- (void)startAnimating{
    if (!self.loadingDisplayLink) {
        CADisplayLink *displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(transformCircle)];
        
        [displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
        self.loadingDisplayLink = displayLink;
    }
    
}
- (void)stopAnimating{
    
    if (self.loadingDisplayLink) {
        self.transform = CGAffineTransformIdentity;
        [_loadingDisplayLink invalidate];
        _loadingDisplayLink = nil;
        self.hidden = YES;
    }
}
-(void)transformCircle{
    self.transform = CGAffineTransformRotate(self.transform, M_PI / 30.0);
}
#pragma mark - Getters and Setters
- (void)setColor:(UIColor *)color{
    if (![_color isEqual:color] ) {
        _color = color;
        self.loadingView.tintColor = color;
    }
    
}
- (BOOL)isAnimating{
    if (_loadingDisplayLink) return YES;
    return NO;
}
- (UIImageView *)loadingView{
    if (!_loadingView) {
        _loadingView = [UIImageView new];
        NSBundle *buddle = [NSBundle bundleWithPath:[[NSBundle bundleForClass:[LLActivityindicatorView class]] pathForResource:@"LLProgressHUD" ofType:@"bundle"]];
        UIImage *image = [UIImage imageWithContentsOfFile:[buddle pathForResource:@"Loading@2x" ofType:@"png"]];
        image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        _loadingView.image = image;
        _loadingView.tintColor = _color;
    }
    return _loadingView;
}
@end
