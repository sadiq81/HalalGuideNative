//
//  CreateDiningViewController.m
//  HalalGuide
//
//  Created by Privat on 09/11/14.
//  Copyright (c) 2014 Eazy It. All rights reserved.
//

#import <ALActionBlocks/UIControl+ALActionBlocks.h>
#import <ALActionBlocks/UIBarButtonItem+ALActionBlocks.h>
#import <LinqToObjectiveC/NSArray+LinqExtensions.h>
#import <SVProgressHUD/SVProgressHUD.h>
#import "CreateDiningViewController.h"
#import "CategoriesViewController.h"
#import "CreateDiningViewModel.h"
#import "MZFormSheetSegue.h"
#import "IQUIView+Hierarchy.h"
#import "Adgangsadresse.h"
#import "IQKeyboardReturnKeyHandler.h"
#import "UIAlertController+Blocks.h"
#import "CreateReviewViewModel.h"

//TODO Opening hours

@implementation CreateDiningViewController {
    IQKeyboardReturnKeyHandler *returnKeyHandler;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [[CreateDiningViewModel instance] reset];

    [CreateDiningViewModel instance].categories = [NSMutableArray new];

    returnKeyHandler = [[IQKeyboardReturnKeyHandler alloc] initWithViewController:self];

    self.road.autocompleteDataSource = self;
    self.roadNumber.autocompleteDataSource = self;

    [self setupEvents];
}

- (void)setupEvents {

    [[CreateDiningViewModel instance] loadAddressesNearPositionOnCompletion:nil];

    __weak typeof(self) weakSelf = self;

    [self.pickImage handleControlEvents:UIControlEventTouchUpInside withBlock:^(UIButton *weakSender) {
        [[CreateDiningViewModel instance] getPicture:weakSelf withDelegate:weakSelf];
    }];

    [self.road handleControlEvents:UIControlEventEditingDidEnd withBlock:^(UITextField *weakSender) {
        Postnummer *postnummer = [[CreateDiningViewModel instance] postalCodeFor:weakSender.text];
        if (postnummer) {
            weakSelf.postalCode.text = postnummer.nr;
            weakSelf.city.text = postnummer.navn;
        }
    }];

    [self.postalCode handleControlEvents:UIControlEventEditingDidEnd withBlock:^(UITextField *weakSender) {
        [[CreateDiningViewModel instance] cityNameFor:weakSender.text onCompletion:^(Postnummer *postnummer) {
            if (postnummer) {
                weakSelf.city.text = postnummer.navn;
            }
        }];
    }];

    [self.porkSwitch handleControlEvents:UIControlEventValueChanged withBlock:^(UISwitch *weakSender) {
        weakSelf.porkImage.image = [UIImage imageNamed:weakSender.on ? @"PigTrue" : @"PigFalse"];
    }];

    [self.alcoholSwitch handleControlEvents:UIControlEventValueChanged withBlock:^(UISwitch *weakSender) {
        weakSelf.alcoholImage.image = [UIImage imageNamed:weakSender.on ? @"AlcoholTrue" : @"AlcoholFalse"];
    }];

    [self.halalSwitch handleControlEvents:UIControlEventValueChanged withBlock:^(UISwitch *weakSender) {
        weakSelf.halalImage.image = [UIImage imageNamed:weakSender.on ? @"NonHalalTrue" : @"NonHalalFalse"];
    }];

    [self.reset handleControlEvents:UIControlEventTouchUpInside withBlock:^(UIButton *weakSender) {
        [[CreateDiningViewModel instance].categories removeAllObjects];
        [weakSelf setUILabels];
    }];

    [self.regret setBlock:^(id weakSender) {
        [weakSelf.navigationController popViewControllerAnimated:true];
    }];

    [self.save setBlock:^(id weakSender) {
        if ([weakSelf areMandatoryFieldsFilledOut]) {
            [[CreateDiningViewModel instance] saveEntity:weakSelf.name.text
                                                    road:weakSelf.road.text
                                              roadNumber:weakSelf.roadNumber.text
                                              postalCode:weakSelf.postalCode.text
                                                    city:weakSelf.city.text
                                               telephone:weakSelf.telephone.text
                                                 website:weakSelf.website.text
                                                    pork:weakSelf.porkSwitch.on
                                                 alcohol:weakSelf.alcoholSwitch.on
                                                nonHalal:weakSelf.halalSwitch.on
                                                   image:weakSelf.image
                                            onCompletion:^(CreateEntityResult result) {

                                                [weakSelf showDialog:result];

                                            }];
        }
    }];
}

