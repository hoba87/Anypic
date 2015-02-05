//
//  PAPHomeViewController.m
//  Anypic
//
//  Created by Héctor Ramos on 5/2/12.
//  Copyright (c) 2013 Parse. All rights reserved.
//

#import "PAPHomeViewController.h"
//#import "PAPSettingsActionSheetDelegate.h"
//#import "PAPSettingsButtonItem.h"
#import "PAPFindFriendsViewController.h"
#import "MBProgressHUD.h"
#import "PAPFindFriendsViewController.h"
#import "MBProgressHUD.h"
#import "DImageCropViewController.h"
#import "DSettingsViewController.h"
#import "DCaptureViewController.h"
#import "PAPAccountViewController.h"
#import <ParseFacebookUtils/PFFacebookUtils.h>
#import "PAPActivityFeedViewController.h"

@interface PAPHomeViewController ()
//@property (nonatomic, strong) PAPSettingsActionSheetDelegate *settingsActionSheetDelegate;
@property (nonatomic, strong) UIView *blankTimelineView;
@end

@implementation PAPHomeViewController
@synthesize firstLaunch;
//@synthesize settingsActionSheetDelegate;
@synthesize blankTimelineView;
@synthesize activityButton;

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = @"Dimensiva";

//    self.navigationItem.rightBarButtonItem = [[PAPSettingsButtonItem alloc] initWithTarget:self action:@selector(settingsButtonAction:)];
    
    
    UIBarButtonItem *profileButton = [[UIBarButtonItem alloc]
                                      initWithImage:[UIImage imageNamed:@"man"]
                                      style:UIBarButtonItemStyleDone
                                      target:self action:@selector(myProfile)];
    [profileButton setBackgroundImage:[UIImage new] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    
    //        Find Friends
    UIBarButtonItem *friendsButton = [[UIBarButtonItem alloc]
                                      initWithImage:[UIImage imageNamed:@"addfriends"]
                                      style:UIBarButtonItemStyleDone
                                      target:self action:@selector(friends)];
    [friendsButton setBackgroundImage:[UIImage new] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    //
    //        self.toolBarItemsLeft = @[profileButton];
    self.toolBarItemsLeft = @[profileButton,friendsButton];
    
    //        Activity
    UIButton *customButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
    // Add your action to your button
    [customButton addTarget:self action:@selector(activity) forControlEvents:UIControlEventTouchUpInside];
    // Customize your button as you want, with an image if you have a pictogram to display for example
    [customButton setImage:[UIImage imageNamed:@"activity"] forState:UIControlStateNormal];
    
    // Then create and add our custom BBBadgeBarButtonItem
    activityButton = [[BBBadgeBarButtonItem alloc] initWithCustomUIButton:customButton];
    activityButton.badgeOriginX = 25;
    activityButton.badgeOriginY = -6;
    
    UIBarButtonItem *shuffleButton = [[UIBarButtonItem alloc]
                                      initWithImage:[UIImage imageNamed:@"newestpics"]
                                      style:UIBarButtonItemStyleDone
                                      target:self action:@selector(shuffle)];
    self.toolBarItemsRight = @[shuffleButton, activityButton];
    
    //        self.navigationItem.rightBarButtonItem = shuffleButton;
    
    self.blankTimelineView = [[UIView alloc] initWithFrame:self.view.bounds];
    self.blankTimelineView.alpha = 0.0f;
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = self.view.bounds;
    [button setBackgroundImage:[UIImage imageNamed:@"HomeTimelineBlank.png"] forState:UIControlStateNormal];
    [button addTarget:self action:@selector(inviteFriendsButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.blankTimelineView addSubview:button];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(timeline) name:@"kBlankTimeLineView" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pushreceived) name:@"kPushNotification" object:nil];

    
}

static PAPHomeViewController *__sharedInstance = nil;

+ (instancetype)sharedInstance {
    if (__sharedInstance == nil) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            __sharedInstance = [[[self class] alloc] init];
        });
    }
    
    return __sharedInstance;
}
-(void)myProfile {
    PAPAccountViewController *accountViewController = [[PAPAccountViewController alloc] init];//WithStyle:UITableViewStylePlain];
    [accountViewController setUser:[PFUser currentUser]];
    [self.navigationController pushViewController:accountViewController animated:YES];
}
-(void)activity{
    //    // Clears out all notifications from Notification Center.
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
    [UIApplication sharedApplication].applicationIconBadgeNumber = 1;
    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
    [[PFInstallation currentInstallation] saveInBackground];
    activityButton.badgeValue = @"0";
    PAPActivityFeedViewController *activityViewController = [[PAPActivityFeedViewController alloc] initWithStyle:UITableViewStylePlain];//WithStyle:UITableViewStylePlain];
    [self.navigationController pushViewController:activityViewController animated:YES];
}
-(void)friends{
    PAPFindFriendsViewController *findFriendsVC = [[PAPFindFriendsViewController alloc] init];
    [self.navigationController pushViewController:findFriendsVC animated:YES];
}

