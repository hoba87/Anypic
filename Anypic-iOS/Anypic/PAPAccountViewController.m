//
//  PAPAccountViewController.m
//  Anypic
//
//  Created by Héctor Ramos on 5/2/12.
//  Copyright (c) 2013 Parse. All rights reserved.
//

#import "PAPAccountViewController.h"
#import "PAPPhotoCell.h"
#import "TTTTimeIntervalFormatter.h"
#import "PAPLoadMoreCell.h"
#import "UIImage+ImageEffects.h"
#import "StretchyHeaderCollectionViewLayout.h"
#import "DDimensivaGalleryCollectionViewCell.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <AssetsLibrary/AssetsLibrary.h>

#define ORIGINAL_MAX_WIDTH 640.0f

@interface PAPAccountViewController()
@property (nonatomic, strong) UIView *headerView;
@end

@implementation PAPAccountViewController
static NSString *LoadMoreCellIdentifier = @"LoadMoreCell";

@synthesize headerView;
@synthesize user;
@synthesize header;

#pragma mark - Initialization

- (id)initWithUser:(PFUser *)aUser {
    self = [super init];// initWithStyle:UITableViewStylePlain];
    if (self) {
        self.user = aUser;

        if (!aUser) {
            [NSException raise:NSInvalidArgumentException format:@"PAPAccountViewController init exception: user cannot be nil"];
        }

    }
    return self;
}


#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (!self.user) {
        self.user = [PFUser currentUser];
        [[PFUser currentUser] fetchIfNeeded];
    }
    StretchyHeaderCollectionViewLayout *stretchyLayout;
    stretchyLayout = [[StretchyHeaderCollectionViewLayout alloc] init];
    [stretchyLayout setHeaderReferenceSize:CGSizeMake(320.0, 222.0f)];
    
    // Set our custom layout
    [galleryCollectionView setCollectionViewLayout:stretchyLayout];
    // and tell our collection view to always bounce.
    [galleryCollectionView setAlwaysBounceVertical:YES];
    
    // Then register a class to use for the header.
    [galleryCollectionView registerClass:[UICollectionReusableView class]
       forSupplementaryViewOfKind:UICollectionElementKindSectionHeader
              withReuseIdentifier:@"ident"];

    [galleryCollectionView registerClass:[DDimensivaGalleryCollectionViewCell class] forCellWithReuseIdentifier:LoadMoreCellIdentifier];

    
    self.navigationItem.title = user.username;

