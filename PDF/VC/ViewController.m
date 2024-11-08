//
//  ViewController.m
//  PDF
//
//  Created by 赢赢淡淡小奈尔 on 2024/10/24.
//

#import "ViewController.h"

@interface ViewController ()

// 定义放大倍率数组
@property (nonatomic, strong) NSArray *zoomLevels;
// 当前倍率 格式：100
@property (assign) CGFloat currentZoomValue;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // 初始化放大倍率数组
    self.zoomLevels = @[@10, @13, @25, @38, @50, @63, @75, @88, @100, @112, @125, @137, @150, @162, @175, @187, @200];
    
    // 初始化当前的放大倍率索引，默认为第一个倍率
    self.currentZoomValue = 100;
    
    // 设置滑块的初始值、范围和最小增量
    self.zoomSlider.doubleValue = 50;  // 初始值
    self.zoomSlider.minValue = 10;       // 最小值
    self.zoomSlider.maxValue = 100;     // 最大值
    self.zoomSlider.altIncrementValue = 2; // 每次变化最少为2
    [self.zoomSlider setContinuous:YES];

    
}

#pragma View
- (void)viewWillLayout {
    [super viewWillLayout];
    
    // 调整 pdfView 的框架以适应新的视图大小
    [self setupPdfView];
}

#pragma File
- (IBAction)chooseFile:(id)sender {
    // 创建 NSOpenPanel 实例
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    
    // 配置 openPanel 属性
    openPanel.canChooseFiles = YES;          // 允许选择文件
    openPanel.canChooseDirectories = NO;     // 不允许选择文件夹
    openPanel.allowsMultipleSelection = NO;  // 不允许多选
    
    // 显示对话框并处理用户选择
    [openPanel beginWithCompletionHandler:^(NSModalResponse result) {
        if (result == NSModalResponseOK) {
            // 获取用户选择的文件 URL
            NSURL *selectedFileURL = openPanel.URL;
            
            if (selectedFileURL) {
                // 检查文件是否是 PDF
                if ([[selectedFileURL.pathExtension lowercaseString] isEqualToString:@"pdf"]) {
                    [self handleSelectedPDFFile:selectedFileURL];
                    
                } else {
                    NSLog(@"选中的文件不是 PDF 文件。");
                }
            }
        }
    }];
}

// 处理 PDF 文件的自定义方法
- (void)handleSelectedPDFFile:(NSURL *)fileURL {
    self.pdfView = nil;
    
    // 读取和处理 PDF 文件
    CGFloat VCWidth = self.view.frame.size.width;
    CGFloat VCHeight = self.view.frame.size.height;
    
    self.pdfView = [[PdfView alloc] initWithFileURL:fileURL width:VCWidth height:VCHeight];
    [self.view addSubview:self.pdfView];

    NSLog(@"width:%f, height:%f", self.pdfView.frame.size.width, self.pdfView.frame.size.height);
    [self setupPdfView];
}

// pdf设置
- (void)setupPdfView {
    CGFloat vcWidth = self.view.frame.size.width; // 获取父视图的宽度
    CGFloat vcHeight = self.view.frame.size.height; // 获取父视图的高度

    // 设置 pdfView 的框架
    self.pdfView.frame = NSMakeRect(0, 40, vcWidth, vcHeight - 170);
    
    
    // 将 pdfView 添加到父视图
    [self.view addSubview:self.pdfView];
}

#pragma Zoom
- (IBAction)zoomUp:(id)sender {
    if ([self enableZoom]) {
        self.currentZoomValue = [self findNearestZoomValueHigherThan:self.currentZoomValue];
        [self updateZoomLabel];
    }
}


- (IBAction)zoomDown:(id)sender {
    if ([self enableZoom]) {
        self.currentZoomValue = [self findNearestZoomValueLowerThan:self.currentZoomValue];
        [self updateZoomLabel];
    }
}

- (IBAction)zoomSlider:(id)sender {
    if ([self enableZoom]) {
        NSSlider *slider = (NSSlider *)sender;
        double newValue = slider.doubleValue;
        // 检查滑块值变化是否满足最小增量的条件
        if (fabs(newValue - self.currentZoomValue) < 2) {
            // 如果变化小于 2，保持上一个值
            slider.doubleValue = self.currentZoomValue;
        } else {
            // 更新当前缩放值
            self.currentZoomValue = newValue;
        }
        NSLog(@"float:%f, zoom:%f", self.zoomSlider.doubleValue, self.currentZoomValue);
        
        // 在这里进行实时操作，比如更新显示倍率
        [self updateZoomWithValue:self.currentZoomValue * 2];
    }
}

// 更新显示倍率或其他操作
- (void)updateZoomWithValue:(float)zoomValue {
    self.zoomLabel.stringValue = [NSString stringWithFormat:@"%.0f%%", zoomValue];
    
    [self.pdfView zoomChange:zoomValue];
}

// 查找大于当前倍率的最近值
- (CGFloat)findNearestZoomValueHigherThan:(CGFloat)value {
    for (NSNumber *zoom in self.zoomLevels) {
        if ([zoom floatValue] > value) {
            return [zoom floatValue];
        }
    }
    // 如果没有更大的值，返回最后一个
    return [[self.zoomLevels lastObject] floatValue];
}

// 查找小于当前倍率的最近值
- (CGFloat)findNearestZoomValueLowerThan:(CGFloat)value {
    for (NSNumber *zoom in [self.zoomLevels reverseObjectEnumerator]) {
        if ([zoom floatValue] < value) {
            return [zoom floatValue];
        }
    }
    // 如果没有更小的值，返回第一个
    return [[self.zoomLevels firstObject] floatValue];
}

// 更新放大倍率的显示
- (void)updateZoomLabel {
    // 更新界面显示
    self.zoomLabel.stringValue = [NSString stringWithFormat:@"%.0f%%", self.currentZoomValue];
    
    self.zoomSlider.floatValue = self.currentZoomValue / 2;
    
    [self.pdfView zoomChange:self.currentZoomValue];
}

// 放大功能使用权
- (Boolean)enableZoom {
    if (self.pdfView.imageCV.pdfCutView) {
        return NO;
    } else {
        return YES;
    }
}

#pragma cutImage

- (IBAction)cutButton:(id)sender {
    if (self.pdfView) {
        [self.pdfView enableCropMode];
    }
}

@end