-(void)shuffle{
    [self reloadMPODataSourceDataAndViewWithOptions:[NSDictionary dictionaryWithObjectsAndKeys:@"newest",@"caller",nil]];
}
-(void)pushreceived{
    activityButton.badgeValue = [NSString stringWithFormat:@"%d", [activityButton.badgeValue intValue] + 1];
}
#pragma mark - ()
-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    activityButton.badgeValue = [NSString stringWithFormat:@"%li",(long)[UIApplication sharedApplication].applicationIconBadgeNumber];
}

    -(void)viewWillAppear:(BOOL)animated{
        [super viewWillAppear:animated];
        if ([mpoDataSource loggedIn] == NO) {
            [mpoDataSource loginWithOptions:nil success:^{
                [self reloadMPODataSourceDataAndViewWithOptions:nil];
            } failure:^{
                self.signUpViewController = [[DParseSignUpViewController alloc] init];
                self.signUpViewController.delegate = self;
                
                self.logInViewController = [[DParseLoginViewController alloc] init];
                self.logInViewController.delegate = self;
                
                [self.logInViewController setFields:PFLogInFieldsUsernameAndPassword
                 | PFLogInFieldsLogInButton
                 | PFLogInFieldsSignUpButton
                 | PFLogInFieldsPasswordForgotten
                 | PFLogInFieldsDismissButton
                 | PFLogInFieldsTwitter
                 | PFLogInFieldsFacebook];
                
                [self.logInViewController setSignUpController:self.signUpViewController];
                
                [self presentViewController:self.logInViewController animated:YES completion:NULL];
            }];
        }
        else
        {
#if DEBUG
            [self reloadMPODataSourceDataAndViewWithOptions:nil];
#else
            if (mpoDataSource.isRefreshRecommended) {
                [self reloadMPODataSourceDataAndViewWithOptions:nil];
            }
            else {
                [galleryCollectionView reloadData];
            }
            
#endif
            
            //    } else if ([[PFUser currentUser] objectForKey:kPAPUserProfilePicSmallKey] == nil){
            //
            //#warning todo
            //        DImageCropViewController *imgCropperVC = [[DImageCropViewController alloc] init];
            //        [self presentViewController:imgCropperVC animated:YES completion:^{
            //        }];
            //    }
        }
    }
-(void)timeline{
        if (mpoDataSource.count == 0) {
            [self.view addSubview:self.blankTimelineView];
            self.blankTimelineView.alpha = 0.0f;
            [UIView animateWithDuration:0.200f animations:^{
                self.blankTimelineView.alpha = 1.0f;
            }];
        } else {
            [self.blankTimelineView removeFromSuperview];
        }
    }
- (void)pushCaptureViewController
    {
        [self.navigationController pushViewController:[DCaptureViewController sharedInstance] animated:YES];
    }

- (void)pushSettingsViewController
    {
        [self.navigationController pushViewController:[DSettingsViewController sharedInstance] animated:YES];
    }
    
#pragma mark - PFQueryTableViewController
    
    //- (void)objectsDidLoad:(NSError *)error {
    //    [super objectsDidLoad:error];
    //
    //    if (self.objects.count == 0 && ![[self queryForTable] hasCachedResult]) {
    //        self.tableView.scrollEnabled = NO;
    //
    //        if (!self.blankTimelineView.superview) {
    //            self.blankTimelineView.alpha = 0.0f;
    //            self.tableView.tableHeaderView = self.blankTimelineView;
    //
    //            [UIView animateWithDuration:0.200f animations:^{
    //                self.blankTimelineView.alpha = 1.0f;
    //            }];
    //        }
    //    } else {
    //        self.tableView.tableHeaderView = nil;
    //        self.tableView.scrollEnabled = YES;
    //    }
    //}
    
    
