//
//  PAPPhotoTimelineViewController.h
//  Anypic
//
//  Created by Héctor Ramos on 5/3/12.
//  Copyright (c) 2013 Parse. All rights reserved.
//

#import "PAPPhotoHeaderView.h"
#import "DTemplateGalleryViewController.h"
#import "DDimensivaGalleryCollectionViewCell.h"

@interface PAPPhotoTimelineViewController : DTemplateGalleryViewController <PAPPhotoHeaderViewDelegate>

@property (strong,nonatomic) NSString *parseClassName;

- (void)loadCell:(DDimensivaGalleryCollectionViewCell *)cell AtIndexPath:(NSIndexPath *)indexPath;

@end
