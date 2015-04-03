//
// Created by Privat on 31/03/15.
// Copyright (c) 2015 Eazy It. All rights reserved.
//
#import <Foundation/Foundation.h>
#import "UIKit/UIKit.h"
#import "SevenSwitch.h"
#import "LocationViewModel.h"

@interface HGSwitchView : UIView

@property(strong, nonatomic, readonly) SevenSwitch *halalSwitch;
@property(strong, nonatomic, readonly) UILabel *halalLabel;

@property(strong, nonatomic, readonly) SevenSwitch *alcoholSwitch;
@property(strong, nonatomic, readonly) UILabel *alcoholLabel;

@property(strong, nonatomic, readonly) SevenSwitch *porkSwitch;
@property(strong, nonatomic, readonly) UILabel *porkLabel;

@property(strong, nonatomic, readonly) LocationViewModel *viewModel;

- (id)initWithViewModel:(LocationViewModel *)model;
@end

