//
//  PdfCutView.m
//  PDF
//
//  Created by 赢赢淡淡小奈尔 on 2024/10/25.
//

#import "PdfCutView.h"

@interface PdfCutView ()

typedef NS_ENUM(NSInteger, DraggingState) {
    DraggingStateNone = 0,   // 0: 没有拖动
    DraggingStateStartingX = 1,   // 1: 起始点X移动
    DraggingStateEndingX = 2,   //2: 结束点X移动
    DraggingStateStartingY = 3,   // 1: 起始点Y移动
    DraggingStateEndingY = 4,   //2: 结束点Y移动
    DraggingStateFirst = 5

};

@property (nonatomic, weak) id<PdfCutViewDelegate> delegate;
@property (nonatomic, assign) CGPoint startPoint;
@property (nonatomic, assign) CGPoint endPoint;
@property (nonatomic, assign) BOOL isDraggingBorder;  // 用于拖动边框
@property (nonatomic, assign) DraggingState draggingState; // 当前拖动状态

@property (nonatomic, strong) NSTextField *sizeLabel; // 用于显示宽高的标签

@property (assign) CGFloat MaxY;
@property (assign) CGFloat MinY;
@property (assign) CGFloat MaxX;
@property (assign) CGFloat MinX;



@end

@implementation PdfCutView

- (instancetype)initWithFrame:(NSRect)frame delegate:(id<PdfCutViewDelegate>)delegate {
    self = [super initWithFrame:frame];
    if (self) {
        self.delegate = delegate;  // 设置 delegate
        
        self.MinX = frame.origin.x + 6;
        self.MinY = frame.origin.y + 20;
        self.MaxX = frame.origin.x + frame.size.width - 76;
        self.MaxY = frame.origin.y + frame.size.height - 20;
        
//        self.MinX = 0;
//        self.MinY = 0;
//        self.MaxX = 2000;
//        self.MaxY = 2000;
        
//        [self commonInit];
    }
    return self;
}

- (void)mouseDown:(NSEvent *)event {
    CGPoint point = [self convertPoint:event.locationInWindow fromView:nil];
    
    // 创建边框区域
    NSRect selectionRect = NSMakeRect(fmin(self.startPoint.x, self.endPoint.x),
                                      fmin(self.startPoint.y, self.endPoint.y),
                                      fabs(self.endPoint.x - self.startPoint.x),
                                      fabs(self.endPoint.y - self.startPoint.y));
    
    // 创建边框区域的扩展区域
    NSRect borderRect = NSInsetRect(selectionRect, -5.0, -5.0); // 增加宽度
    
    // 检查点击位置是否在边框区域内
    if (NSPointInRect(point, borderRect)) {
        self.isDraggingBorder = YES;
        
        // 判断点击的是哪个边缘区域，设置为正在调整大小
        if (fabs(point.x - self.startPoint.x) < 5.0) {
            self.draggingState = 1; // 起始点X移动
        } else if (fabs(point.x - self.endPoint.x) < 5.0) {
            self.draggingState = 2; // 结束点X移动
        } else if (fabs(point.y - self.startPoint.y) < 5.0) {
            self.draggingState = 3; // 起始点Y移动
        } else if (fabs(point.y - self.endPoint.y) < 5.0) {
            self.draggingState = 4; // 结束点Y移动
        } else if (NSEqualPoints(self.endPoint, NSZeroPoint)) {
            self.draggingState = 5; // 其他区域拖动
        }
    } else {
        // 如果不在边框区域，开始新的选择
        if (NSEqualPoints(self.startPoint, NSZeroPoint)) {
            // 第一次绘制
            self.startPoint = point;
            self.endPoint = point;
            
            self.isDraggingBorder = YES;
            self.draggingState = 5;
            
            // 创建标签，如果标签还不存在
            if (!self.sizeLabel) {
                self.sizeLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(point.x + 10, point.y + 10, 100, 20)];
                self.sizeLabel.backgroundColor = [NSColor colorWithWhite:0 alpha:0.5];
                self.sizeLabel.textColor = [NSColor blackColor];
                self.sizeLabel.font = [NSFont systemFontOfSize:12];
                self.sizeLabel.alignment = NSTextAlignmentCenter;
                self.sizeLabel.bordered = NO;
                self.sizeLabel.editable = NO;
                self.sizeLabel.bezeled = NO;
                [self addSubview:self.sizeLabel];
            }
        }
    }
}

