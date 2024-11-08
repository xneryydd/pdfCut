//
//  PdfVC.h
//  PDF
//
//  Created by 赢赢淡淡小奈尔 on 2024/10/24.
//

#import <Cocoa/Cocoa.h>
#import <PDFKit/PDFKit.h>
#import <QuartzCore/QuartzCore.h>
#import "ImageContainerView.h"
#import "PdfCutView.h"


NS_ASSUME_NONNULL_BEGIN

@interface PdfView : NSView

@property (nonatomic, strong) PDFDocument *pdfDoc;
@property (strong) NSURL *pdfURL;
@property (strong) ImageContainerView *imageCV;
@property (nonatomic ,weak) PdfCutView *pdfCutView;

- (instancetype)initWithFileURL:(NSURL *)pdfURL width:(CGFloat)width height:(CGFloat)height;

- (void)zoomChange:(float)zoomValue;

- (void)enableCropMode;

@end

NS_ASSUME_NONNULL_END
