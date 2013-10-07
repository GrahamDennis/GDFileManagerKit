//
//  GDDropboxAccountInfo.h
//  GDFileManagerExample
//
//  Created by Graham Dennis on 23/01/13.
//  Copyright (c) 2013 Graham Dennis. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "GDDictionaryBackedObject.h"

@interface GDDropboxAccountInfo : GDDictionaryBackedObject

@property (nonatomic, readonly, copy) NSString *userID;

@end
