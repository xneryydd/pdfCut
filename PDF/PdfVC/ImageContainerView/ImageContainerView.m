//
//  ImageContainerView.m
//  PDF
//
//  Created by 赢赢淡淡小奈尔 on 2024/10/28.
//

#import "ImageContainerView.h"
#import "PdfCutView.h"

@interface ImageContainerView ()


@end

@implementation ImageContainerView

- (instancetype)initWithImage:(NSImage *)image {
    // 设置容器的初始框架大小（加上边距）
    self = [super initWithFrame:NSMakeRect(0, 0, image.size.width + 230, image.size.height + 40)];
    if (self) {
        self.wantsLayer = YES;
        self.layer.backgroundColor = [[NSColor whiteColor] CGColor];
        
        self.zoomFactor = 1.0; // 默认缩放因子
        
        // 初始化 initialImageSize
        self.initialImageSize = image.size; // 记录初始图像大小

        // 设置 imageView
        self.imageView = [[NSImageView alloc] initWithFrame:NSZeroRect];
        self.imageView.image = image;
        self.imageView.wantsLayer = YES;
        self.imageView.layer.borderWidth = 2.0;
        self.imageView.layer.borderColor = [[NSColor blackColor] CGColor];
        self.imageView.translatesAutoresizingMaskIntoConstraints = NO; // 使用 Auto Layout
        [self addSubview:self.imageView];
        
        // 添加 Auto Layout 约束，确保 imageView 居中
        [self.imageView.centerXAnchor constraintEqualToAnchor:self.centerXAnchor].active = YES;
        [self.imageView.centerYAnchor constraintEqualToAnchor:self.centerYAnchor].active = YES;
        
        [self updateImageViewSize]; // 初始化图像视图大小
    }
    return self;
}

// 重写 setFrameSize: 方法，以根据 imageView 的大小调整容器视图的大小
- (void)setFrameSize:(NSSize)newSize {
    CGFloat paddingWidth = 80; // 左右边距
    CGFloat paddingHeight = 40;  // 上下边距
    
    self.superScrollViewSize = newSize;
    
    // 更新容器的大小，保留边距
    CGFloat finalWidth = MAX(newSize.width, self.imageView.image.size.width + paddingWidth);
    CGFloat finalHeight = MAX(newSize.height, self.imageView.image.size.height + paddingHeight);

    // 调用父类方法设置新大小
    [super setFrameSize:NSMakeSize(finalWidth, finalHeight)];
    
    // 调整 imageView 的居中
    [self centerImageView];
}

- (void)setImage:(NSImage *)image {
    // 设置新的图像并更新
    self.imageView.image = image;
    
    // 更新 initialImageSize
    self.initialImageSize = image.size;
    
    // 更新 imageView 尺寸以适应新图像大小
    [self updateImageViewSize];
    
    // 调整 imageView 居中
    [self centerImageView];
    
    // 重新布局视图
    [self setNeedsDisplay:YES];
}

// 更新 imageView 大小
- (void)updateImageViewSize {
    NSLog(@"1");
    if (self.imageView && self.imageView.image) {
        // 使用 initialImageSize 和 zoomFactor 计算缩放后的宽高
        CGFloat newWidth = self.initialImageSize.width * self.zoomFactor;
        CGFloat newHeight = self.initialImageSize.height * self.zoomFactor;

        NSLog(@"%f, %f", newWidth, newHeight);
        
        // 创建一个新的 NSImage，用于承载缩放后的图像
        NSImage *scaledImage = [[NSImage alloc] initWithSize:NSMakeSize(newWidth, newHeight)];
        [scaledImage lockFocus];

        // 绘制原始图像到新的大小
        [self.imageView.image drawInRect:NSMakeRect(0, 0, newWidth, newHeight)];
        
        [scaledImage unlockFocus];

        // 更新 imageView 的图像为缩放后的图像
        self.imageView.image = scaledImage;

        // 更新 imageView 尺寸
        self.imageView.frame = NSMakeRect(0, 0, newWidth, newHeight);
        
        
        [self setFrameSize:self.superScrollViewSize];
        
        // 调整 imageView 的居中
        [self centerImageView];
    }
}


// 中心对齐 imageView
- (void)centerImageView {
    // 计算 imageView 的位置以使其居中
    CGFloat xPosition = (self.frame.size.width - self.imageView.frame.size.width * self.zoomFactor) / 2;
    CGFloat yPosition = (self.frame.size.height - self.imageView.frame.size.height * self.zoomFactor) / 2;

    // 更新 imageView 的位置
    self.imageView.frame = NSMakeRect(xPosition, yPosition, self.imageView.frame.size.width * self.zoomFactor, self.imageView.frame.size.height * self.zoomFactor);
}

// 缩放方法
- (void)zoomChange:(float)zoomValue {
    self.zoomFactor = zoomValue / 100.0; // 转换为比例
    [self updateImageViewSize];
    [self setNeedsDisplay:YES]; // 触发重新布局
}

// 剪切模式切换
- (void)enableCropMode:(id<PdfCutViewDelegate>)delegate {
    NSLog(@"%f, %f", self.imageView.image.size.width, self.imageView.image.size.height);
    if (!self.pdfCutView) {
        
        self.isCropModeEnabled = YES;

        // 初始化并添加 pdfCutView
        NSRect imageViewFrame = NSMakeRect(self.imageView.frame.origin.x - 40, self.imageView.frame.origin.y - 20, self.imageView.image.size.width + 80, self.imageView.image.size.height + 40);
        
        PdfCutView *pdfCutViewInstance = [[PdfCutView alloc] initWithFrame:imageViewFrame delegate:delegate];
        self.pdfCutView = pdfCutViewInstance;
        self.pdfCutView.image = self.imageView.image;
        [self addSubview:self.pdfCutView positioned:NSWindowAbove relativeTo:self.imageView];

        NSLog(@"已进入剪切模式。");
    } else {
        self.isCropModeEnabled = NO;

        // 移除 pdfCutView
        [self.pdfCutView removeFromSuperview];
        self.pdfCutView = nil; // 释放 pdfCutView

        NSLog(@"已退出剪切模式。");
    }
}

@end
