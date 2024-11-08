//
//  ViewController.h
//  PDF
//
//  Created by 赢赢淡淡小奈尔 on 2024/10/24.
//

#import <Cocoa/Cocoa.h>
#import "PdfView.h"

@interface ViewController : NSViewController
@property (strong) IBOutlet PdfView *pdfView;

@property (weak) IBOutlet NSSlider *zoomSlider;

@property (weak) IBOutlet NSTextField *zoomLabel;


@end

