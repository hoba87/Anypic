//
//  PAPAccountViewController.h
//  Anypic
//
//  Created by Héctor Ramos on 5/3/12.
//  Copyright (c) 2013 Parse. All rights reserved.
//

#import "PAPPhotoTimelineViewController.h"
#import "VPImageCropperViewController.h"
@interface PAPAccountViewController : PAPPhotoTimelineViewController <UIActionSheetDelegate, UIImagePickerControllerDelegate, VPImageCropperDelegate, UIGestureRecognizerDelegate> {
}

@property (nonatomic, strong) PFUser *user;
@property (nonatomic, readonly) UICollectionReusableView *header;

- (id)initWithUser:(PFUser *)aUser;

@end