//    UIButton *backButton = [UIButton buttonWithType:UIButtonTypeSystem];
//    [backButton setFrame:CGRectMake( 0.0f, 0.0f, 52.0f, 32.0f)];
//    [backButton setTitle:@"Back" forState:UIControlStateNormal];
//    [backButton setTitleColor:[UIColor colorWithRed:214.0f/255.0f green:210.0f/255.0f blue:197.0f/255.0f alpha:1.0] forState:UIControlStateNormal];
//    [[backButton titleLabel] setFont:[UIFont boldSystemFontOfSize:[UIFont smallSystemFontSize]]];
//    [backButton setTitleEdgeInsets:UIEdgeInsetsMake( 0.0f, 5.0f, 0.0f, 0.0f)];
//    [backButton addTarget:self action:@selector(backButtonAction:) forControlEvents:UIControlEventTouchUpInside];
//    [backButton setBackgroundImage:[UIImage imageNamed:@"ButtonBack.png"] forState:UIControlStateNormal];
    
    self.headerView = [[UIView alloc] initWithFrame:CGRectMake( 0.0f, 0.0f, galleryCollectionView.bounds.size.width, 222.0f)];
    [self.headerView setBackgroundColor:[UIColor clearColor]]; // should be clear, this will be the container for our avatar, photo count, follower count, following count, and so on
    
    UIView *texturedBackgroundView = [[UIView alloc] initWithFrame:self.view.bounds];
    [texturedBackgroundView setBackgroundColor:[UIColor clearColor]];
    galleryCollectionView.backgroundView = texturedBackgroundView;

    UIView *profilePictureBackgroundView = [[UIView alloc] initWithFrame:CGRectMake( 94.0f, 38.0f, 132.0f, 132.0f)];
    [profilePictureBackgroundView setBackgroundColor:[UIColor darkGrayColor]];
    profilePictureBackgroundView.alpha = 0.0f;
    CALayer *layer = [profilePictureBackgroundView layer];
    layer.cornerRadius = 66.0f;
    layer.masksToBounds = YES;
    [self.headerView addSubview:profilePictureBackgroundView];
    
    PFImageView *profilePictureImageView = [[PFImageView alloc] initWithFrame:CGRectMake( 94.0f, 38.0f, 132.0f, 132.0f)];
    [self.headerView addSubview:profilePictureImageView];
    [profilePictureImageView setContentMode:UIViewContentModeScaleAspectFill];
    layer = [profilePictureImageView layer];
    layer.cornerRadius = 15.0f;
    layer.masksToBounds = YES;
    profilePictureImageView.alpha = 0.0f;

    if ([PAPUtility userHasProfilePictures:self.user]) {
        PFFile *imageFile = [self.user objectForKey:kPAPUserProfilePicMediumKey];
        [profilePictureImageView setFile:imageFile];
        [profilePictureImageView loadInBackground:^(UIImage *image, NSError *error) {
            if (!error) {
                [UIView animateWithDuration:0.200f animations:^{
                    profilePictureBackgroundView.alpha = 1.0f;
                    profilePictureImageView.alpha = 1.0f;
                }];
                
                UIImageView *backgroundImageView = [[UIImageView alloc] initWithImage:[image applyDarkEffect]];
                backgroundImageView.frame = galleryCollectionView.backgroundView.bounds;
                backgroundImageView.alpha = 0.0f;
                [galleryCollectionView.backgroundView addSubview:backgroundImageView];
                
                [UIView animateWithDuration:0.2f animations:^{
                    backgroundImageView.alpha = 1.0f;
                }];
            }
        }];
    } else {
        [profilePictureImageView setImage:[[PAPUtility defaultProfilePicture] applyDarkEffect]];
        [UIView animateWithDuration:0.200f animations:^{
            profilePictureBackgroundView.alpha = 1.0f;
            profilePictureImageView.alpha = 1.0f;
        }];
        UIImageView *backgroundImageView = [[UIImageView alloc] initWithImage:[[PAPUtility defaultProfilePicture] applyDarkEffect]];
        backgroundImageView.frame = galleryCollectionView.backgroundView.bounds;
        backgroundImageView.alpha = 0.0f;
        [galleryCollectionView.backgroundView addSubview:backgroundImageView];
        
        [UIView animateWithDuration:0.2f animations:^{
            backgroundImageView.alpha = 1.0f;
        }];
    }
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapOnProfilePhoto:)];
    tap.delegate = self;
    [profilePictureImageView setUserInteractionEnabled:YES];
    [profilePictureImageView addGestureRecognizer:tap];
    
    UIImageView *photoCountIconImageView = [[UIImageView alloc] initWithImage:nil];
    [photoCountIconImageView setImage:[UIImage imageNamed:@"iconPics.png"]];
    [photoCountIconImageView setFrame:CGRectMake( 26.0f, 50.0f, 45.0f, 37.0f)];
    [self.headerView addSubview:photoCountIconImageView];
    
    UILabel *photoCountLabel = [[UILabel alloc] initWithFrame:CGRectMake( 0.0f, 94.0f, 92.0f, 22.0f)];
    [photoCountLabel setTextAlignment:NSTextAlignmentCenter];
    [photoCountLabel setBackgroundColor:[UIColor clearColor]];
    [photoCountLabel setTextColor:[UIColor whiteColor]];
    [photoCountLabel setShadowColor:[UIColor colorWithWhite:0.0f alpha:0.300f]];
    [photoCountLabel setShadowOffset:CGSizeMake( 0.0f, -1.0f)];
    [photoCountLabel setFont:[UIFont boldSystemFontOfSize:14.0f]];
    [self.headerView addSubview:photoCountLabel];
