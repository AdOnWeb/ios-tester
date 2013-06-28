//
//  WebViewController.m
//  Browser
//
//  Created by Dmitry Ponomarev on 6/27/13.
//  Copyright (c) 2013 adonweb. All rights reserved.
//

#import "WebViewController.h"
#import "AppDelegate.h"

static bool doLoad = true;

@interface WebViewController ()

- (void)loadPage:(NSString *)url;

@end

@implementation WebViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.webView.delegate = self;
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(nGoto:) name:@"goto" object:nil];
    
    NSString *curUrl = ((AppDelegate *)[[UIApplication sharedApplication] delegate]).curUrl;
    if (nil!=curUrl && curUrl.length>0) {
        doLoad = false;
        [self loadPage:curUrl];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    [_webView release];
    [super dealloc];
}

- (void)viewDidUnload {
    [self setWebView:nil];
    [super viewDidUnload];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Events

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

#pragma mark - Notofication

- (void)nGoto:(NSNotification *)notification
{
    doLoad = false;
    NSDictionary *info = notification.userInfo;
    [self loadPage:info[@"url"]];
}

#pragma mark - WebView Delegate

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    NSLog(@"webViewDidStartLoad: %@", webView.request.URL.absoluteString);
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    NSLog(@"webViewDidFinishLoad: %@", webView.request.URL.absoluteString);
    if (doLoad) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"goto2" object:self userInfo:@{@"url": webView.request.URL.absoluteString}];
    }
    doLoad = true;
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    NSLog(@"webView: %@ didFailLoadWithError: %@", webView, error);
}

#pragma mark – Actions

- (void)loadPage:(NSString *)url
{
    NSString* sUrl = url;
    if (![sUrl hasPrefix:@"http://"] && ![sUrl hasPrefix:@"https://"] && ![sUrl hasPrefix:@"ftp://"])
    {
        sUrl = [NSString stringWithFormat:@"http://%@", sUrl];
    }
    NSURL* nsUrl = [NSURL URLWithString:sUrl];
    NSURLRequest* request = [NSURLRequest requestWithURL:nsUrl cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:30];

    [self.webView loadRequest:request];
}

@end
