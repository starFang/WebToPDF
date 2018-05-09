//
//  RCMCBPrinterA4Data.m
//  RedCircleManager
//
//  Created by Star童话 on 2018/5/3.
//  Copyright © 2018年 Hecom. All rights reserved.
//

#import "RCMCBPrinterA4Data.h"

@interface RCMCBPrinterA4Data () <UIPrintInteractionControllerDelegate>
{
    NSUInteger _pageCount;
}
@end

@implementation RCMCBPrinterA4Data

- (void)dealloc {
    
}

CGContextRef CreateARGBBitmapContext (size_t pixelsWide, size_t pixelsHigh) {
    CGContextRef    context = NULL;
    CGColorSpaceRef colorSpace;
    void *bitmapData;
    unsigned long bitmapByteCount;
    unsigned long bitmapBytesPerRow;
    
    // Get image width, height. We’ll use the entire image.
    //  size_t pixelsWide = CGImageGetWidth(inImage);
    //  size_t pixelsHigh = CGImageGetHeight(inImage);
    
    // Declare the number of bytes per row. Each pixel in the bitmap in this
    // example is represented by 4 bytes; 8 bits each of red, green, blue, and
    // alpha.
    bitmapBytesPerRow = (pixelsWide * 4);
    bitmapByteCount = (bitmapBytesPerRow * pixelsHigh);
    
    // Use the generic RGB color space.
    //colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
    colorSpace = CGColorSpaceCreateDeviceRGB();
    if (colorSpace == NULL) {
        fprintf(stderr, "Error allocating color space\n");
        return NULL;
    }
    
    // Allocate memory for image data. This is the destination in memory
    // where any drawing to the bitmap context will be rendered.
    if (sizeof(bitmapData)) {
        //NSLog(@"size %d",bitmapData);
        //free(bitmapData);
    }
    bitmapData = malloc( bitmapByteCount );
    if (bitmapData == NULL) {
        fprintf (stderr, "Memory not allocated!");
        CGColorSpaceRelease( colorSpace );
        return NULL;
    }
    
    // Create the bitmap context. We want pre-multiplied ARGB, 8-bits
    // per component. Regardless of what the source image format is
    // (CMYK, Grayscale, and so on) it will be converted over to the format
    // specified here by CGBitmapContextCreate.
    context = CGBitmapContextCreate (bitmapData,
                                     pixelsWide,
                                     pixelsHigh,
                                     8,      // bits per component
                                     bitmapBytesPerRow,
                                     colorSpace,
                                     kCGImageAlphaPremultipliedFirst);
    if (context == NULL) {
        free (bitmapData);
        fprintf (stderr, "Context not created!");
    }
    
    // Make sure and release colorspace before returning
    CGColorSpaceRelease( colorSpace );
    return context;
}

CGImageRef PDFPageToCGImage(size_t pageNumber, CGPDFDocumentRef document) {
    CGPDFPageRef    page;
    CGRect        pageSize;
    CGContextRef    outContext;
    CGImageRef    ThePDFImage;
    //CGAffineTransform ctm;
    page = CGPDFDocumentGetPage (document, pageNumber);
    if(page) {
        pageSize = CGPDFPageGetBoxRect(page, kCGPDFMediaBox);
        outContext= CreateARGBBitmapContext (pageSize.size.width, pageSize.size.height);
        if(outContext) {
            CGContextDrawPDFPage(outContext, page);
            ThePDFImage= CGBitmapContextCreateImage(outContext);
            int *buffer;
            buffer = CGBitmapContextGetData(outContext);
            free(buffer);
            CGContextRelease(outContext);
            CGPDFPageRelease(page);
            return ThePDFImage;
        }
    }
    return NULL;
}

- (UIImage *)createImageWithPageNo:(NSInteger)pageNo {
    if (_pageCount) {
        return [UIImage imageWithCGImage:PDFPageToCGImage(pageNo, _pdf)];
    }
    return nil;
}

- (void)createPDFFromExistFile:(NSString *)aFilePath {
    CFStringRef path = CFStringCreateWithCString(NULL, [aFilePath UTF8String], kCFStringEncodingUTF8);
    CFURLRef url = CFURLCreateWithFileSystemPath(NULL, path, kCFURLPOSIXPathStyle, NO);
    CFRelease(path);
    _pdf = CGPDFDocumentCreateWithURL(url);
    CFRelease(url);
    unsigned long count = CGPDFDocumentGetNumberOfPages(_pdf);
    _pageCount = count;
}

#pragma mark - publicMethod
- (void)showPrintWithWebView:(UIWebView *)webView {
    UIPrintPageRenderer *pageRender = [[UIPrintPageRenderer alloc] init];
    CGRect page;
    page.origin.x = 0;
    page.origin.y = 0;
    page.size.width = 595;
    page.size.height = 842;
    
    [pageRender setValue:[NSValue valueWithCGRect:page] forKey:@"paperRect"];
    [pageRender setValue:[NSValue valueWithCGRect:CGRectMake(10, 10, 575, 750)] forKey:@"printableRect"];
    
    UIPrintFormatter *printFor = [webView viewPrintFormatter];
    [pageRender addPrintFormatter:printFor startingAtPageAtIndex:0];
    
    NSData *pdfData = [self printToPDF:pageRender];
    
//    NSString *documentPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
//    NSString *pdfPath = [documentPath stringByAppendingPathComponent:@"print.pdf"];
//    BOOL result = [pdfData writeToFile:pdfPath atomically:YES];
    
//    if (result) {
//        [self createPDFFromExistFile:pdfPath];
//        for (NSInteger i = 1; i <= _pageCount; i++) {
//            [self loadImageFinished:[self createImageWithPageNo:i]];
//        }
    UIPrintInteractionController *printC = [UIPrintInteractionController sharedPrintController];
    printC.delegate = self;
    if (printC && [UIPrintInteractionController canPrintData:pdfData]) {
        UIPrintInfo *printInfo = [UIPrintInfo printInfo];//准备打印信息以预设值初始化的对象。
        printInfo.outputType = UIPrintInfoOutputGeneral;//设置输出类型。
        printC.showsPageRange = YES;//显示的页面范围
        printC.printingItem = pdfData;//single NSData, NSURL, UIImage, ALAsset
        [printC presentAnimated:YES completionHandler:^(UIPrintInteractionController * _Nonnull printInteractionController, BOOL completed, NSError * _Nullable error) {
            if (!completed && error) {
                NSLog(@"可能无法完成，因为印刷错误: %@", error);
            }
        }];//在iPhone上弹出打印那个页面
    }
//    }
}

#pragma mark - prvateMethod
- (NSData *)printToPDF:(UIPrintPageRenderer *)pageRenderer {
    NSMutableData *pdfData = [NSMutableData data];
    UIGraphicsBeginPDFContextToData( pdfData, CGRectZero, nil );
    for (NSInteger i = 0; i < [pageRenderer numberOfPages]; i++) {
        UIGraphicsBeginPDFPage();
        CGRect bounds = UIGraphicsGetPDFContextBounds();
        [pageRenderer drawPageAtIndex:i inRect:bounds];
    }
    UIGraphicsEndPDFContext();
    return pdfData;
}

- (void)loadImageFinished:(UIImage *)image {
    UIImageWriteToSavedPhotosAlbum(image, self, @selector(image:didFinishSavingWithError:contextInfo:), (__bridge void *)self);
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    NSLog(@"image = %@, error = %@, contextInfo = %@", image, error, contextInfo);
}

@end