- (void)mouseDragged:(NSEvent *)event {
    if (self.isDraggingBorder) {
        NSPoint point = [self convertPoint:event.locationInWindow fromView:nil];
        
        if (self.draggingState == 1) {
            // 从左边拖动
            CGPoint newStartPoint = self.startPoint;
            newStartPoint.x = point.x; // 更新左边的 x 坐标
            [self setStartPoint:newStartPoint];  // 调用 setter 方法
        } else if (self.draggingState == 2) {
            // 从右边拖动
            CGPoint newEndPoint = self.endPoint;
            newEndPoint.x = point.x; // 更新右边的 x 坐标
            [self setEndPoint:newEndPoint];  // 调用 setter 方法
        } else if (self.draggingState == 3) {
            // 从上边拖动
            CGPoint newStartPoint = self.startPoint;
            newStartPoint.y = point.y; // 更新上边的 y 坐标
            [self setStartPoint:newStartPoint];  // 调用 setter 方法
        } else if (self.draggingState == 4) {
            // 从下边拖动
            CGPoint newEndPoint = self.endPoint;
            newEndPoint.y = point.y; // 更新下边的 y 坐标
            [self setEndPoint:newEndPoint];  // 调用 setter 方法
        } else if (self.draggingState == 5) {
            // 第一次绘制时终点的改变
            [self setEndPoint:point];  // 调用 setter 方法
        }
        
        // 计算宽度和高度
        CGFloat width = fabs(self.endPoint.x - self.startPoint.x);
        CGFloat height = fabs(self.endPoint.y - self.startPoint.y);
        
        // 更新标签内容
        self.sizeLabel.stringValue = [NSString stringWithFormat:@"W: %.0f H: %.0f", width, height];
        
        // 重新定位标签，放置在选择区域附近
        CGFloat labelX = fmin(self.startPoint.x, self.endPoint.x) + 10;
        CGFloat labelY = fmax(self.startPoint.y, self.endPoint.y) + 10;
        self.sizeLabel.frame = NSMakeRect(labelX, labelY, 100, 20);
        
        [self setNeedsDisplay:YES];
        [self removeButtons];
    }
}

- (void)mouseUp:(NSEvent *)event {
    self.isDraggingBorder = NO; // 停止拖动边框
    self.draggingState = 0;
    
    [self showActionButtonsAtPoint:self.endPoint];
    
//    NSLog(@"start.x = %f, start.y = %f, end.x = %f, end.y = %f, int = %ld", self.startPoint.x, self.startPoint.y, self.endPoint.x, self.endPoint.y, (long)self.draggingState);
}


#pragma 剪切点变化限制
- (void)setStartPoint:(CGPoint)startPoint {
    startPoint.x = fmax(self.MinX, fmin(self.MaxX, startPoint.x));
    startPoint.y = fmax(self.MinY, fmin(self.MaxY, startPoint.y));
//    
    _startPoint = startPoint;  // 将限制后的值赋给 _startPoint
}

// 自定义 endPoint 的 setter 方法，限制其坐标
- (void)setEndPoint:(CGPoint)endPoint {
    endPoint.x = fmax(self.MinX, fmin(self.MaxX, endPoint.x));
    endPoint.y = fmax(self.MinY, fmin(self.MaxY, endPoint.y));
    
    _endPoint = endPoint;  // 将限制后的值赋给 _endPoint
}


- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];

//    NSLog(@"Drawing selection rect at startPoint: %@, endPoint: %@", NSStringFromPoint(self.startPoint), NSStringFromPoint(self.endPoint));

    if (!CGPointEqualToPoint(self.startPoint, self.endPoint)) {
        NSRect selectionRect = NSMakeRect(fmin(self.startPoint.x, self.endPoint.x),
                                          fmin(self.startPoint.y, self.endPoint.y),
                                          fabs(self.endPoint.x - self.startPoint.x),
                                          fabs(self.endPoint.y - self.startPoint.y));

        // 绘制半透明填充
        [[NSColor colorWithWhite:1.0 alpha:0.3] setFill];
        NSRectFillUsingOperation(selectionRect, NSCompositingOperationSourceOver);

        // 绘制边框
        [[NSColor redColor] setStroke]; // 设置边框颜色为红色
        NSBezierPath *borderPath = [NSBezierPath bezierPathWithRect:NSInsetRect(selectionRect, -2.5, -2.5)];
        borderPath.lineWidth = 5.0; // 设置边框宽度
        [borderPath stroke]; // 绘制边框
    }
}

