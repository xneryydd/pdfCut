//
//  PdfVC.m
//  PDF
//
//  Created by 赢赢淡淡小奈尔 on 2024/10/24.
//

#import "PdfView.h"
#import "ImageContainerView.h"
#import <Quartz/Quartz.h>

@interface PdfView ()  <PdfCutViewDelegate>

@property (strong) NSScrollView *imageScrollView;
@property (strong) NSScrollView *contentScrollView;
@property (assign) CGFloat offsetX;

@end

@implementation PdfView

- (instancetype)initWithFileURL:(NSURL *)pdfURL width:(CGFloat)width height:(CGFloat)height {
    self = [super initWithFrame:NSMakeRect(0, 0, width, height)];
    if (self) {
        self.wantsLayer = YES;
        
        // 初始化左侧缩略图 ScrollView
        self.offsetX = 150;
        self.contentScrollView = [[NSScrollView alloc] initWithFrame:NSMakeRect(0, 0, self.offsetX, self.bounds.size.height)];
        self.contentScrollView.hasVerticalScroller = YES;
        self.contentScrollView.backgroundColor = [NSColor lightGrayColor];
        [self.contentScrollView setWantsLayer:YES];
        [self addSubview:self.contentScrollView];
        
        // 初始化右侧内容显示 ScrollView
        self.imageScrollView = [[NSScrollView alloc] initWithFrame:NSMakeRect(self.offsetX, 0, self.bounds.size.width - self.offsetX, self.bounds.size.height)];
        self.imageScrollView.hasVerticalScroller = YES;
        self.imageScrollView.hasHorizontalScroller = YES;
        self.imageScrollView.backgroundColor = [NSColor blackColor];
        [self.imageScrollView setWantsLayer:YES];
        [self addSubview:self.imageScrollView];
        
        // 加载 PDF 文件
        self.pdfDoc = [[PDFDocument alloc] initWithURL:pdfURL];
        if (self.pdfDoc) {
            // 显示 PDF 缩略图
            [self displayThumbnailsInContentScrollView];
            
            // 生成第一个页面的图像并显示
            PDFPage *firstPage = [self.pdfDoc pageAtIndex:0];
            NSImage *firstPageImage = [firstPage thumbnailOfSize:NSMakeSize(800, 1200) forBox:kPDFDisplayBoxMediaBox];
            
            // 创建右侧显示页面的 ImageContainerView，只显示一个图像
            ImageContainerView *imageCV = [[ImageContainerView alloc] initWithImage:firstPageImage];
            
            self.imageCV = imageCV;
            self.imageScrollView.documentView = self.imageCV;
            
            // 滚动到顶部
            [self.imageScrollView.contentView scrollToPoint:NSMakePoint(0, self.imageCV.bounds.size.height - self.imageScrollView.contentSize.height)];
            [self.imageScrollView reflectScrolledClipView:self.imageScrollView.contentView];
            
        } else {
            NSLog(@"无法加载 PDF 文件");
        }
    }
    return self;
}

// 显示缩略图方法
- (void)displayThumbnailsInContentScrollView {
    NSView *thumbnailContainer = [[NSView alloc] init];
    CGFloat yOffset = 10; // 缩略图间距
    
    for (NSInteger i = 0; i < self.pdfDoc.pageCount; i++) {
        PDFPage *page = [self.pdfDoc pageAtIndex:i];
        NSImage *thumbnailImage = [page thumbnailOfSize:NSMakeSize(100, 140) forBox:kPDFDisplayBoxMediaBox];
        
        // 使用 NSButton 代替 NSImageView
        NSButton *thumbnailButton = [[NSButton alloc] initWithFrame:NSMakeRect(10, yOffset, 130, 180)];
        [thumbnailButton setImage:thumbnailImage];
        [thumbnailButton setBordered:NO]; // 无边框按钮
        thumbnailButton.wantsLayer = YES;
        thumbnailButton.layer.borderWidth = 1.0;
        thumbnailButton.layer.borderColor = [[NSColor darkGrayColor] CGColor];
        
        // 设置点击事件
        thumbnailButton.target = self;
        thumbnailButton.action = @selector(thumbnailClicked:);
        
        // 设置按钮的 tag 属性为页面索引
        thumbnailButton.tag = i;
        
        [thumbnailContainer addSubview:thumbnailButton];
        
        yOffset += 190; // 下一个缩略图的位置
    }
    
    [thumbnailContainer setFrame:NSMakeRect(0, 0, self.offsetX, yOffset)];
    self.contentScrollView.documentView = thumbnailContainer;
}