#warning todo
//    UIImageView *followersIconImageView = [[UIImageView alloc] initWithImage:nil];
//    [followersIconImageView setImage:[UIImage imageNamed:@"iconFollowers.png"]];
//    [followersIconImageView setFrame:CGRectMake( 247.0f, 40.0f, 52.0f, 51.0f)];
//    [self.headerView addSubview:followersIconImageView];
    
    UILabel *followerCountLabel = [[UILabel alloc] initWithFrame:CGRectMake( 226.0f, 94.0f, self.headerView.bounds.size.width - 226.0f, 16.0f)];
    [followerCountLabel setTextAlignment:NSTextAlignmentCenter];
    [followerCountLabel setBackgroundColor:[UIColor clearColor]];
    [followerCountLabel setTextColor:[UIColor whiteColor]];
    [followerCountLabel setShadowColor:[UIColor colorWithWhite:0.0f alpha:0.300f]];
    [followerCountLabel setShadowOffset:CGSizeMake( 0.0f, -1.0f)];
    [followerCountLabel setFont:[UIFont boldSystemFontOfSize:12.0f]];
    [self.headerView addSubview:followerCountLabel];
    
    UILabel *followingCountLabel = [[UILabel alloc] initWithFrame:CGRectMake( 226.0f, 110.0f, self.headerView.bounds.size.width - 226.0f, 16.0f)];
    [followingCountLabel setTextAlignment:NSTextAlignmentCenter];
    [followingCountLabel setBackgroundColor:[UIColor clearColor]];
    [followingCountLabel setTextColor:[UIColor whiteColor]];
    [followingCountLabel setShadowColor:[UIColor colorWithWhite:0.0f alpha:0.300f]];
    [followingCountLabel setShadowOffset:CGSizeMake( 0.0f, -1.0f)];
    [followingCountLabel setFont:[UIFont boldSystemFontOfSize:12.0f]];
    [self.headerView addSubview:followingCountLabel];
    
    UILabel *userDisplayNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 176.0f, self.headerView.bounds.size.width, 22.0f)];
    [userDisplayNameLabel setTextAlignment:NSTextAlignmentCenter];
    [userDisplayNameLabel setBackgroundColor:[UIColor clearColor]];
    [userDisplayNameLabel setTextColor:[UIColor whiteColor]];
    [userDisplayNameLabel setShadowColor:[UIColor colorWithWhite:0.0f alpha:0.300f]];
    [userDisplayNameLabel setShadowOffset:CGSizeMake( 0.0f, -1.0f)];
    [userDisplayNameLabel setText:[self.user objectForKey:@"displayName"]];
    [userDisplayNameLabel setFont:[UIFont boldSystemFontOfSize:18.0f]];
    [self.headerView addSubview:userDisplayNameLabel];
    
    [photoCountLabel setText:@"0 photos"];
    
    PFQuery *queryPhotoCount = [PFQuery queryWithClassName:kPAPPhotoClassKey];
    [queryPhotoCount whereKey:kPAPPhotoUserKey equalTo:self.user];
    [queryPhotoCount setCachePolicy:kPFCachePolicyCacheThenNetwork];
    [queryPhotoCount countObjectsInBackgroundWithBlock:^(int number, NSError *error) {
        if (!error) {
            [photoCountLabel setText:[NSString stringWithFormat:@"%d photo%@", number, number==1?@"":@"s"]];
            [[PAPCache sharedCache] setPhotoCount:[NSNumber numberWithInt:number] user:self.user];
        }
    }];
    
    [followerCountLabel setText:@"0 followers"];
    
    PFQuery *queryFollowerCount = [PFQuery queryWithClassName:kPAPActivityClassKey];
    [queryFollowerCount whereKey:kPAPActivityTypeKey equalTo:kPAPActivityTypeFollow];
    [queryFollowerCount whereKey:kPAPActivityToUserKey equalTo:self.user];
    [queryFollowerCount setCachePolicy:kPFCachePolicyCacheThenNetwork];
    [queryFollowerCount countObjectsInBackgroundWithBlock:^(int number, NSError *error) {
        if (!error) {
            [followerCountLabel setText:[NSString stringWithFormat:@"%d follower%@", number, number==1?@"":@"s"]];
        }
    }];

    NSDictionary *followingDictionary = [[PFUser currentUser] objectForKey:@"following"];
    [followingCountLabel setText:@"0 following"];
    if (followingDictionary) {
        [followingCountLabel setText:[NSString stringWithFormat:@"%lu following", (unsigned long)[[followingDictionary allValues] count]]];
    }
    
    PFQuery *queryFollowingCount = [PFQuery queryWithClassName:kPAPActivityClassKey];
    [queryFollowingCount whereKey:kPAPActivityTypeKey equalTo:kPAPActivityTypeFollow];
    [queryFollowingCount whereKey:kPAPActivityFromUserKey equalTo:self.user];
    [queryFollowingCount setCachePolicy:kPFCachePolicyCacheThenNetwork];
    [queryFollowingCount countObjectsInBackgroundWithBlock:^(int number, NSError *error) {
        if (!error) {
            [followingCountLabel setText:[NSString stringWithFormat:@"%d following", number]];
        }
    }];
    
    if (![[self.user objectId] isEqualToString:[[PFUser currentUser] objectId]]) {
        UIActivityIndicatorView *loadingActivityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        [loadingActivityIndicatorView startAnimating];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:loadingActivityIndicatorView];
        
        // check if the currentUser is following this user
        PFQuery *queryIsFollowing = [PFQuery queryWithClassName:kPAPActivityClassKey];
        [queryIsFollowing whereKey:kPAPActivityTypeKey equalTo:kPAPActivityTypeFollow];
        [queryIsFollowing whereKey:kPAPActivityToUserKey equalTo:self.user];
        [queryIsFollowing whereKey:kPAPActivityFromUserKey equalTo:[PFUser currentUser]];
        [queryIsFollowing setCachePolicy:kPFCachePolicyCacheThenNetwork];
        [queryIsFollowing countObjectsInBackgroundWithBlock:^(int number, NSError *error) {
            if (error && [error code] != kPFErrorCacheMiss) {
                NSLog(@"Couldn't determine follow relationship: %@", error);
                self.navigationItem.rightBarButtonItem = nil;
            } else {
                if (number == 0) {
                    [self configureFollowButton];
                } else {
                    [self configureUnfollowButton];
                }
            }
        }];
    }
}
-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self reloadMPODataSourceDataAndViewWithOptions:[NSDictionary dictionaryWithObjectsAndKeys:@"account",@"caller",self.user,@"user",nil]];
}