#pragma mark - ()
    
    //- (void)settingsButtonAction:(id)sender {
    //    self.settingsActionSheetDelegate = [[PAPSettingsActionSheetDelegate alloc] initWithNavigationController:self.navigationController];
    //    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self.settingsActionSheetDelegate cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"My Profile",@"Activity Feed", @"Find Friends",@"Log Out", nil];
    //
    //    [actionSheet showFromToolbar:self.navigationController.toolbar];
    //}
    
    
    - (void)inviteFriendsButtonAction:(id)sender {
        PAPFindFriendsViewController *detailViewController = [[PAPFindFriendsViewController alloc] init];
        [self.navigationController pushViewController:detailViewController animated:YES];
    }
#pragma mark - PFLogInViewControllerDelegate
    - (BOOL)logInViewController:(PFLogInViewController *)logInController shouldBeginLogInWithUsername:(NSString *)username password:(NSString *)password {
        
        //check old dimensiva user
        if (username && password && username.length != 0 && password.length != 0) {
            return YES; // Begin login process
        }
        [[[UIAlertView alloc] initWithTitle:@"Missing Information"
                                    message:@"Make sure you fill out all of the information!"
                                   delegate:nil
                          cancelButtonTitle:@"ok"
                          otherButtonTitles:nil] show];
        return NO; // Interrupt login process
    }
    
    // Sent to the delegate when a PFUser is logged in.
    - (void)logInViewController:(PFLogInViewController *)logInController didLogInUser:(PFUser *)user {
        //    [user fetchIfNeeded];// InBackgroundWithBlock:^(PFObject *object, NSError *error) {
        if ([PFTwitterUtils isLinkedWithUser:user]) {
            
            NSString *name = [PFTwitterUtils twitter].screenName;
            PFQuery *query = [PFQuery queryWithClassName:@"_User"];
            
            [query whereKey:@"username" equalTo:name];
            
            
            //Username setzen
            [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                if (!error && objects > 0) {
                    UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Alert" message:@"The username does exist. Please enter another username!" delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil];
                    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
                    [alert show];
                } else {
                    user[kPAPUserDisplayNameKey] = name;
                    [user saveInBackground];
                }
            }];
            
            //Profilfoto setzen
            
            NSString * requestString = [NSString stringWithFormat:@"https://api.twitter.com/1.1/users/show.json?screen_name=%@", name];
            
            NSURL *verify = [NSURL URLWithString:requestString];
            NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:verify];
            [[PFTwitterUtils twitter] signRequest:request];
            NSURLResponse *response = nil;
            NSError *error = nil;
            NSData *data = [NSURLConnection sendSynchronousRequest:request
                                                 returningResponse:&response
                                                             error:&error];
            
            
            if ( error == nil){
                NSDictionary* result = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
                NSLog(@"%@",result);
                PFFile *image = [PFFile fileWithData:
                                 [NSData dataWithContentsOfURL:
                                  [NSURL URLWithString:
                                   [[result objectForKey:@"profile_image_url_https"] stringByReplacingOccurrencesOfString:@"_normal" withString:@""]]]];
                [user setObject:image forKey:kPAPUserProfilePicSmallKey];
                [user saveInBackground];
            }
            
        } else if ([PFFacebookUtils isLinkedWithUser:user]) {
            [FBRequestConnection
             startForMeWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                 if (!error) {
                     NSString *name = [result objectForKey:@"name"];
                     NSString *facebookId = [result objectForKey:@"id"];
                     
                     PFQuery *query = [PFQuery queryWithClassName:@"_User"];
                     
                     [query whereKey:@"username" equalTo:name];
                     
                     [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                         if (!error && objects > 0) {
                             UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Alert" message:@"The username does exist. Please enter another username!" delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil];
                             alert.alertViewStyle = UIAlertViewStylePlainTextInput;
                             [alert show];
                         } else {
                             user[kPAPUserDisplayNameKey] = name;
                             [user saveInBackground];
                         }
                     }];
                     
                     //Profilfoto
                     PFFile *image = [PFFile fileWithData:
                                      [NSData dataWithContentsOfURL:
                                       [NSURL URLWithString:[@"https://graph.facebook.com/<facebookId>/picture?type=large"  stringByReplacingOccurrencesOfString:@"<facebookId>" withString:facebookId]]]];
                     [user setObject:image forKey:kPAPUserProfilePicSmallKey];
                     [user saveInBackground];
                 }
             }];
        }
        
        
        //    PFFile *image = [user objectForKey:kPAPUserProfilePicSmallKey];
        //    if (image == nil) {
        //
        //        [self.logInViewController dismissViewControllerAnimated:YES completion:^{
        //            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Profile picture" message:@"Please upload a profile picture! To do so, tap on the Dimensiva logo." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        //            [alertView show];
        //            PAPAccountViewController *accountViewController = [[PAPAccountViewController alloc] init];//WithStyle:UITableViewStylePlain];
        //            [accountViewController setUser:[PFUser currentUser]];
        //            [self.navigationController pushViewController:accountViewController animated:YES];
        //        }];
        //    } else {
        [self.logInViewController dismissViewControllerAnimated:YES completion:nil];
        //    }
        //    }];
        //        VPImageCropperViewController *imgCropperVC = [[VPImageCropperViewController alloc] initWithImage:[UIImage imageNamed:@"button001Dimensiva"] cropFrame:CGRectMake(0, 100.0f, self.view.frame.size.width, self.view.frame.size.width) limitScaleRatio:3.0];
        //        imgCropperVC.delegate = self;
        //        [self presentViewController:imgCropperVC animated:YES completion:^{
        //            // TO DO
        //        }];
        //    }
    }
    - (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
        NSString *name = [[alertView textFieldAtIndex:0] text];
        PFQuery *query = [PFQuery queryWithClassName:@"_User"];
        [query whereKey:@"username" equalTo:name];
        //Username setzen
        [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            if (!error && objects > 0) {
                if (![PFTwitterUtils isLinkedWithUser:[objects objectAtIndex:0]] || ![PFFacebookUtils isLinkedWithUser:[objects objectAtIndex:0]]) {
                    UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Alert" message:@"The username does exist. Please enter another username!" delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil];
                    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
                    [alert show];
                }
            } else {
                PFUser *user = [PFUser currentUser];
                user[kPAPUserDisplayNameKey] = name;
                [user saveInBackground];
            }
        }];
    }
    
    // Sent to the delegate when the log in attempt fails.
    - (void)logInViewController:(PFLogInViewController *)logInController didFailToLogInWithError:(NSError *)error {
        NSString *errorString = [error userInfo][@"error"];
        NSLog(@"%@",errorString);
    }
    
    // Sent to the delegate when the log in screen is dismissed.
    - (void)logInViewControllerDidCancelLogIn:(PFLogInViewController *)logInController {
        // pop DDimensivaViewController
        [self.navigationController popViewControllerAnimated:YES];
    }
    