- (void)showDialog:(CreateEntityResult)result {

    __weak typeof(self) weakSelf = self;

    switch (result) {
        case CreateEntityResultAddressDoesNotExist: {
                [UIAlertController showAlertInViewController:self withTitle:NSLocalizedString(@"GPSNotPreciseEnough", nil) message:nil cancelButtonTitle:NSLocalizedString(@"no", nil) destructiveButtonTitle:nil otherButtonTitles:@[NSLocalizedString(@"yes", nil)] tapBlock:^(UIAlertController *controller, UIAlertAction *action, NSInteger buttonIndex) {

                if (UIAlertControllerBlocksFirstOtherButtonIndex == buttonIndex) {
                    [[CreateDiningViewModel instance] findAddressByDescription:weakSelf.road.text roadNumber:weakSelf.roadNumber.text postalCode:weakSelf.postalCode.text onCompletion:^{
                        [CreateDiningViewModel instance].suggestionName = weakSelf.name.text;
                        [self performSegueWithIdentifier:@"ChooseGPSPoint" sender:self];
                    }];
                }
            }];
            break;
        }
        case CreateEntityResultCouldNotCreateEntityInDatabase: {
            [UIAlertController showAlertInViewController:self withTitle:NSLocalizedString(@"couldnotcreateindb", nil) message:nil cancelButtonTitle:NSLocalizedString(@"no", nil) destructiveButtonTitle:nil otherButtonTitles:@[NSLocalizedString(@"yes", nil)] tapBlock:^(UIAlertController *controller, UIAlertAction *action, NSInteger buttonIndex) {
                if (UIAlertControllerBlocksCancelButtonIndex == buttonIndex) {
                    [self.navigationController popViewControllerAnimated:true];
                } else if (UIAlertControllerBlocksFirstOtherButtonIndex == buttonIndex) {
                    [[CreateDiningViewModel instance] saveEntity:self.name.text road:self.road.text roadNumber:self.roadNumber.text postalCode:self.postalCode.text city:self.city.text telephone:self.telephone.text website:self.website.text pork:self.porkSwitch.on alcohol:self.alcoholSwitch.on nonHalal:self.halalSwitch.on image:weakSelf.image onCompletion:^(CreateEntityResult result) {
                        [self showDialog:result];
                    }];
                }
            }];
            break;
        }
        case CreateEntityResultCouldNotUploadFile: {
            [UIAlertController showAlertInViewController:self withTitle:NSLocalizedString(@"couldnotuploadfile", nil) message:nil cancelButtonTitle:NSLocalizedString(@"no", nil) destructiveButtonTitle:nil otherButtonTitles:@[NSLocalizedString(@"yes", nil)] tapBlock:^(UIAlertController *controller, UIAlertAction *action, NSInteger buttonIndex) {
                if (UIAlertControllerBlocksCancelButtonIndex == buttonIndex) {
                    [self.navigationController popViewControllerAnimated:true];
                } else if (UIAlertControllerBlocksFirstOtherButtonIndex == buttonIndex) {
                    [[CreateDiningViewModel instance] savePicture:weakSelf.image onCompletion:^(CreateEntityResult result) {
                        [self showDialog:result];
                    }];
                }
            }];
            break;
        }
        case CreateEntityResultOk: {
            [UIAlertController showAlertInViewController:self withTitle:NSLocalizedString(@"ok", nil) message:nil cancelButtonTitle:NSLocalizedString(@"done", nil) destructiveButtonTitle:nil otherButtonTitles:@[NSLocalizedString(@"addReview", nil)] tapBlock:^(UIAlertController *controller, UIAlertAction *action, NSInteger buttonIndex) {
                if (UIAlertControllerBlocksCancelButtonIndex == buttonIndex) {
                    [self.navigationController popViewControllerAnimated:true];
                } else if (UIAlertControllerBlocksFirstOtherButtonIndex == buttonIndex) {
                    [self performSegueWithIdentifier:@"CreateReview" sender:self];
                }
            }];
            break;
        }
        case CreateEntityResultError: {
            //Not currently used
            break;
        }
    }
}