- (void)dropViewDidBeginRefreshing:(UIRefreshControl *)refreshControl
{
    [mpoDataSource reloadFilesURLArrayWithOptions:[NSDictionary dictionaryWithObjectsAndKeys:@"account",@"caller",self.user,@"user",nil] AndCompletionBlock:^{
        [galleryCollectionView reloadData];
        [refreshControl endRefreshing];
    }];
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView
           viewForSupplementaryElementOfKind:(NSString *)kind
                                 atIndexPath:(NSIndexPath *)indexPath {
    // You can make header an ivar so we only ever create one
    if (!header) {
        
        header = [collectionView dequeueReusableSupplementaryViewOfKind:kind
                                                    withReuseIdentifier:@"ident"
                                                           forIndexPath:indexPath];
        CGRect bounds;
        bounds = [header bounds];
        [header addSubview:headerView];
//        UIImageView *imageView;
//        imageView = [[UIImageView alloc] initWithFrame:bounds];
//        [imageView setImage:[UIImage imageNamed:@"header-background"]];
//        
//        // Make sure the contentMode is set to scale proportionally
//        [imageView setContentMode:UIViewContentModeScaleAspectFill];
//        // Clip the parts of the image that are not in frame
//        [imageView setClipsToBounds:YES];
//        // Set the autoresizingMask to always be the same height as the header
//        [imageView setAutoresizingMask:UIViewAutoresizingFlexibleHeight];
//        // Add the image to our header
//        [header addSubview:imageView];
    }
    return header;
}



#pragma mark - ()

- (void)followButtonAction:(id)sender {
    UIActivityIndicatorView *loadingActivityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    [loadingActivityIndicatorView startAnimating];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:loadingActivityIndicatorView];

    [self configureUnfollowButton];

    [PAPUtility followUserEventually:self.user block:^(BOOL succeeded, NSError *error) {
        if (error) {
            [self configureFollowButton];
        }
    }];
}

- (void)unfollowButtonAction:(id)sender {
    UIActivityIndicatorView *loadingActivityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    [loadingActivityIndicatorView startAnimating];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:loadingActivityIndicatorView];

    [self configureFollowButton];

    [PAPUtility unfollowUserEventually:self.user];
}

- (void)backButtonAction:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)configureFollowButton {
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Follow" style:UIBarButtonItemStylePlain target:self action:@selector(followButtonAction:)];
    [[PAPCache sharedCache] setFollowStatus:NO user:self.user];
}

- (void)configureUnfollowButton {
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Unfollow" style:UIBarButtonItemStylePlain target:self action:@selector(unfollowButtonAction:)];
    [[PAPCache sharedCache] setFollowStatus:YES user:self.user];
}

