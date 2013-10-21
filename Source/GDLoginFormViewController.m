//
//  GDFormLoginViewController.m
//  GDFileManagerExample
//
//  Created by Graham Dennis on 19/02/13.
//  Copyright (c) 2013 Graham Dennis. All rights reserved.
//

#import "GDLoginFormViewController.h"
#import <QuickDialog/QuickDialogController+Loading.h>

@interface GDLoginFormViewController () <QuickDialogStyleProvider>

- (IBAction)cancelTapped:(id)sender;

@end

@implementation GDLoginFormViewController

- (id)initWithRoot:(QRootElement *)rootElement
{
    rootElement.appearance.valueAlignment = NSTextAlignmentLeft;
    return [super initWithRoot:rootElement];
}

#pragma mark - Styling

- (void)setQuickDialogTableView:(QuickDialogTableView *)aQuickDialogTableView
{
    [super setQuickDialogTableView:aQuickDialogTableView];
    
//    self.quickDialogTableView.backgroundView = nil;
//    self.quickDialogTableView.backgroundColor = [UIColor whiteColor];
    self.quickDialogTableView.bounces = YES;
    self.quickDialogTableView.styleProvider = self;
    self.resizeWhenKeyboardPresented = NO;

    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelTapped:)];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
//    self.navigationController.navigationBar.tintColor = [UIColor colorWithRed:21./255 green:116./255 blue:60./255 alpha:1.0];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // Make the first editable field the first responder
    for (QSection *section in self.root.sections) {
        for (QElement *element in section.elements) {
            if ([element isKindOfClass:[QEntryElement class]]) {
                QEntryTableViewCell *cell = (QEntryTableViewCell *)[self.quickDialogTableView cellForElement:element];
                [cell.textField becomeFirstResponder];
                goto loopEnd;
            }
        }
    }
loopEnd:;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
//    self.navigationController.navigationBar.tintColor = nil;
}

-(void) cell:(UITableViewCell *)cell willAppearForElement:(QElement *)element atIndexPath:(NSIndexPath *)indexPath{
//    cell.backgroundColor = [UIColor colorWithRed:0.9582 green:0.9104 blue:0.7991 alpha:1.0000];
//    
//    if ([element isKindOfClass:[QEntryElement class]] || [element isKindOfClass:[QButtonElement class]]){
//        cell.textLabel.textColor = [UIColor colorWithRed:0.6033 green:0.2323 blue:0.0000 alpha:1.0000];
//    }
}

#pragma mark - Action methods

- (void)buttonTapped:(QButtonElement *)buttonElement {
    [[self view] endEditing:YES];
    NSMutableDictionary *result = [NSMutableDictionary new];

    [self.root fetchValueUsingBindingsIntoObject:result];
    
    if (self.buttonTapHandler) {
        self.buttonTapHandler(result);
    }
}

- (void)cancelTapped:(id)sender
{
    [[self view] endEditing:YES];
    
    if (self.cancelHandler) {
        self.cancelHandler();
    }
    
}

- (void)setLoading:(BOOL)loading
{
    if (loading == _loading) return;
    _loading = loading;
    [self loading:loading];
}

@end
