//
//  FirstViewController.m
//  Browser
//
//  Created by Dmitry Ponomarev on 6/27/13.
//  Copyright (c) 2013 adonweb. All rights reserved.
//

#import "FirstViewController.h"
#import "AppDelegate.h"

@interface FirstViewController ()

- (void)onGoto:(NSNotification *)notification;

@end

@implementation FirstViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.url.delegate = self;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onGoto:) name:@"goto" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onGoto:) name:@"goto2" object:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)dealloc {
    [_url release];
    [_output release];
    [super dealloc];
}

- (void)viewDidUnload {
    [self setUrl:nil];
    [self setOutput:nil];
    [super viewDidUnload];
}

#pragma mark - Events

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (IBAction)onGo:(id)sender {
    [self.url resignFirstResponder];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"goto" object:self userInfo:@{@"url": self.url.text}];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string   // return NO to not change text
{
    if ([string isEqualToString:@"\n"]) {
        [self onGo:nil];
        return NO;
    }
    return YES;
}

#pragma mrak - Actions

- (void)onGoto:(NSNotification *)notification
{
    NSDictionary *info = notification.userInfo;
    AppDelegate *delegate = ((AppDelegate *)[[UIApplication sharedApplication] delegate]);

    // Prepare URL
    NSString* sUrl = info[@"url"];
    if (![sUrl hasPrefix:@"http://"] && ![sUrl hasPrefix:@"https://"] && ![sUrl hasPrefix:@"ftp://"])
    {
        sUrl = [NSString stringWithFormat:@"http://%@", sUrl];
    }
    
    // Check current url
    if (delegate.curUrl && [sUrl compare:delegate.curUrl] == NSOrderedSame)
    {
        return;
    }
    
    NSLog(@"onGoto: %@", sUrl);
    
    // Set body output
    self.output.text = [NSString stringWithFormat:@"Loading: %@ ...", sUrl];
    
    // Init request
    NSURL* nsUrl = [NSURL URLWithString:sUrl];
    NSURLRequest* request = [NSURLRequest requestWithURL:nsUrl cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:30];
    
    // Lock
    static NSObject *lock = nil;
    if (nil==lock) {
        lock = [[NSObject alloc] init];
    }
    
    // Send async request
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *resp, NSData *data, NSError *e)
    {
        NSDictionary *_headers = [(NSHTTPURLResponse*)resp allHeaderFields];

        NSMutableString *headers = [NSMutableString stringWithFormat:@"URL: %@\nStatus: %d\n", sUrl, [(NSHTTPURLResponse*)resp statusCode]];
        NSArray *keys = _headers.allKeys;
        NSArray *vals = _headers.allValues;
        for (int i=0;i<keys.count;i++) {
            [headers appendFormat:@"%@: %@\n", keys[i], vals[i]];
        }
        
        @synchronized(lock) {
            NSString *_c = [NSString stringWithUTF8String:data.bytes];
            if (!_c) {
                _c = [[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding:NSASCIIStringEncoding];
            }
            NSString *content = [NSString stringWithFormat:@"%@\n\n%@", headers, e ? e : _c];

            // Change text
            _output.text = content;
        }
    }];
    
    // Set prepared url
    self.url.text = sUrl;
    delegate.curUrl = sUrl;
}

@end
