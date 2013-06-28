//
//  FirstViewController.h
//  Browser
//
//  Created by Dmitry Ponomarev on 6/27/13.
//  Copyright (c) 2013 adonweb. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FirstViewController : UIViewController <UITextFieldDelegate>

@property (retain, nonatomic) IBOutlet UITextField *url;
@property (retain, nonatomic) IBOutlet UITextView *output;

- (IBAction)onGo:(id)sender;

@end
