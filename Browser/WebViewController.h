//
//  WebViewController.h
//  Browser
//
//  Created by Dmitry Ponomarev on 6/27/13.
//  Copyright (c) 2013 adonweb. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WebViewController : UIViewController <UIWebViewDelegate>

@property (retain, nonatomic) IBOutlet UIWebView *webView;

- (void)nGoto:(NSNotification *)notification;

@end
