//
//  MBHudDemoViewController.m
//  HudDemo
//
//  Created by Matej Bukovinski on 30.9.09.
//  Copyright © 2009-2016 Matej Bukovinski. All rights reserved.
//
#import "ViewController.h"
#import "LLProgressHUD.h"
#import <QuartzCore/QuartzCore.h>

@interface MBExample : NSObject

@property (nonatomic, copy) NSString *title;
@property (nonatomic, assign) SEL selector;

@end


@implementation MBExample

+ (instancetype)exampleWithTitle:(NSString *)title selector:(SEL)selector {
    MBExample *example = [[self class] new];
    example.title = title;
    example.selector = selector;
    return example;
}

@end


@interface ViewController () <NSURLSessionDelegate,UITableViewDelegate,UITableViewDataSource>

@property (nonatomic, strong) NSArray<NSArray<MBExample *> *> *examples;
// Atomic, because it may be cancelled from main thread, flag is read on a background thread
@property (atomic, assign) BOOL canceled;

@property (nonatomic, strong) UITableView *tableView;

@end


@implementation ViewController

#pragma mark - Lifecycle
- (void)viewDidLoad{
    [super viewDidLoad];
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.sectionHeaderHeight = 10;
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"MBExampleCell"];
    [self.view addSubview:self.tableView];
    
    self.examples =
    @[@[[MBExample exampleWithTitle:@"show" selector:@selector(show)],
        [MBExample exampleWithTitle:@"showLoadingText:" selector:@selector(showLoadingText)],
        ],
      @[[MBExample exampleWithTitle:@"showText Center" selector:@selector(showTextCenter)],
        [MBExample exampleWithTitle:@"showText bottom" selector:@selector(showTextBottom)],
        [MBExample exampleWithTitle:@"showImage" selector:@selector(showImage)]],
      @[[MBExample exampleWithTitle:@"showProgress" selector:@selector(showProgress)],
        [MBExample exampleWithTitle:@"showProgress:text:" selector:@selector(showProgressText)],
        [MBExample exampleWithTitle:@"showProgress mode" selector:@selector(showProgressMode)]],
      @[[MBExample exampleWithTitle:@"showSuccessText" selector:@selector(showSuccessText)],
        [MBExample exampleWithTitle:@"showErrorText" selector:@selector(showErrorText)],
        [MBExample exampleWithTitle:@"showWarningText" selector:@selector(showWarningText)]],
      @[[MBExample exampleWithTitle:@"showCustomView" selector:@selector(showCustomView)],
        
        ],
      @[
        [MBExample exampleWithTitle:@"Dim background" selector:@selector(dimBackgroundExample)],
        [MBExample exampleWithTitle:@"Colored" selector:@selector(colorExample)],
        [MBExample exampleWithTitle:@"Loading Image" selector:@selector(LoadingImage)],
        [MBExample exampleWithTitle:@"backgroundColor" selector:@selector(backgroundStyle)],]
      ];
}
- (void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    
    self.tableView.frame = self.view.bounds;
}

#pragma mark - Examples

- (void)show {

    [LLProgressHUD show];
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        
        // Do something useful in the background
        [self doSomeWork];
        
        // IMPORTANT - Dispatch back to the main thread. Always access UI
        // classes (including LLProgressHUD) on the main thread.
        dispatch_async(dispatch_get_main_queue(), ^{
            [LLProgressHUD hide];
        });
    });
    
    
    
}

