//
//  AsyncSequentialEnumeration.h
//  GDFileManagerExample
//
//  Created by Graham Dennis on 29/01/13.
//  Copyright (c) 2013 Graham Dennis. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^AsyncSequentialEnumerationContinuationBlock)(BOOL keepGoing);

void __attribute__((overloadable)) AsyncSequentialEnumeration(NSEnumerator *enumerator,
                                                              void (^iterationBlock)(id object, AsyncSequentialEnumerationContinuationBlock continuationBlock));

void __attribute__((overloadable)) AsyncSequentialEnumeration(NSEnumerator *enumerator,
                                                              void (^iterationBlock)(id object, AsyncSequentialEnumerationContinuationBlock continuationBlock),
                                                              void (^completionBlock)(BOOL completed));

void __attribute__((overloadable)) AsyncSequentialEnumeration(NSEnumerator *enumerator,
                                dispatch_queue_t queue,
                                void (^iterationBlock)(id object, AsyncSequentialEnumerationContinuationBlock continuationBlock),
                                void (^completionBlock)(BOOL completed));