#pragma mark - PFSignUpViewControllerDelegate
    // Sent to the delegate to determine whether the sign up request should be submitted to the server.
    - (BOOL)signUpViewController:(PFSignUpViewController *)signUpController shouldBeginSignUp:(NSDictionary *)info {
        BOOL informationComplete = YES;
        
        // loop through all of the submitted data
        for (id key in info) {
            NSString *field = [info objectForKey:key];
            if (!field || field.length == 0) { // check completion
                informationComplete = NO;
                break;
            }
        }
        
        // Display an alert if a field wasn't completed
        if (!informationComplete) {
            [[[UIAlertView alloc] initWithTitle:@"Missing Information"
                                        message:@"Make sure you fill out all of the information!"
                                       delegate:nil
                              cancelButtonTitle:@"ok"
                              otherButtonTitles:nil] show];
        }
        
        return informationComplete;
    }
    // Sent to the delegate when a PFUser is signed up.
    - (void)signUpViewController:(PFSignUpViewController *)signUpController didSignUpUser:(PFUser *)user {
        [self.signUpViewController dismissViewControllerAnimated:YES completion:nil]; // Dismiss the PFSignUpViewController
    }
    
    // Sent to the delegate when the sign up attempt fails.
    - (void)signUpViewController:(PFSignUpViewController *)signUpController didFailToSignUpWithError:(NSError *)error {
        NSLog(@"Failed to sign up...");
    }
    
    // Sent to the delegate when the sign up screen is dismissed.
    - (void)signUpViewControllerDidCancelSignUp:(PFSignUpViewController *)signUpController {
        NSLog(@"User dismissed the signUpViewController");
    }
    
#pragma mark image cropper delegate
    // callback when cropping finished
    - (void)imageCropper:(VPImageCropperViewController *)cropperViewController didFinished:(UIImage *)editedImage{
        PFUser *user = [PFUser currentUser];
        user[kPAPUserProfilePicSmallKey] = editedImage;
        [user saveInBackground];
    }
    // callback when cropping cancelled
    - (void)imageCropperDidCancel:(VPImageCropperViewController *)cropperViewController {
        
    }

@end
