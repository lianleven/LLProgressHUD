//
//  LLTextLabel.m
//  LLProgressHUD
//
//  Created by LianLeven on 2017/4/11.
//  Copyright © 2017年 LEVEN. All rights reserved.
//

#import "LLTextLabel.h"


@interface LLTextLabel ()

@property (nonatomic, strong) NSString *imageAttributedString;

@end

@implementation LLTextLabel

@synthesize imageSize = _imageSize;

- (void)updateAttributedText{
    UIFont *font = self.font;
    if (!font) font = [UIFont systemFontOfSize:12];
    NSMutableAttributedString *text = [NSMutableAttributedString new];
    {
        
        NSAttributedString *attachmentString = nil;
        if (_image) {
            if (self.imageTintColor && _image) {
                _image = [LLTextLabel colorImage:_image color:_imageTintColor];
            }
            attachmentString = [LLTextLabel attachmentStringWithImage:_image attachmentSize:self.imageSize font:font];
            
        }
        if (attachmentString) {
            [text appendAttributedString:attachmentString];
            [text addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor] range:NSMakeRange(0, text.length)];
            [text appendAttributedString:[[NSAttributedString alloc] initWithString:@" "]];
        }
        if (self.text && [self.text isKindOfClass:[NSString class]]) {
            [text appendAttributedString:[[NSAttributedString alloc] initWithString:self.text]];
        }
    }
    self.attributedText = text;
}
#pragma mark - Setters

- (void)setImage:(UIImage *)image{
    _image = image;
    
    [self updateAttributedText];
}
- (void)setImageTintColor:(UIColor *)imageTintColor{
    _imageTintColor = imageTintColor;
    [self updateAttributedText];
}
- (void)setImageSize:(CGSize)imageSize{
    _imageSize = imageSize;
    [self updateAttributedText];
}
- (void)setText:(NSString *)text{
    [super setText:text];
    [self updateAttributedText];
}
- (void)setFont:(UIFont *)font{
    [super setFont:font];
    [self updateAttributedText];
}
#pragma mark - Getters
- (CGSize)imageSize{
    if (!CGSizeEqualToSize(_imageSize, CGSizeZero)) {
        return _imageSize;
    }
    return CGSizeMake(18, 18);
}
+ (NSAttributedString *)attachmentStringWithImage:(UIImage *)image
                                   attachmentSize:(CGSize)attachmentSize
                                             font:(UIFont *)font{
    CGFloat fontHeight = font.ascender - font.descender;
    CGFloat yOffset = font.ascender - fontHeight * 0.5;
    CGFloat ascent = attachmentSize.height * 0.5 + yOffset;
    CGFloat descent = ascent - attachmentSize.height;
    
    NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
    attachment.image = image;
    attachment.bounds = CGRectMake(0, descent, attachmentSize.width, attachmentSize.height);
    
    return [NSAttributedString attributedStringWithAttachment:attachment];
    
}
+ (UIImage *)colorImage:(UIImage *)image color:(UIColor *)color
{
    UIGraphicsBeginImageContextWithOptions(image.size, NO, [UIScreen mainScreen].scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextTranslateCTM(context, 0, image.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    CGRect rect = CGRectMake(0, 0, image.size.width, image.size.height);
    
    CGContextSetBlendMode(context, kCGBlendModeNormal);
    CGContextDrawImage(context, rect, image.CGImage);
    CGContextSetBlendMode(context, kCGBlendModeSourceIn);
    [color setFill];
    CGContextFillRect(context, rect);
    
    
    UIImage *coloredImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return coloredImage;
}

@end
