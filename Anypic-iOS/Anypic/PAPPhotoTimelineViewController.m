//
//  PAPPhotoTimelineViewController.m
//  Anypic
//
//  Created by Héctor Ramos on 5/2/12.
//

#import "PAPPhotoTimelineViewController.h"
#import "PAPPhotoCell.h"
#import "PAPAccountViewController.h"
#import "PAPPhotoDetailsViewController.h"
#import "PAPUtility.h"
#import "PAPLoadMoreCell.h"
#import "DDimensivaGalleryViewController.h"
#import "DDimensivaMPODataSource.h"
#import "DTopGalleryViewController.h"
#import "DDimensivaGalleryCollectionViewCell.h"


@interface PAPPhotoTimelineViewController ()
@property (nonatomic, assign) BOOL shouldReloadOnAppear;
@property (nonatomic, strong) NSMutableSet *reusableSectionHeaderViews;
@property (nonatomic, strong) NSMutableDictionary *outstandingSectionHeaderQueries;
@end

@implementation PAPPhotoTimelineViewController
@synthesize reusableSectionHeaderViews;
@synthesize shouldReloadOnAppear;
@synthesize outstandingSectionHeaderQueries;

#pragma mark - Initialization

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:PAPTabBarControllerDidFinishEditingPhotoNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:PAPUtilityUserFollowingChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:PAPPhotoDetailsViewControllerUserLikedUnlikedPhotoNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:PAPUtilityUserLikedUnlikedPhotoCallbackFinishedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:PAPPhotoDetailsViewControllerUserCommentedOnPhotoNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:PAPPhotoDetailsViewControllerUserDeletedPhotoNotification object:nil];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

#pragma mark - UIViewController
- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.navigationItem.title = @"Dimensiva";
    mpoDataSource = [DDimensivaMPODataSource sharedInstance];
    
    // init CollectionView
    [galleryCollectionView registerClass:[DDimensivaGalleryCollectionViewCell class] forCellWithReuseIdentifier:@"galleryCellIdentifier"];
    [galleryCollectionView registerClass:[DDimensivaGalleryCollectionViewCell class] forCellWithReuseIdentifier:@"galleryCellIdentifierLS"];
//    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone]; // PFQueryTableViewController reads this in viewDidLoad -- would prefer to throw this in init, but didn't work

    // The className to query on
    self.parseClassName = kPAPPhotoClassKey;

    
    
//    UIView *texturedBackgroundView = [[UIView alloc] initWithFrame:self.view.bounds];
//    texturedBackgroundView.backgroundColor = [UIColor colorWithRed:0.0f/255.0f green:0.0f/255.0f blue:0.0f/255.0f alpha:1.0f];
    galleryCollectionView.backgroundColor = [UIColor dimensivaBackgroundColor];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDidPublishPhoto:) name:PAPTabBarControllerDidFinishEditingPhotoNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userFollowingChanged:) name:PAPUtilityUserFollowingChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDidDeletePhoto:) name:PAPPhotoDetailsViewControllerUserDeletedPhotoNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDidLikeOrUnlikePhoto:) name:PAPPhotoDetailsViewControllerUserLikedUnlikedPhotoNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDidLikeOrUnlikePhoto:) name:PAPUtilityUserLikedUnlikedPhotoCallbackFinishedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDidCommentOnPhoto:) name:PAPPhotoDetailsViewControllerUserCommentedOnPhotoNotification object:nil];
}
//- (void)viewWillAppear:(BOOL)animated {
//#if DEBUG
//    [self reloadMPODataSourceDataAndViewWithOptions:nil];
//#else
//    if (mpoDataSource.isRefreshRecommended) {
//        [self reloadMPODataSourceDataAndViewWithOptions:nil];
//    }
//    else {
//        [galleryCollectionView reloadData];
//    }
//#endif
//}

