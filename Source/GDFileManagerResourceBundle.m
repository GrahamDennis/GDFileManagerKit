//
//  GDFileManagerResourceBundle.m
//  GDFileManagerExample
//
//  Created by Graham Dennis on 1/09/13.
//  Copyright (c) 2013 Graham Dennis. All rights reserved.
//

#import "GDFileManagerResourceBundle.h"

NSBundle *GDFileManagerResourcesBundle()
{
    static NSBundle *resourcesBundle;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSURL *resourcesBundleURL = [[NSBundle mainBundle] URLForResource:@"GDFileManagerKit" withExtension:@"bundle"];
        if (resourcesBundleURL) {
            resourcesBundle = [NSBundle bundleWithURL:resourcesBundleURL];
        } else {
            resourcesBundle = [NSBundle mainBundle];
        }
    });
    
    return resourcesBundle;
}