#pragma mark Saving

- (bool)areMandatoryFieldsFilledOut {

    bool complete = true;
    for (int i = 100; i < 105; i++) {
        UITextField *textField = (UITextField *) [self.scrollView viewWithTag:i];
        if ([textField.text length] == 0) {
            textField.layer.borderColor = [UIColor redColor].CGColor;
            textField.layer.borderWidth = 3;
            textField.layer.cornerRadius = 5;
            complete = false;
        } else {
            textField.layer.borderColor = [UIColor clearColor].CGColor;
            textField.layer.borderWidth = 0.5f;
            textField.layer.cornerRadius = 5;
        }

    }
    return complete;
}

#pragma mark - ImagePicker

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {

    __weak typeof(self) weakSelf = self;

    [self dismissViewControllerAnimated:true completion:^{
        weakSelf.image = [info valueForKey:UIImagePickerControllerOriginalImage];
        [self.pickImage setImage:weakSelf.image forState:UIControlStateNormal];
    }];

}


#pragma mark UIUpdates

- (void)setUILabels {
    int count = (int) [[CreateDiningViewModel instance].categories count];
    self.categoriesCount.text = [NSString stringWithFormat:@"%i", count];

}

#pragma mark - AutoComplete

- (NSString *)textField:(HTAutocompleteTextField *)textField completionForPrefix:(NSString *)prefix ignoreCase:(BOOL)ignoreCase {

    NSArray *suggestions;

    if (textField == self.road) {
        suggestions = [[CreateDiningViewModel instance] streetNameForPrefix:prefix];
    } else if (textField == self.roadNumber) {
        suggestions = [[CreateDiningViewModel instance] streetNumbersFor:self.road.text];
    }

    NSString *suggestion = [suggestions linq_firstOrNil];

    if (suggestion && [suggestion length] > [prefix length]) {
        return [suggestion substringFromIndex:[prefix length]];
    } else {
        return @"";
    }

}

#pragma mark - AutoComplete

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {

    if (textField == self.name) {
        [self.road becomeFirstResponder];
        return false;
    } else if (textField == self.road) {
        [self.roadNumber becomeFirstResponder];
        return false;
    } else if (textField == self.roadNumber) {
        [self.postalCode becomeFirstResponder];
        return false;
    } else if (textField == self.postalCode) {
        [self.city becomeFirstResponder];
        return false;
    } else if (textField == self.telephone) {
        [self.website becomeFirstResponder];
        return false;
    } else {
        return true;
    }
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    [super prepareForSegue:segue sender:sender];
    if ([segue.identifier isEqualToString:@"chooseCategories"]) {
        CategoriesViewController *destination = (CategoriesViewController *) segue.destinationViewController;
        destination.viewModel = [CreateDiningViewModel instance];

        MZFormSheetSegue *formSheetSegue = (MZFormSheetSegue *) segue;
        MZFormSheetController *formSheet = formSheetSegue.formSheetController;
        formSheet.presentedFormSheetSize = CGSizeMake(self.view.size.width * 0.8, self.view.size.height * 0.8);
        formSheet.transitionStyle = MZFormSheetTransitionStyleBounce;
        formSheet.cornerRadius = 8.0;
        formSheet.shouldDismissOnBackgroundViewTap = YES;
        formSheet.didDismissCompletionHandler = ^(UIViewController *presentedFSViewController) {
            [self setUILabels];
        };
    }
    else if ([segue.identifier isEqualToString:@"CreateReview"]) {
        [CreateReviewViewModel instance].reviewedLocation = [CreateDiningViewModel instance].createdLocation;
    }
}

- (void)dealloc {
    returnKeyHandler = nil;
}

@end
