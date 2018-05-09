//
//  RCMCBPrinterA4Data.h
//  RedCircleManager
//
//  Created by Star童话 on 2018/5/3.
//  Copyright © 2018年 Hecom. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RCMCBPrinterA4Data : NSObject
{
    CGPDFDocumentRef _pdf;
}

CGImageRef PDFPageToCGImage(size_t pageNumber, CGPDFDocumentRef document);

#pragma mark - publicMethod

- (void)showPrintWithWebView:(UIWebView *)webView;

@end

/**
 * 1、网页转PDF
 * 2、PDF转图片
 */