- (void)showActionButtonsAtPoint:(NSPoint)point {
    // 计算按钮位置
    NSRect buttonRect = NSMakeRect(point.x + 10, point.y - 30, 60, 30); // 右上角的按钮位置

    // 创建“完成”按钮
    NSButton *finishButton = [[NSButton alloc] initWithFrame:buttonRect];
    finishButton.wantsLayer = YES; // 启用 CALayer 支持
    finishButton.layer.backgroundColor = [NSColor blackColor].CGColor; // 设置背景为黑色
    
    NSDictionary *finishAttributes = @{
        NSForegroundColorAttributeName: [NSColor whiteColor],
        NSFontAttributeName: [NSFont systemFontOfSize:14]
    };
    NSAttributedString *finishAttributedTitle = [[NSAttributedString alloc] initWithString:@"完成" attributes:finishAttributes];
    [finishButton setAttributedTitle:finishAttributedTitle];
    
    [finishButton setTarget:self];
    [finishButton setAction:@selector(finishCropping)];
    [self addSubview:finishButton];

    // 创建“取消”按钮
    buttonRect.origin.y -= 40; // 调整位置
    NSButton *cancelButton = [[NSButton alloc] initWithFrame:buttonRect];
    cancelButton.wantsLayer = YES; // 启用 CALayer 支持
    cancelButton.layer.backgroundColor = [NSColor blackColor].CGColor; // 设置背景为黑色

    NSDictionary *cancelAttributes = @{
        NSForegroundColorAttributeName: [NSColor whiteColor],
        NSFontAttributeName: [NSFont systemFontOfSize:14]
    };
    NSAttributedString *cancelAttributedTitle = [[NSAttributedString alloc] initWithString:@"取消" attributes:cancelAttributes];
    [cancelButton setAttributedTitle:cancelAttributedTitle];

    [cancelButton setTarget:self];
    [cancelButton setAction:@selector(cancelCropping)];
    [self addSubview:cancelButton];
}


- (void)finishCropping {
    CGFloat imageWidth = self.image.size.width;
    CGFloat imageHeight = self.image.size.height;
    
    CGRect pointRect = CGRectMake(fmin(_startPoint.x, _endPoint.x) - 40, fmin(_startPoint.y, _endPoint.y) - 20, fabs(_startPoint.x - _endPoint.x), fabs(_startPoint.y - _endPoint.y));
    
    [self.delegate pdfCutView:self didSelectFrame:pointRect imageWidth:imageWidth imageHeight:imageHeight];
}

- (void)cancelCropping {
    NSLog(@"尝试结束");
    [self removeFromSuperview];
}

- (void)removeButtons {
    for (NSView *subview in [self subviews]) {
        if ([subview isKindOfClass:[NSButton class]]) {
            [subview removeFromSuperview];
        }
    }
}

- (void)cropImage {
    NSRect selectionRect = NSMakeRect(fmin(self.startPoint.x, self.endPoint.x),
                                      fmin(self.startPoint.y, self.endPoint.y),
                                      fabs(self.endPoint.x - self.startPoint.x),
                                      fabs(self.endPoint.y - self.startPoint.y));

    // 裁剪当前 imageView 中的图片
    NSImage *croppedImage = [self cropImage:self.image withRect:selectionRect];

    if (croppedImage) {
        NSLog(@"裁剪后的图像存在。");

        // 选择保存文件的类型
        NSInteger saveType = 2; // 1: PNG, 2: PDF

        // 创建保存面板
        NSSavePanel *savePanel = [NSSavePanel savePanel];
        
        // 设置允许的文件类型和默认文件名
        if (saveType == 1) {
            [savePanel setAllowedFileTypes:@[@"png"]];
            [savePanel setNameFieldStringValue:@"croppedImage.png"];
        } else if (saveType == 2) {
            [savePanel setAllowedFileTypes:@[@"pdf"]];
            [savePanel setNameFieldStringValue:@"croppedImage.pdf"];
        }

        // 显示保存面板
        [savePanel beginWithCompletionHandler:^(NSInteger result) {
            if (result == NSModalResponseOK) {
                NSURL *selectedURL = [savePanel URL];

                // 根据用户选择的文件类型保存图像
                if (saveType == 1) {
                    NSData *pngData = [self imageDataFromImage:croppedImage];
                    if (pngData) {
                        NSError *error = nil;
                        BOOL success = [pngData writeToURL:selectedURL options:NSDataWritingAtomic error:&error];
                        if (success) {
                            NSLog(@"裁剪后的图像已保存到: %@", selectedURL.path);
                        } else {
                            NSLog(@"保存失败：%@", error.localizedDescription);
                        }
                    } else {
                        NSLog(@"无法获取 PNG 数据，裁剪未成功");
                    }
                } else if (saveType == 2) {
                    NSData *pdfData = [self pdfDataFromImage:croppedImage];
                    if (pdfData) {
                        NSError *error = nil;
                        BOOL success = [pdfData writeToURL:selectedURL options:NSDataWritingAtomic error:&error];
                        if (success) {
                            NSLog(@"裁剪后的图像已保存为 PDF 到: %@", selectedURL.path);
                        } else {
                            NSLog(@"保存失败：%@", error.localizedDescription);
                        }
                    } else {
                        NSLog(@"无法获取 PDF 数据，裁剪未成功");
                    }
                }
            }
        }];
    } else {
        NSLog(@"裁剪后的图像为 nil，裁剪失败。");
    }
}


