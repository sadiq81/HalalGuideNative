//
// Created by Privat on 29/11/14.
// Copyright (c) 2014 Eazy It. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HGBaseViewModel.h"
#import "ReactiveCocoa/ReactiveCocoa.h"
#import "Review.h"

@class RACSignal;

@interface CreateReviewViewModel : HGBaseViewModel

@property Location *location;
@property Review *createdReview;

- (instancetype)initWithReviewedLocation:(Location *)reviewedLocation;

+ (instancetype)modelWithReviewedLocation:(Location *)reviewedLocation;

- (void)saveEntity:(NSString *)reviewText rating:(int)rating;

@end