//- (void)viewDidAppear:(BOOL)animated {
//    [super viewDidAppear:animated];
//    
//    if (self.shouldReloadOnAppear) {
//        self.shouldReloadOnAppear = NO;
//        [self loadObjects];
//    }
//}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}


#pragma mark - PFQueryTableViewController

#pragma mark - UICollectionViewDelegate
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    DDimensivaGalleryCollectionViewCell *cell = nil;
    if UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation]) {
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"galleryCellIdentifier" forIndexPath:indexPath];
    } else {
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"galleryCellIdentifierLS" forIndexPath:indexPath];
    }
    
    [cell setImage:[UIImage imageNamed:@"thumbDimensiva"]];
    
    //    NSString *userName = [[[mpoDataSource photosMetaInfoArray] objectAtIndex:indexPath.row] objectForKey:@"user"];
    //    [cell setCaption:userName];
    
    [self loadCell:cell AtIndexPath:indexPath];
    
    return cell;
}

- (void)loadCell:(DDimensivaGalleryCollectionViewCell *)cell AtIndexPath:(NSIndexPath *)indexPath
{
    [mpoDataSource loadThumbAsynchronouslyAtIndex:indexPath.row WithCompletionBlock:^(UIImage *thumbImage) {
        cell.image = thumbImage;
    }];
    
    PFObject *object = [[[DDimensivaMPODataSource sharedInstance] photosMetaInfoArray] objectAtIndex:indexPath.row];
    
    NSDictionary *attributesForPhoto = [[PAPCache sharedCache] attributesForPhoto:object];
    if (attributesForPhoto) {
        //                    [headerView setLikeStatus:[[PAPCache sharedCache] isPhotoLikedByCurrentUser:photo]];
        [cell setLikeCount:[[[PAPCache sharedCache] likeCountForPhoto:object] description]];
        [cell setCommentCount:[[[PAPCache sharedCache] commentCountForPhoto:object] description]];
        [cell setCaption:[[PAPCache sharedCache] authorNameForPhoto:object]];
    } else {
        cell.likeLabel.alpha = 0.0f;
        cell.commentLabel.alpha = 0.0f;
        cell.captionLabel.alpha = 0.0f;
        cell.commentLabelHelper.alpha = 0.0f;

        @synchronized(self) {
            // check if we can update the cache
            NSNumber *outstandingSectionHeaderQueryStatus = [self.outstandingSectionHeaderQueries objectForKey:[NSNumber numberWithInteger:indexPath.row]];
            if (!outstandingSectionHeaderQueryStatus) {
                PFQuery *query = [PAPUtility queryForActivitiesOnPhoto:object cachePolicy:kPFCachePolicyNetworkOnly];
                [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                    @synchronized(self) {
                            [self.outstandingSectionHeaderQueries removeObjectForKey:[NSNumber numberWithInteger:indexPath.row]];
                            if (error) {
                                return;
                            }
                            
                            NSMutableArray *likers = [NSMutableArray array];
                            NSMutableArray *commenters = [NSMutableArray array];
                            BOOL isLikedByCurrentUser = NO;
                            for (PFObject *activity in objects) {
                                if ([[activity objectForKey:kPAPActivityTypeKey] isEqualToString:kPAPActivityTypeLike] && [activity objectForKey:kPAPActivityFromUserKey]) {
                                    [likers addObject:[activity objectForKey:kPAPActivityFromUserKey]];
                                } else if ([[activity objectForKey:kPAPActivityTypeKey] isEqualToString:kPAPActivityTypeComment] && [activity objectForKey:kPAPActivityFromUserKey]) {
                                    [commenters addObject:[activity objectForKey:kPAPActivityFromUserKey]];
                                }
                            if ([[[activity objectForKey:kPAPActivityFromUserKey] objectId] isEqualToString:[[PFUser currentUser] objectId]]) {
                                if ([[activity objectForKey:kPAPActivityTypeKey] isEqualToString:kPAPActivityTypeLike]) {
                                    isLikedByCurrentUser = YES;
                                    }
                                }
                            }
                            NSString *author = @"N/A";
                            if ([objects count] > 0) {
                                author = [[[objects firstObject] objectForKey:@"photo"] objectForKey:@"user"];
                            } else {
                                PFObject *photo = [[[[mpoDataSource photosMetaInfoArray] objectAtIndex:indexPath.row]
                                  objectForKey:@"userObject"] fetchIfNeeded];
                                    author = [photo objectForKey:kPAPUserDisplayNameKey];
//                                }];
                            }

                            [[PAPCache sharedCache] setAttributesForPhoto:object authorName:author likers:likers commenters:commenters likedByCurrentUser:isLikedByCurrentUser];

                            [cell setLikeCount:[[[PAPCache sharedCache] likeCountForPhoto:object] description]];
                            [cell setCommentCount:[[[PAPCache sharedCache] commentCountForPhoto:object] description]];
                            [cell setCaption:[[PAPCache sharedCache] authorNameForPhoto:object]];
                            
                            if (cell.likeLabel.alpha < 1.0f || cell.commentLabel.alpha < 1.0f || cell.captionLabel.alpha < 1.0f) {
                                [UIView animateWithDuration:0.200f animations:^{
                                    cell.likeLabel.alpha = 0.6f;
                                    cell.commentLabel.alpha = 0.6f;
                                    cell.captionLabel.alpha = 0.6f;
                                    cell.commentLabelHelper.alpha = 0.6f;
                                }];
                            }

//
#warning todo
                            //      [headerView setLikeStatus:[[PAPCache sharedCache] isPhotoLikedByCurrentUser:object]];
                            
                        }
                    }];
                }
            }
        }
    ////
    if ([indicesToEdit containsObject:indexPath]) {
        cell.alpha = 0.3;
    } else {
        cell.alpha = 1.0;
    }
}