- (void)didTapOnProfilePhoto:(UIButton *)sender {
    PFUser *current = [PFUser currentUser];
    if ([user.username isEqualToString:current.username]) {
        [self editPortrait];
//        DImageCropViewController *imgCropperVC = [[DImageCropViewController alloc] init];
//        [self presentViewController:imgCropperVC animated:YES completion:^{
//        // TO DO
//        }];
    }

}

- (void)photoHeaderView:(PAPPhotoHeaderView *)photoHeaderView didTapUserButton:(UIButton *)button user:(PFUser *)user {
 
}

- (void)editPortrait {
#warning delete hinzufügen
    UIActionSheet *choiceSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                             delegate:self
                                                    cancelButtonTitle:@"Cancel"
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:@"Capture", @"Library", nil];
    [choiceSheet showInView:self.view];
}


#pragma mark UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        // 拍照
        if ([self isCameraAvailable] && [self doesCameraSupportTakingPhotos]) {
            UIImagePickerController *controller = [[UIImagePickerController alloc] init];
            controller.sourceType = UIImagePickerControllerSourceTypeCamera;
            if ([self isFrontCameraAvailable]) {
                controller.cameraDevice = UIImagePickerControllerCameraDeviceFront;
            }
            NSMutableArray *mediaTypes = [[NSMutableArray alloc] init];
            [mediaTypes addObject:(__bridge NSString *)kUTTypeImage];
            controller.mediaTypes = mediaTypes;
            controller.delegate = self;
            [self presentViewController:controller
                               animated:YES
                             completion:^(void){
                                 NSLog(@"Picker View Controller is presented");
                             }];
        }
        
    } else if (buttonIndex == 1) {
        // 从相册中选取
        if ([self isPhotoLibraryAvailable]) {
            UIImagePickerController *controller = [[UIImagePickerController alloc] init];
            controller.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            NSMutableArray *mediaTypes = [[NSMutableArray alloc] init];
            [mediaTypes addObject:(__bridge NSString *)kUTTypeImage];
            controller.mediaTypes = mediaTypes;
            controller.delegate = self;
            [self presentViewController:controller
                               animated:YES
                             completion:^(void){
                                 NSLog(@"Picker View Controller is presented");
                             }];
        }
    } else if (buttonIndex == 2) {
        [self dismissViewControllerAnimated:YES completion:^{
            
        }];
        
    }
}
#pragma mark - UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [picker dismissViewControllerAnimated:YES completion:^() {
        UIImage *portraitImg = [info objectForKey:@"UIImagePickerControllerOriginalImage"];
        portraitImg = [self imageByScalingToMaxSize:portraitImg];
        // present the cropper view controller
        VPImageCropperViewController *imgCropperVC = [[VPImageCropperViewController alloc] initWithImage:portraitImg cropFrame:CGRectMake(0, 100.0f, self.view.frame.size.width, self.view.frame.size.width) limitScaleRatio:3.0];
        imgCropperVC.delegate = self;
        [self presentViewController:imgCropperVC animated:YES completion:^{
            // TO DO
        }];
    }];
}
#pragma mark image scale utility
- (UIImage *)imageByScalingToMaxSize:(UIImage *)sourceImage {
    if (sourceImage.size.width < ORIGINAL_MAX_WIDTH) return sourceImage;
    CGFloat btWidth = 0.0f;
    CGFloat btHeight = 0.0f;
    if (sourceImage.size.width > sourceImage.size.height) {
        btHeight = ORIGINAL_MAX_WIDTH;
        btWidth = sourceImage.size.width * (ORIGINAL_MAX_WIDTH / sourceImage.size.height);
    } else {
        btWidth = ORIGINAL_MAX_WIDTH;
        btHeight = sourceImage.size.height * (ORIGINAL_MAX_WIDTH / sourceImage.size.width);
    }
    CGSize targetSize = CGSizeMake(btWidth, btHeight);
    return [self imageByScalingAndCroppingForSourceImage:sourceImage targetSize:targetSize];
}

