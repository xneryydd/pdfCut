//
//  PdfCutView.h
//  PDF
//
//  Created by 赢赢淡淡小奈尔 on 2024/10/25.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@class PdfCutView;
// 声明 pdfCutViewDelegate 协议
@protocol PdfCutViewDelegate <NSObject>

- (void)pdfCutView:(PdfCutView *)pdfCutView didSelectFrame:(NSRect)frame imageWidth:(CGFloat)imageWidth imageHeight:(CGFloat)imageHeight;

@end

@interface PdfCutView : NSView

@property (nonatomic, strong) NSImage *image;

- (instancetype)initWithFrame:(NSRect)frame delegate:(id<PdfCutViewDelegate>)delegate;
- (void)cropImage;

@end

NS_ASSUME_NONNULL_END