#pragma mark - PAPPhotoHeaderViewDelegate

- (void)photoHeaderView:(PAPPhotoHeaderView *)photoHeaderView didTapUserButton:(UIButton *)button user:(PFUser *)user {
    PAPAccountViewController *accountViewController = [[PAPAccountViewController alloc] initWithUser:user];
    NSLog(@"Presenting account view controller with user: %@", user);
    [accountViewController setUser:user];
    [self.navigationController pushViewController:accountViewController animated:YES];
}
//
- (void)userDidLikeOrUnlikePhoto:(NSNotification *)note {
    [self reloadMPODataSourceDataAndViewWithOptions:nil];
//    [self.tableView beginUpdates];
//    [self.tableView endUpdates];
}

- (void)userDidCommentOnPhoto:(NSNotification *)note {
    [self reloadMPODataSourceDataAndViewWithOptions:nil];
//    [self.tableView beginUpdates];
//    [self.tableView endUpdates];
}

- (void)userDidDeletePhoto:(NSNotification *)note {
    // refresh timeline after a delay
    dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, 1.0 * NSEC_PER_SEC);
    dispatch_after(time, dispatch_get_main_queue(), ^(void){
        [self reloadMPODataSourceDataAndViewWithOptions:nil];
    });
}

- (void)userDidPublishPhoto:(NSNotification *)note {
//    if (self.objects.count > 0) {
//        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
//    }

    [self reloadMPODataSourceDataAndViewWithOptions:nil];
}

- (void)userFollowingChanged:(NSNotification *)note {
    NSLog(@"User following changed.");
    self.shouldReloadOnAppear = YES;
}


- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    PFObject *photo = [[[DDimensivaMPODataSource sharedInstance] photosMetaInfoArray] objectAtIndex:indexPath.row];
    if (photo) {
        PAPPhotoDetailsViewController *photoDetailsVC = [[PAPPhotoDetailsViewController alloc] initWithPhoto:photo];
        [self.navigationController pushViewController:photoDetailsVC animated:YES];
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation])) {
        return CGSizeMake(170, 210);
    }
    else {
        return CGSizeMake(155, 195);
    }
}

@end