// 缩略图点击事件处理
- (void)thumbnailClicked:(NSButton *)thumbnailButton {
    NSInteger pageIndex = thumbnailButton.tag;
    PDFPage *selectedPage = [self.pdfDoc pageAtIndex:pageIndex];
    NSImage *selectedPageImage = [selectedPage thumbnailOfSize:NSMakeSize(800, 1200) forBox:kPDFDisplayBoxMediaBox];
    
    // 更新 imageCV 显示选中的页面图像
    if (self.imageCV) {
        [self.imageCV setImage:selectedPageImage];
        [self.imageScrollView.contentView scrollToPoint:NSMakePoint(0, self.imageCV.bounds.size.height - self.imageScrollView.contentSize.height)];
        [self.imageScrollView reflectScrolledClipView:self.imageScrollView.contentView];
    }

    NSLog(@"缩略图点击事件触发，页面索引: %ld", (long)pageIndex);
}


// 窗口调整大小时调整子视图布局
- (void)resizeSubviewsWithOldSize:(NSSize)oldSize {
    [super resizeSubviewsWithOldSize:oldSize];
    
    // 调整 ScrollView 的大小
    self.contentScrollView.frame = NSMakeRect(0, 0, self.offsetX, self.bounds.size.height);
    self.imageScrollView.frame = NSMakeRect(self.offsetX, 0, self.bounds.size.width - self.offsetX, self.bounds.size.height);
    
    // 更新 imageCV 的大小
    if (self.imageCV) {
        [self.imageCV setFrameSize:NSMakeSize(self.bounds.size.width - self.offsetX, self.bounds.size.height)];
    }
}

// 缩放方法
- (void)zoomChange:(float)zoomValue {
    if (self.imageCV) {
        [self.imageCV zoomChange:zoomValue];
        [self.imageCV setNeedsDisplay:YES];
    }
}

#pragma cut
// 启用裁剪模式
- (void)enableCropMode {
    if (!self.pdfCutView && self.imageCV) {
        // 初始化并添加 pdfCutView
        [self.imageCV enableCropMode:self];
        NSLog(@"已进入剪切模式。");
    } else {
        // 移除 pdfCutView
        [self.pdfCutView removeFromSuperview];
        self.pdfCutView = nil; // 释放 pdfCutView
        
        NSLog(@"已退出剪切模式。");
    }
}

