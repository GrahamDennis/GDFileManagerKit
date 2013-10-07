//
//  GDFormLoginViewController.h
//  GDFileManagerExample
//
//  Created by Graham Dennis on 19/02/13.
//  Copyright (c) 2013 Graham Dennis. All rights reserved.
//

#import <QuickDialog/QuickDialog.h>

@interface GDLoginFormViewController : QuickDialogController

@property (nonatomic, strong) void (^buttonTapHandler)(NSDictionary *result);
@property (nonatomic, strong) dispatch_block_t cancelHandler;
@property (nonatomic, getter = isLoading) BOOL loading;

@end