- (UIImage *)imageByScalingAndCroppingForSourceImage:(UIImage *)sourceImage targetSize:(CGSize)targetSize {
    UIImage *newImage = nil;
    CGSize imageSize = sourceImage.size;
    CGFloat width = imageSize.width;
    CGFloat height = imageSize.height;
    CGFloat targetWidth = targetSize.width;
    CGFloat targetHeight = targetSize.height;
    CGFloat scaleFactor = 0.0;
    CGFloat scaledWidth = targetWidth;
    CGFloat scaledHeight = targetHeight;
    CGPoint thumbnailPoint = CGPointMake(0.0,0.0);
    if (CGSizeEqualToSize(imageSize, targetSize) == NO)
    {
        CGFloat widthFactor = targetWidth / width;
        CGFloat heightFactor = targetHeight / height;
        
        if (widthFactor > heightFactor)
            scaleFactor = widthFactor; // scale to fit height
        else
            scaleFactor = heightFactor; // scale to fit width
        scaledWidth  = width * scaleFactor;
        scaledHeight = height * scaleFactor;
        
        // center the image
        if (widthFactor > heightFactor)
        {
            thumbnailPoint.y = (targetHeight - scaledHeight) * 0.5;
        }
        else
            if (widthFactor < heightFactor)
            {
                thumbnailPoint.x = (targetWidth - scaledWidth) * 0.5;
            }
    }
    UIGraphicsBeginImageContext(targetSize); // this will crop
    CGRect thumbnailRect = CGRectZero;
    thumbnailRect.origin = thumbnailPoint;
    thumbnailRect.size.width  = scaledWidth;
    thumbnailRect.size.height = scaledHeight;
    
    [sourceImage drawInRect:thumbnailRect];
    
    newImage = UIGraphicsGetImageFromCurrentImageContext();
    if(newImage == nil) NSLog(@"could not scale image");
    
    //pop the context to get back to the default
    UIGraphicsEndImageContext();
    return newImage;
}

#pragma mark camera utility
- (BOOL)isCameraAvailable{
    return [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera];
}

- (BOOL)isRearCameraAvailable{
    return [UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceRear];
}

- (BOOL)isFrontCameraAvailable {
    return [UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceFront];
}

- (BOOL)doesCameraSupportTakingPhotos {
    return [self cameraSupportsMedia:(__bridge NSString *)kUTTypeImage sourceType:UIImagePickerControllerSourceTypeCamera];
}

- (BOOL)isPhotoLibraryAvailable{
    return [UIImagePickerController isSourceTypeAvailable:
            UIImagePickerControllerSourceTypePhotoLibrary];
}

- (BOOL)canUserPickVideosFromPhotoLibrary{
    return [self
            cameraSupportsMedia:(__bridge NSString *)kUTTypeMovie sourceType:UIImagePickerControllerSourceTypePhotoLibrary];
}

- (BOOL)canUserPickPhotosFromPhotoLibrary{
    return [self
            cameraSupportsMedia:(__bridge NSString *)kUTTypeImage sourceType:UIImagePickerControllerSourceTypePhotoLibrary];
}

- (BOOL)cameraSupportsMedia:(NSString *)paramMediaType sourceType:(UIImagePickerControllerSourceType)paramSourceType{
    __block BOOL result = NO;
    if ([paramMediaType length] == 0) {
        return NO;
    }
    NSArray *availableMediaTypes = [UIImagePickerController availableMediaTypesForSourceType:paramSourceType];
    [availableMediaTypes enumerateObjectsUsingBlock: ^(id obj, NSUInteger idx, BOOL *stop) {
        NSString *mediaType = (NSString *)obj;
        if ([mediaType isEqualToString:paramMediaType]){
            result = YES;
            *stop= YES;
        }
    }];
    return result;
}



#pragma mark VPImageCropperDelegate
- (void)imageCropper:(VPImageCropperViewController *)cropperViewController didFinished:(UIImage *)editedImage {
    PFFile *small = [PFFile fileWithData:UIImageJPEGRepresentation(editedImage, 0.9)];
    user[kPAPUserProfilePicSmallKey] = small;
    [user saveInBackground];
    [cropperViewController dismissViewControllerAnimated:YES completion:^{
        [self dismissViewControllerAnimated:YES completion:^{
            NSLog(@"Profilbild gespeichert");
        }];
    }];
}

- (void)imageCropperDidCancel:(VPImageCropperViewController *)cropperViewController {
    [cropperViewController dismissViewControllerAnimated:YES completion:^{
    }];
}


- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:^(){
    }];
}


@end
