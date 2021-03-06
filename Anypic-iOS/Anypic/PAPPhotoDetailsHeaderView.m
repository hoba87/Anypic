//
//  PAPPhotoDetailsHeaderView.m
//  Anypic
//
//  Created by Mattieu Gamache-Asselin on 5/15/12.
//  Copyright (c) 2013 Parse. All rights reserved.
//

#import "PAPPhotoDetailsHeaderView.h"
#import "PAPProfileImageView.h"
#import "TTTTimeIntervalFormatter.h"
#import <ParseUI/ParseUI.h>
#import "MPOSideBySideImageView.h"
#import "MPOAnaglyphImageView.h"
#import "MPOParallaxImageView.h"

#define baseHorizontalOffset 0.0f
#define baseWidth 320.0f

#define horiBorderSpacing 6.0f
#define horiMediumSpacing 8.0f

#define vertBorderSpacing 6.0f
#define vertSmallSpacing 2.0f


#define nameHeaderX baseHorizontalOffset
#define nameHeaderY 0.0f
#define nameHeaderWidth baseWidth
#define nameHeaderHeight 46.0f

#define avatarImageX horiBorderSpacing
#define avatarImageY vertBorderSpacing
#define avatarImageDim 35.0f

#define nameLabelX avatarImageX+avatarImageDim+horiMediumSpacing
#define nameLabelY avatarImageY+vertSmallSpacing
#define nameLabelMaxWidth 280.0f - (horiBorderSpacing+avatarImageDim+horiMediumSpacing+horiBorderSpacing)

#define timeLabelX nameLabelX
#define timeLabelMaxWidth nameLabelMaxWidth

#define mainImageX baseHorizontalOffset
#define mainImageY nameHeaderHeight
#define mainImageWidth baseWidth
#define mainImageHeight 320.0f

#define likeBarX baseHorizontalOffset
#define likeBarY nameHeaderHeight + mainImageHeight
#define likeBarWidth baseWidth
#define likeBarHeight 43.0f

#define likeButtonX 0.0f
#define likeButtonY 0.0f
#define likeButtonDim 48.0f

#define likeProfileXBase 46.0f
#define likeProfileXSpace 3.0f
#define likeProfileY 6.0f
#define likeProfileDim 30.0f

#define viewTotalHeight likeBarY+likeBarHeight
#define numLikePics 7.0f

@interface PAPPhotoDetailsHeaderView (){
    NSInteger mpoImage3DViewOption;
}

// View components
@property (nonatomic, strong) UIView *nameHeaderView;
@property (nonatomic, strong) PFImageView *photoImageView;
@property (nonatomic, strong) UIView *likeBarView;
@property (nonatomic, strong) NSMutableArray *currentLikeAvatars;

// Redeclare for edit
@property (nonatomic, strong, readwrite) PFUser *photographer;

// Private methods
- (void)createView;

@property (strong, nonatomic) MPOImageView *mpoImageView;


@end


static TTTTimeIntervalFormatter *timeFormatter;

@implementation PAPPhotoDetailsHeaderView

@synthesize photo;
@synthesize photographer;
@synthesize likeUsers;
@synthesize nameHeaderView;
@synthesize photoImageView;
@synthesize likeBarView;
@synthesize likeButton;
@synthesize delegate;
@synthesize currentLikeAvatars;

#pragma mark - NSObject

- (id)initWithFrame:(CGRect)frame photo:(PFObject*)aPhoto {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        if (!timeFormatter) {
            timeFormatter = [[TTTTimeIntervalFormatter alloc] init];
        }
        
        self.photo = aPhoto;
        self.photographer = [self.photo objectForKey:kPAPPhotoUserKey];
        self.likeUsers = nil;
        
        self.backgroundColor = [UIColor clearColor];
        [self createView];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame photo:(PFObject*)aPhoto photographer:(PFUser*)aPhotographer likeUsers:(NSArray*)theLikeUsers {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        if (!timeFormatter) {
            timeFormatter = [[TTTTimeIntervalFormatter alloc] init];
        }

        self.photo = aPhoto;
        self.photographer = aPhotographer;
        self.likeUsers = theLikeUsers;
        
        self.backgroundColor = [UIColor clearColor];

        if (self.photo && self.photographer && self.likeUsers) {
            [self createView];
        }
        mpoImage3DViewOption = -1;

        
    }
    return self;
}

