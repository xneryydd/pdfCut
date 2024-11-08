//
//  ImageContainerView.h
//  PDF
//
//  Created by 赢赢淡淡小奈尔 on 2024/10/28.
//

#import <Cocoa/Cocoa.h>
#import <PDFKit/PDFKit.h>
#import "PdfCutView.h"

@interface ImageContainerView : NSView

@property (nonatomic, strong) NSImageView *imageView;
@property (nonatomic, assign) CGFloat zoomFactor;

@property (nonatomic) NSSize initialImageSize; // 初始图像大小存储
@property (nonatomic) NSSize superScrollViewSize;

@property (nonatomic, assign) BOOL isCropModeEnabled;
@property (nonatomic, weak) PdfCutView *pdfCutView;

- (instancetype)initWithImage:(NSImage *)image;
- (void)setImage:(NSImage *)image;
- (void)zoomChange:(float)zoomValue;
- (void)enableCropMode:(id<PdfCutViewDelegate>)delegate;

@end
