//
//  CreateReviewViewController.m
//  HalalGuide
//
//  Created by Privat on 09/11/14.
//  Copyright (c) 2014 Eazy It. All rights reserved.
//

#import <ALActionBlocks/UIBarButtonItem+ALActionBlocks.h>
#import <Masonry/View+MASAdditions.h>
#import "CreateReviewViewController.h"
#import "LocationViewController.h"
#import "Review.h"

@interface CreateReviewViewController () <EDStarRatingProtocol>

@property(strong, nonatomic) EDStarRating *rating;
@property(strong, nonatomic) SZTextView *review;
@property(strong, nonatomic) UIBarButtonItem *save;

@property(strong, nonatomic) CreateReviewViewModel *viewModel;

@end

@implementation CreateReviewViewController

- (instancetype)initWithViewModel:(CreateReviewViewModel *)viewModel {
    self = [super init];
    if (self) {
        self.viewModel = viewModel;
    }

    return self;
}


+ (instancetype)controllerWithViewModel:(CreateReviewViewModel *)viewModel {
    return [[self alloc] initWithViewModel:viewModel];
}


- (void)viewDidLoad {
    [super viewDidLoad];

    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"CreateReviewViewController.button.regret", nil) style:UIBarButtonItemStylePlain block:^(id weakReference) {
        [self.presentingViewController dismissViewControllerAnimated:true completion:nil];
    }];
    self.navigationItem.rightBarButtonItem = self.save = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"CreateReviewViewController.button.save", nil) style:UIBarButtonItemStylePlain block:^(id weakReference) {
        [self.viewModel saveReview];
    }];

    [self setupViews];
    [self setupViewModel];
    [self setupRating];
    [self setupReview];
    [self updateViewConstraints];
}


- (void)setupViews {

    self.view.backgroundColor = [UIColor whiteColor];

    self.rating = [[EDStarRating alloc] initWithFrame:CGRectZero];
    [self.view addSubview:self.rating];

    self.review = [[SZTextView alloc] initWithFrame:CGRectZero];
    [self.view addSubview:self.review];

}


- (void)setupViewModel {

    [RACObserve(self.viewModel, saving) subscribeNext:^(NSNumber *saving) {
        if (saving.boolValue) {
            [SVProgressHUD showInfoWithStatus:NSLocalizedString(@"CreateReviewViewController.hud.saving", nil) maskType:SVProgressHUDMaskTypeBlack];
        } else {
            [SVProgressHUD dismiss];
        }
    }];

    [[RACObserve(self.viewModel, error) throttle:0.5] subscribeNext:^(NSError *error) {
        if (error) {
            [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"CreateReviewViewController.hud.error", nil)];
        }
    }];

    RACSignal *review = [RACSignal merge:@[[self.review rac_textSignal], RACObserve(self.review, text)]];
    RACSignal *rating = RACObserve(self.rating, rating);

    //TODO is this MVVM?
    RAC(self.viewModel, reviewText) = review;
    RAC(self.viewModel, rating) = rating;

    RAC(self.save, enabled) = [RACSignal combineLatest:@[review, rating] reduce:^(NSString *reviewText, NSNumber *rating) {
        return @([reviewText length] > 30 && rating > 0);
    }];

    [[RACObserve(self.viewModel, createdReview) skip:1] subscribeNext:^(Review *review) {
        if (!self.viewModel.error && review.objectId) {
            [SVProgressHUD showSuccessWithStatus:NSLocalizedString(@"CreateReviewViewController.hud.saved", nil)];
        }
    }];

    [[[[NSNotificationCenter defaultCenter] rac_addObserverForName:SVProgressHUDDidDisappearNotification object:nil] takeUntil:[self rac_willDeallocSignal]] subscribeNext:^(NSNotification *notification) {
        NSString *hudText = [[notification userInfo] valueForKey:SVProgressHUDStatusUserInfoKey];
        if ([hudText isEqualToString:NSLocalizedString(@"CreateReviewViewController.hud.saved", nil)]) {
            [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
        }
    }];

}

- (void)setupRating {

    self.rating.starImage = [UIImage imageNamed:@"EDStarRating.star.unselected"];
    self.rating.starHighlightedImage = [UIImage imageNamed:@"EDStarRating.star.selected"];
    self.rating.maxRating = 5.0;
    self.rating.backgroundColor = [UIColor whiteColor];
    self.rating.delegate = self;
    self.rating.horizontalMargin = 12;
    self.rating.editable = YES;
    self.rating.rating = 1;
    self.rating.displayMode = EDStarRatingDisplayFull;

}

- (void)setupReview {
    self.review.placeholder = NSLocalizedString(@"CreateReviewViewController.textview.placeholder", nil);

    self.review.layer.borderColor = [UIColor lightGrayColor].CGColor;
    self.review.layer.borderWidth = 0.5;
    self.review.layer.cornerRadius = 5;
    self.review.ClipsToBounds = true;
}

- (void)updateViewConstraints {

    [self.rating mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset(8);
        make.left.equalTo(self.view).offset(8);
        make.right.equalTo(self.view).offset(-8);
        make.height.equalTo(@(50));
    }];

    [self.review mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.rating.mas_bottom).offset(8);
        make.left.equalTo(self.view).offset(8);
        make.right.equalTo(self.view).offset(-8);
        make.bottom.equalTo(self.view).offset(-8);
    }];

    [super updateViewConstraints];
}


@end
