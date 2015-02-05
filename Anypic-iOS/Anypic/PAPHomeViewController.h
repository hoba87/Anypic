//
//  PAPHomeViewController.h
//  Anypic
//
//  Created by Héctor Ramos on 5/3/12.
//  Copyright (c) 2013 Parse. All rights reserved.
//

#import "PAPPhotoTimelineViewController.h"
#import "VPImageCropperViewController.h"
#import "DParseLoginViewController.h"
#import "DParseSignUpViewController.h"
#import "BBBadgeBarButtonItem.h"

@interface PAPHomeViewController : PAPPhotoTimelineViewController <PFLogInViewControllerDelegate, PFSignUpViewControllerDelegate, VPImageCropperDelegate>
{
}
+ (instancetype)sharedInstance;

@property (nonatomic, assign, getter = isFirstLaunch) BOOL firstLaunch;
@property (strong, nonatomic) DParseLoginViewController *logInViewController;
@property (strong, nonatomic) DParseSignUpViewController *signUpViewController;
@property (strong, nonatomic) BBBadgeBarButtonItem *activityButton;
@end