- (void)showLoadingText {
    LLProgressHUD *hud = [LLProgressHUD showLoadingText:NSLocalizedString(@"Loading...", @"HUD loading title")];
    hud.label.font = [UIFont italicSystemFontOfSize:20.f];
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        [self doSomeWork];
        dispatch_async(dispatch_get_main_queue(), ^{
            [LLProgressHUD hide];
        });
    });
}
- (void)showTextCenter{
    [LLProgressHUD showText:@"Text's Position is Center"];
}
- (void)showTextBottom{
    LLProgressHUD *hud = [LLProgressHUD showText:@"Text's Position is Center"];
    hud.offset = CGPointMake(0, LLProgressMaxOffset);
}
- (void)showImage {
    NSBundle *buddle = [NSBundle bundleWithPath:[[NSBundle bundleForClass:[ViewController class]] pathForResource:@"LLProgressHUD" ofType:@"bundle"]];
    UIImage *image = [UIImage imageWithContentsOfFile:[buddle pathForResource:@"warning" ofType:@"png"]];
    LLProgressHUD *hud = [LLProgressHUD showImage:image text:@"Message here!"];
    hud.label.imageSize = CGSizeMake(18, 18);
    
}
- (void)showProgress{
    LLProgressHUD *hud = [LLProgressHUD showProgress];
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        // Do something useful in the background and update the HUD periodically.
        [self doSomeWorkWithProgress];
        dispatch_async(dispatch_get_main_queue(), ^{
            [hud hideAnimated:YES];
        });
    });
}
- (void)showProgressText{
    LLProgressHUD *hud = [LLProgressHUD showProgressText:NSLocalizedString(@"Loading...", @"HUD loading title")];
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        // Do something useful in the background and update the HUD periodically.
        [self doSomeWorkWithProgress];
        dispatch_async(dispatch_get_main_queue(), ^{
            [hud hideAnimated:YES];
        });
    });
}
- (void)showProgressMode{
    LLProgressHUD *hud = [LLProgressHUD showProgress];
    hud.mode = LLProgressHUDModeDeterminateHorizontalBar;
    hud.label.text = NSLocalizedString(@"Loading...", @"HUD loading title");
    hud.label.image = [UIImage imageNamed:@"live"];
//    LLProgressHUD *hud = [LLProgressHUD showProgress:0 text:NSLocalizedString(@"Loading...", @"HUD loading title") progressHUDMode:LLProgressHUDModeDeterminateHorizontalBar];
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        // Do something useful in the background and update the HUD periodically.
        [self doSomeWorkWithProgress];
        dispatch_async(dispatch_get_main_queue(), ^{
            [hud hideAnimated:YES];
        });
    });
}

- (void)showSuccessText{
    [LLProgressHUD showSuccessText:@"Request Success"];
}
- (void)showErrorText{
    [LLProgressHUD showErrorText:@"Response Error"];
}
- (void)showWarningText{
    [LLProgressHUD showWarningText:@"Warning..."];
}
- (void)showCustomView{
    [LLProgressHUD showCustomView:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"live"]] text:@"Custom View" afterDelay:3];
}
- (void)dimBackgroundExample {
    
    LLProgressHUD *hud = [LLProgressHUD show];
    hud.backgroundView.color = [UIColor colorWithWhite:0.f alpha:0.1f];
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        [self doSomeWork];
        dispatch_async(dispatch_get_main_queue(), ^{
            [hud hideAnimated:YES];
        });
    });
}

- (void)colorExample {
    LLProgressHUD *hud = [LLProgressHUD showLoadingText:NSLocalizedString(@"Loading...", @"HUD loading title")];
    hud.contentColor = [UIColor colorWithRed:0.f green:0.6f blue:0.7f alpha:1.f];
    hud.margin = 8;
    hud.minSize = CGSizeMake(100, 100);
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        [self doSomeWork];
        dispatch_async(dispatch_get_main_queue(), ^{
            [hud hideAnimated:YES];
        });
    });
}
- (void)LoadingImage{
    LLProgressHUD *hud = [LLProgressHUD show];
    
    hud.backgroundView.color = [UIColor colorWithWhite:0.f alpha:0.1f];
    hud.indicatorImage = [UIImage imageNamed:@"loading"];
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        [self doSomeWork];
        dispatch_async(dispatch_get_main_queue(), ^{
            [hud hideAnimated:YES];
        });
    });
}
- (void)backgroundStyle{
    LLProgressHUD *hud = [LLProgressHUD show];
    hud.bezelView.color = [UIColor colorWithWhite:0.9 alpha:1];
    hud.contentColor = [UIColor blackColor];
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        [self doSomeWork];
        dispatch_async(dispatch_get_main_queue(), ^{
            [hud hideAnimated:YES];
        });
    });
}

#pragma mark - Tasks

- (void)doSomeWork {
    // Simulate by just waiting.
    sleep(3.);
}