// 实现 pdfCutViewDelegate 方法，接收裁剪区域
- (void)pdfCutView:(PdfCutView *)cutView didSelectFrame:(NSRect)frame imageWidth:(CGFloat)imageWidth imageHeight:(CGFloat)imageHeight {
    // 计算横轴和纵轴的比例
    CGFloat xRatio = frame.origin.x / imageWidth;
    CGFloat yRatio = frame.origin.y / imageHeight;
    CGFloat widthRatio = frame.size.width / imageWidth;
    CGFloat heightRatio = frame.size.height / imageHeight;
    
    // 获取 PDF 页数
    NSUInteger pageCount = self.pdfDoc.pageCount;
    
    // 弹出对话框，获取用户选择的页码范围
    NSAlert *pageSelectionAlert = [[NSAlert alloc] init];
    [pageSelectionAlert setMessageText:@"选择要剪切的页码范围"];
    [pageSelectionAlert addButtonWithTitle:@"确定"];
    [pageSelectionAlert addButtonWithTitle:@"取消"];
    
    NSTextField *startPageField = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 50, 24)];
    NSTextField *endPageField = [[NSTextField alloc] initWithFrame:NSMakeRect(60, 0, 50, 24)];
    startPageField.placeholderString = @"开始页";
    endPageField.placeholderString = @"结束页";
    startPageField.stringValue = @"1";
    endPageField.stringValue = @"1";
    
    [pageSelectionAlert setAccessoryView:[[NSView alloc] initWithFrame:NSMakeRect(0, 0, 120, 24)]];
    [[pageSelectionAlert accessoryView] addSubview:startPageField];
    [[pageSelectionAlert accessoryView] addSubview:endPageField];
    
    if ([pageSelectionAlert runModal] == NSAlertFirstButtonReturn) {
        NSInteger startPage = startPageField.integerValue - 1;
        NSInteger endPage = endPageField.integerValue - 1;
        
        // 确保页码范围至少为0
        startPage = MAX(0, startPage);
        endPage = MAX(0, endPage);
        
        if (startPage >= pageCount || endPage >= pageCount || startPage > endPage) {
            NSLog(@"页码范围无效！");
            return;
        }
        
        // 创建新的 PDF 文档以保存剪切内容
        PDFDocument *croppedPDFDoc = [[PDFDocument alloc] init];
        
        // 循环处理选定范围内的每一页
        for (NSInteger pageIndex = startPage; pageIndex <= endPage; pageIndex++) {
            PDFPage *page = [self.pdfDoc pageAtIndex:pageIndex];
            NSRect pageBounds = [page boundsForBox:kPDFDisplayBoxMediaBox];
            
            // 计算剪切区域在 PDF 页面中的实际位置
            NSRect cropRect = NSMakeRect(pageBounds.size.width * xRatio,
                                         pageBounds.size.height * yRatio,
                                         pageBounds.size.width * widthRatio,
                                         pageBounds.size.height * heightRatio);
            
            // 创建新的裁剪后的页面
            PDFPage *croppedPage = [self cropPDFPage:page toRect:cropRect];
            [croppedPDFDoc insertPage:croppedPage atIndex:croppedPDFDoc.pageCount];
        }
        
        // 保存裁剪后的 PDF 文件
        NSSavePanel *savePanel = [NSSavePanel savePanel];
        savePanel.allowedFileTypes = @[@"pdf"];
        [savePanel setMessage:@"选择文件保存位置"];
        
        if ([savePanel runModal] == NSModalResponseOK) {
            NSURL *saveURL = [savePanel URL];
            [croppedPDFDoc writeToURL:saveURL];
            NSLog(@"PDF 保存成功到: %@", saveURL.path);
        }
    }
}

// 辅助方法：裁剪 PDF 页面
- (PDFPage *)cropPDFPage:(PDFPage *)page toRect:(NSRect)rect {
    // 1. 获取 PDF 页面的边界尺寸
    NSRect pageBounds = [page boundsForBox:kPDFDisplayBoxMediaBox];
    
    // 2. 创建 NSImage 以匹配页面大小
    NSImage *pageImage = [[NSImage alloc] initWithSize:pageBounds.size];
    [pageImage lockFocus];
    
    // 3. 将 PDF 页面绘制到图形上下文中
    NSGraphicsContext *context = [NSGraphicsContext currentContext];
    CGContextRef cgContext = [context CGContext];
    [page drawWithBox:kPDFDisplayBoxMediaBox toContext:cgContext];
    
    [pageImage unlockFocus];
    
    // 4. 创建一个裁剪后的图像
    NSImage *croppedImage = [[NSImage alloc] initWithSize:rect.size];
    [croppedImage lockFocus];
    
    // 5. 从原始图像中裁剪特定的矩形区域
    [pageImage drawInRect:NSMakeRect(0, 0, rect.size.width, rect.size.height)
                 fromRect:rect
                operation:NSCompositingOperationCopy
                 fraction:1.0];
    [croppedImage unlockFocus];
    
    // 6. 使用裁剪后的图像创建新的 PDF 页面
    PDFPage *croppedPDFPage = [[PDFPage alloc] initWithImage:croppedImage];
    
    return croppedPDFPage;
}



@end