- (NSData *)imageDataFromImage:(NSImage *)image {
    NSSize imageSize = [image size];

    // 创建一个 NSBitmapImageRep
    NSBitmapImageRep *bitmapRep = [[NSBitmapImageRep alloc]
        initWithBitmapDataPlanes:NULL
                      pixelsWide:imageSize.width
                      pixelsHigh:imageSize.height
                   bitsPerSample:8
                 samplesPerPixel:4
                        hasAlpha:YES
                        isPlanar:NO
                  colorSpaceName:NSDeviceRGBColorSpace
                     bytesPerRow:0
                    bitsPerPixel:0];

    if (bitmapRep) {
        // 锁定 focus 并绘制图像
        [NSGraphicsContext saveGraphicsState];
        NSGraphicsContext *context = [NSGraphicsContext graphicsContextWithBitmapImageRep:bitmapRep];
        [NSGraphicsContext setCurrentContext:context];

        [image drawInRect:NSMakeRect(0, 0, imageSize.width, imageSize.height)];

        [NSGraphicsContext restoreGraphicsState];

        // 生成 PNG 数据
        return [bitmapRep representationUsingType:NSBitmapImageFileTypePNG properties:@{}];
    } else {
        NSLog(@"无法创建 NSBitmapImageRep");
        return nil;
    }
}

- (NSData *)pdfDataFromImage:(NSImage *)image {
    NSSize imageSize = [image size];

    // 创建一个可变的 PDF 数据对象
    NSMutableData *pdfData = [NSMutableData data];

    // 创建 PDF 文档的上下文
    CGDataConsumerRef dataConsumer = CGDataConsumerCreateWithCFData((__bridge CFMutableDataRef)pdfData);
    CGRect mediaBox = CGRectMake(0, 0, imageSize.width, imageSize.height);
    CGContextRef pdfContext = CGPDFContextCreate(dataConsumer, &mediaBox, NULL);
    CGDataConsumerRelease(dataConsumer);

    if (!pdfContext) {
        NSLog(@"无法创建 PDF 上下文");
        return nil;
    }

    // 开始 PDF 页面
    CGPDFContextBeginPage(pdfContext, NULL);

    // 创建 NSGraphicsContext 以便绘制到 PDF 中
    NSGraphicsContext *graphicsContext = [NSGraphicsContext graphicsContextWithCGContext:pdfContext flipped:NO];
    [NSGraphicsContext saveGraphicsState];
    [NSGraphicsContext setCurrentContext:graphicsContext];

    // 绘制图像
    [image drawInRect:NSMakeRect(0, 0, imageSize.width, imageSize.height)];

    // 结束 PDF 页面
    CGPDFContextEndPage(pdfContext);

    // 释放 PDF 上下文
    CGPDFContextClose(pdfContext);
    CGContextRelease(pdfContext);

    [NSGraphicsContext restoreGraphicsState];

    // 返回生成的 PDF 数据
    return pdfData;
}

- (NSImage *)cropImage:(NSImage *)image withRect:(NSRect)cropRect {
    NSImage *croppedImage = [[NSImage alloc] initWithSize:cropRect.size];

    [croppedImage lockFocus];
    NSRect fromRect = NSMakeRect(cropRect.origin.x, cropRect.origin.y, cropRect.size.width, cropRect.size.height);
    [image drawInRect:NSMakeRect(0, 0, cropRect.size.width, cropRect.size.height)
             fromRect:fromRect
            operation:NSCompositingOperationSourceOver
             fraction:1.0];
    [croppedImage unlockFocus];

    return croppedImage;
}

- (void)dealloc {
    NSLog(@"剪切结束");
}

@end