- (void)doSomeWorkWithProgressObject:(NSProgress *)progressObject {
    // This just increases the progress indicator in a loop.
    while (progressObject.fractionCompleted < 1.0f) {
        if (progressObject.isCancelled) break;
        [progressObject becomeCurrentWithPendingUnitCount:1];
        [progressObject resignCurrent];
        usleep(50000);
    }
}

- (void)doSomeWorkWithProgress {
    self.canceled = NO;
    // This just increases the progress indicator in a loop.
    float progress = 0.0f;
    while (progress < 1.0f) {
        if (self.canceled) break;
        progress += 0.01f;
        dispatch_async(dispatch_get_main_queue(), ^{
            // Instead we could have also passed a reference to the HUD
            // to the HUD to myProgressTask as a method parameter.
            [LLProgressHUD HUDForWindow].progress = progress;
        });
        usleep(50000);
    }
}

- (void)doSomeWorkWithMixedProgress {
    LLProgressHUD *hud = [LLProgressHUD HUDForView:self.navigationController.view];
    // Indeterminate mode
    sleep(2);
    // Switch to determinate mode
    dispatch_async(dispatch_get_main_queue(), ^{
        hud.mode = LLProgressHUDModeDeterminate;
        hud.label.text = NSLocalizedString(@"Loading...", @"HUD loading title");
    });
    float progress = 0.0f;
    while (progress < 1.0f) {
        progress += 0.01f;
        dispatch_async(dispatch_get_main_queue(), ^{
            hud.progress = progress;
        });
        usleep(50000);
    }
    // Back to indeterminate mode
    dispatch_async(dispatch_get_main_queue(), ^{
        hud.mode = LLProgressHUDModeIndeterminate;
        hud.label.text = NSLocalizedString(@"Cleaning up...", @"HUD cleanining up title");
    });
    sleep(2);
    dispatch_sync(dispatch_get_main_queue(), ^{
        UIImage *image = [[UIImage imageNamed:@"Checkmark"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
        hud.customView = imageView;
        hud.mode = LLProgressHUDModeCustomView;
        hud.label.text = NSLocalizedString(@"Completed", @"HUD completed title");
    });
    sleep(2);
}

- (void)doSomeNetworkWorkWithProgress {
    NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfig delegate:self delegateQueue:nil];
    NSURL *URL = [NSURL URLWithString:@"https://support.apple.com/library/APPLE/APPLECARE_ALLGEOS/HT1425/sample_iPod.m4v.zip"];
    NSURLSessionDownloadTask *task = [session downloadTaskWithURL:URL];
    [task resume];
}

- (void)cancelWork:(id)sender {
    self.canceled = YES;
}

#pragma mark - UITableViewDelegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.examples.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.examples[section].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MBExample *example = self.examples[indexPath.section][indexPath.row];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MBExampleCell" forIndexPath:indexPath];
    cell.textLabel.text = example.title;
    cell.textLabel.textColor = self.view.tintColor;
    cell.textLabel.textAlignment = NSTextAlignmentCenter;
    cell.selectedBackgroundView = [UIView new];
    cell.selectedBackgroundView.backgroundColor = [cell.textLabel.textColor colorWithAlphaComponent:0.1f];
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    MBExample *example = self.examples[indexPath.section][indexPath.row];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [self performSelector:example.selector];
#pragma clang diagnostic pop
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    });
}

#pragma mark - NSURLSessionDelegate

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location {
    // Do something with the data at location...
    
    // Update the UI on the main thread
    dispatch_async(dispatch_get_main_queue(), ^{
        LLProgressHUD *hud = [LLProgressHUD HUDForView:self.navigationController.view];
        UIImage *image = [[UIImage imageNamed:@"Checkmark"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
        hud.customView = imageView;
        hud.mode = LLProgressHUDModeCustomView;
        hud.label.text = NSLocalizedString(@"Completed", @"HUD completed title");
        [hud hideAnimated:YES afterDelay:3.f];
    });
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    float progress = (float)totalBytesWritten / (float)totalBytesExpectedToWrite;
    
    // Update the UI on the main thread
    dispatch_async(dispatch_get_main_queue(), ^{
        LLProgressHUD *hud = [LLProgressHUD HUDForView:self.navigationController.view];
        hud.mode = LLProgressHUDModeDeterminate;
        hud.progress = progress;
    });
}

@end