#pragma mark - PAPPhotoDetailsHeaderView

+ (CGRect)rectForView {
    return CGRectMake( 0.0f, 0.0f, [UIScreen mainScreen].bounds.size.width, viewTotalHeight);
}

- (void)setPhoto:(PFObject *)aPhoto {
    photo = aPhoto;

    if (self.photo && self.photographer && self.likeUsers) {
        [self createView];
        [self setNeedsDisplay];
    }
}

- (void)setLikeUsers:(NSMutableArray *)anArray {
    likeUsers = [anArray sortedArrayUsingComparator:^NSComparisonResult(PFUser *liker1, PFUser *liker2) {
        NSString *displayName1 = [liker1 objectForKey:kPAPUserDisplayNameKey];
        NSString *displayName2 = [liker2 objectForKey:kPAPUserDisplayNameKey];
        
        if ([[liker1 objectId] isEqualToString:[[PFUser currentUser] objectId]]) {
            return NSOrderedAscending;
        } else if ([[liker2 objectId] isEqualToString:[[PFUser currentUser] objectId]]) {
            return NSOrderedDescending;
        }
        
        return [displayName1 compare:displayName2 options:NSCaseInsensitiveSearch|NSDiacriticInsensitiveSearch];
    }];;
    
    for (PAPProfileImageView *image in currentLikeAvatars) {
        [image removeFromSuperview];
    }

    [likeButton setTitle:[NSString stringWithFormat:@"%lu", (unsigned long)self.likeUsers.count] forState:UIControlStateNormal];

    self.currentLikeAvatars = [[NSMutableArray alloc] initWithCapacity:likeUsers.count];
    NSInteger i;
    NSInteger numOfPics = numLikePics > self.likeUsers.count ? self.likeUsers.count : numLikePics;

    for (i = 0; i < numOfPics; i++) {
        PAPProfileImageView *profilePic = [[PAPProfileImageView alloc] init];
        [profilePic setFrame:CGRectMake(likeProfileXBase + i * (likeProfileXSpace + likeProfileDim), likeProfileY, likeProfileDim, likeProfileDim)];
        [profilePic.profileButton addTarget:self action:@selector(didTapLikerButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        profilePic.profileButton.tag = i;

        
        if ([PAPUtility userHasProfilePictures:[self.likeUsers objectAtIndex:i]]) {
            [profilePic setFile:[[self.likeUsers objectAtIndex:i] objectForKey:kPAPUserProfilePicSmallKey]];
        } else {
            [profilePic setImage:[PAPUtility defaultProfilePicture]];
        }

        [likeBarView addSubview:profilePic];
        [currentLikeAvatars addObject:profilePic];
    }
    
    [self setNeedsDisplay];
}

- (void)setLikeButtonState:(BOOL)selected {
    if (selected) {
        [likeButton setTitleEdgeInsets:UIEdgeInsetsMake( -1.0f, 0.0f, 0.0f, 0.0f)];
    } else {
        [likeButton setTitleEdgeInsets:UIEdgeInsetsMake( 0.0f, 0.0f, 0.0f, 0.0f)];
    }
    [likeButton setSelected:selected];
}

- (void)reloadLikeBar {
    self.likeUsers = [[PAPCache sharedCache] likersForPhoto:self.photo];
    [self setLikeButtonState:[[PAPCache sharedCache] isPhotoLikedByCurrentUser:self.photo]];
    [likeButton addTarget:self action:@selector(didTapLikePhotoButtonAction:) forControlEvents:UIControlEventTouchUpInside];    
}


#pragma mark - ()

- (void)createView {    
    /*
     Create middle section of the header view; the image
     */
//    self.photoImageView = [[PFImageView alloc] initWithFrame:CGRectMake(mainImageX, mainImageY, mainImageWidth, mainImageHeight)];
    CGRect frame = CGRectMake(mainImageX, mainImageY, mainImageWidth, mainImageHeight);
//    DDimensivaMPODataSource *datasource = [DDimensivaMPODataSource sharedInstance];
//    self.mpoViewController = [[DMPOViewController alloc] initWithDataSource:datasource AndIndex:1];
////    self.photoImageView.image = [UIImage imageNamed:@"PlaceholderPhoto.png"];
    
        NSNumber *viewOption3DView = [[NSUserDefaults standardUserDefaults] objectForKey:kViewOption3DView];
//        if (mpoImage3DViewOption != viewOption3DView.integerValue) {
            if (self.mpoImageView != nil) {
                [self.mpoImageView removeFromSuperview];
            }
            
            mpoImage3DViewOption = viewOption3DView.integerValue;
            switch (viewOption3DView.integerValue) {
                case 0:
                    self.mpoImageView = [[MPOSideBySideImageView alloc] initWithFrame:frame];
                    ((MPOSideBySideImageView *)self.mpoImageView).crossView = NO;
                    break;
                case 1:
                    self.mpoImageView = [[MPOSideBySideImageView alloc] initWithFrame:frame];
                    ((MPOSideBySideImageView *)self.mpoImageView).crossView = YES;
                    break;
                case 2:
                    self.mpoImageView = [[MPOAnaglyphImageView alloc] initWithFrame:frame];
                    break;
                case 3:
                    self.mpoImageView = [[MPOParallaxImageView alloc] initWithFrame:frame];
                    break;
                default:
                    break;
            }
            
            [self addSubview:self.mpoImageView];
            self.mpoImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
//        }
    [photo fetchIfNeededInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        PFFile *image = photo[@"picture"];
        [image getDataInBackgroundWithBlock:^(NSData *imageData, NSError *error) {
            if (!error) {
                MPOImage *mpoImage = [[MPOImage alloc] initWithMPOData:imageData];
                [self.mpoImageView setMpoImage:mpoImage];
//                assert(completionBlock != nil);
//                completionBlock(mpoImage);
//                
//                if ([[NSUserDefaults standardUserDefaults] boolForKey:@"autosave"] == YES) {
//                    [mpoImage writeToFile];
//                }
            }
        }];
    }];

    
    
    
//        [[NSNotificationCenter defaultCenter] postNotificationName:kAirplayNotificationImageChanged object:self userInfo:[NSDictionary dictionaryWithObject:mpoImage forKey:@"MPOImage"]];

//    PFFile *imageFile = [self.photo objectForKey:kPAPPhotoPictureKey];
//    if (imageFile) {
//        self.photoImageView.file = imageFile;
//        [self.photoImageView loadInBackground];
//    }
    
//    [self addSubview:self.photoImageView];
    
    /*
     Create top of header view with name and avatar
     */
    self.nameHeaderView = [[UIView alloc] initWithFrame:CGRectMake(nameHeaderX, nameHeaderY, nameHeaderWidth, nameHeaderHeight)];
    self.nameHeaderView.backgroundColor = [UIColor whiteColor];
    [self addSubview:self.nameHeaderView];
    
    // Load data for header
    [self.photographer fetchIfNeededInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        // Create avatar view
        PAPProfileImageView *avatarImageView = [[PAPProfileImageView alloc] initWithFrame:CGRectMake(avatarImageX, avatarImageY, avatarImageDim, avatarImageDim)];

        if ([PAPUtility userHasProfilePictures:self.photographer]) {
            [avatarImageView setFile:[self.photographer objectForKey:kPAPUserProfilePicSmallKey]];
        } else {
            [avatarImageView setImage:[PAPUtility defaultProfilePicture]];
        }

        [avatarImageView setBackgroundColor:[UIColor clearColor]];
        [avatarImageView setOpaque:NO];
        [avatarImageView.profileButton addTarget:self action:@selector(didTapUserNameButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        [avatarImageView setContentMode:UIViewContentModeScaleAspectFill];
        avatarImageView.layer.cornerRadius = 17.5f;
        avatarImageView.layer.masksToBounds = YES;
        //[avatarImageView load:^(UIImage *image, NSError *error) {}];
        [nameHeaderView addSubview:avatarImageView];
        
        // Create name label
        NSString *nameString = [self.photographer objectForKey:kPAPUserDisplayNameKey];
        UIButton *userButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [nameHeaderView addSubview:userButton];
        [userButton setBackgroundColor:[UIColor clearColor]];
        [[userButton titleLabel] setFont:[UIFont boldSystemFontOfSize:15.0f]];
        [userButton setTitle:nameString forState:UIControlStateNormal];
        [userButton setTitleColor:[UIColor colorWithRed:34.0f/255.0f green:34.0f/255.0f blue:34.0f/255.0f alpha:1.0f] forState:UIControlStateNormal];
        [userButton setTitleColor:[UIColor colorWithRed:114.0f/255.0f green:114.0f/255.0f blue:114.0f/255.0f alpha:1.0f] forState:UIControlStateHighlighted];
        [[userButton titleLabel] setLineBreakMode:NSLineBreakByTruncatingTail];
        [userButton addTarget:self action:@selector(didTapUserNameButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        
        // we resize the button to fit the user's name to avoid having a huge touch area
        CGPoint userButtonPoint = CGPointMake(50.0f, 6.0f);
        CGFloat constrainWidth = self.nameHeaderView.bounds.size.width - (avatarImageView.bounds.origin.x + avatarImageView.bounds.size.width);
        CGSize constrainSize = CGSizeMake(constrainWidth, self.nameHeaderView.bounds.size.height - userButtonPoint.y*2.0f);
        CGSize userButtonSize = [userButton.titleLabel.text boundingRectWithSize:constrainSize
                                                                         options:NSStringDrawingTruncatesLastVisibleLine|NSStringDrawingUsesLineFragmentOrigin
                                                                      attributes:@{NSFontAttributeName:userButton.titleLabel.font}
                                                                         context:nil].size;

        
        CGRect userButtonFrame = CGRectMake(userButtonPoint.x, userButtonPoint.y, userButtonSize.width, userButtonSize.height);
        [userButton setFrame:userButtonFrame];
        
        // Create time label
        NSString *timeString = [timeFormatter stringForTimeIntervalFromDate:[NSDate date] toDate:[self.photo createdAt]];
        CGSize timeLabelSize = [timeString boundingRectWithSize:CGSizeMake(nameLabelMaxWidth, CGFLOAT_MAX)
                                                        options:NSStringDrawingTruncatesLastVisibleLine|NSStringDrawingUsesLineFragmentOrigin
                                                     attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:11.0f]}
                                                        context:nil].size;
        
        UILabel *timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(timeLabelX, nameLabelY+userButtonSize.height, timeLabelSize.width, timeLabelSize.height)];
        [timeLabel setText:timeString];
        [timeLabel setFont:[UIFont systemFontOfSize:11.0f]];
        [timeLabel setTextColor:[UIColor colorWithRed:114.0f/255.0f green:114.0f/255.0f blue:114.0f/255.0f alpha:1.0f]];
        [timeLabel setBackgroundColor:[UIColor clearColor]];
        [self.nameHeaderView addSubview:timeLabel];
        
        [self setNeedsDisplay];
    }];
    
    /*
     Create bottom section fo the header view; the likes
     */
    likeBarView = [[UIView alloc] initWithFrame:CGRectMake(likeBarX, likeBarY, likeBarWidth, likeBarHeight)];
    [likeBarView setBackgroundColor:[UIColor whiteColor]];
    [self addSubview:likeBarView];
    
    // Create the heart-shaped like button
    likeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [likeButton setFrame:CGRectMake(likeButtonX, likeButtonY, likeButtonDim, likeButtonDim)];
    [likeButton setBackgroundColor:[UIColor clearColor]];
    [likeButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [likeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
    [likeButton setTitleEdgeInsets:UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, 0.0f)];
    [[likeButton titleLabel] setFont:[UIFont systemFontOfSize:12.0f]];
    [[likeButton titleLabel] setMinimumScaleFactor:0.8f];
    [[likeButton titleLabel] setAdjustsFontSizeToFitWidth:YES];
    [likeButton setAdjustsImageWhenDisabled:NO];
    [likeButton setAdjustsImageWhenHighlighted:NO];
    [likeButton setBackgroundImage:[UIImage imageNamed:@"buttonLike.png"] forState:UIControlStateNormal];
    [likeButton setBackgroundImage:[UIImage imageNamed:@"buttonLikeSelected.png"] forState:UIControlStateSelected];
    [likeButton addTarget:self action:@selector(didTapLikePhotoButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [likeBarView addSubview:likeButton];
    
    [self reloadLikeBar];
    
    UIImageView *separator = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"separatorComments.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(0.0f, 1.0f, 0.0f, 1.0f)]];
    [separator setFrame:CGRectMake(0.0f, likeBarView.frame.size.height - 1.0f, likeBarView.frame.size.width, 1.0f)];
    //[likeBarView addSubview:separator];
}

- (void)didTapLikePhotoButtonAction:(UIButton *)button {
    BOOL liked = !button.selected;
    [button removeTarget:self action:@selector(didTapLikePhotoButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self setLikeButtonState:liked];

    NSArray *originalLikeUsersArray = [NSArray arrayWithArray:self.likeUsers];
    NSMutableSet *newLikeUsersSet = [NSMutableSet setWithCapacity:[self.likeUsers count]];
    
    for (PFUser *likeUser in self.likeUsers) {
        // add all current likeUsers BUT currentUser
        if (![[likeUser objectId] isEqualToString:[[PFUser currentUser] objectId]]) {
            [newLikeUsersSet addObject:likeUser];
        }
    }
    
    if (liked) {
        [[PAPCache sharedCache] incrementLikerCountForPhoto:self.photo];
        [newLikeUsersSet addObject:[PFUser currentUser]];
    } else {
        [[PAPCache sharedCache] decrementLikerCountForPhoto:self.photo];
    }
    
    [[PAPCache sharedCache] setPhotoIsLikedByCurrentUser:self.photo liked:liked];

    [self setLikeUsers:[newLikeUsersSet allObjects]];

    if (liked) {
        [PAPUtility likePhotoInBackground:self.photo block:^(BOOL succeeded, NSError *error) {
            if (!succeeded) {
                [button addTarget:self action:@selector(didTapLikePhotoButtonAction:) forControlEvents:UIControlEventTouchUpInside];
                [self setLikeUsers:originalLikeUsersArray];
                [self setLikeButtonState:NO];
            }
        }];
    } else {
        [PAPUtility unlikePhotoInBackground:self.photo block:^(BOOL succeeded, NSError *error) {
            if (!succeeded) {
                [button addTarget:self action:@selector(didTapLikePhotoButtonAction:) forControlEvents:UIControlEventTouchUpInside];
                [self setLikeUsers:originalLikeUsersArray];
                [self setLikeButtonState:YES];
            }
        }];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:PAPPhotoDetailsViewControllerUserLikedUnlikedPhotoNotification object:self.photo userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:liked] forKey:PAPPhotoDetailsViewControllerUserLikedUnlikedPhotoNotificationUserInfoLikedKey]];
}

- (void)didTapLikerButtonAction:(UIButton *)button {
    PFUser *user = [self.likeUsers objectAtIndex:button.tag];
    if (delegate && [delegate respondsToSelector:@selector(photoDetailsHeaderView:didTapUserButton:user:)]) {
        [delegate photoDetailsHeaderView:self didTapUserButton:button user:user];
    }    
}

- (void)didTapUserNameButtonAction:(UIButton *)button {
    if (delegate && [delegate respondsToSelector:@selector(photoDetailsHeaderView:didTapUserButton:user:)]) {
        [delegate photoDetailsHeaderView:self didTapUserButton:button user:self.photographer];
    }    
}

@end
