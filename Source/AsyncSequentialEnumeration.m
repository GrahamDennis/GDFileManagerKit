//
//  AsyncSequentialEnumeration.m
//  GDFileManagerExample
//
//  Created by Graham Dennis on 29/01/13.
//  Copyright (c) 2013 Graham Dennis. All rights reserved.
//

#import "AsyncSequentialEnumeration.h"

typedef void(^ContinuationBlock)(BOOL);

void __attribute__((overloadable)) AsyncSequentialEnumeration(NSEnumerator *enumerator,
                                                              void (^iterationBlock)(id object, ContinuationBlock continuationBlock))
{
    return AsyncSequentialEnumeration(enumerator, iterationBlock, NULL);
}

void __attribute__((overloadable)) AsyncSequentialEnumeration(NSEnumerator *enumerator,
                                                              void (^iterationBlock)(id object, ContinuationBlock continuationBlock),
                                                              void (^completionBlock)(BOOL completed))
{
    return AsyncSequentialEnumeration(enumerator, NULL, iterationBlock, completionBlock);
}

void __attribute__((overloadable)) AsyncSequentialEnumeration(NSEnumerator *enumerator,
                                                              dispatch_queue_t queue,
                                                              void (^iterationBlock)(id object, ContinuationBlock continuationBlock),
                                                              void (^completionBlock)(BOOL completed))
{
    if (!queue) {
        queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    }
#if !OS_OBJECT_USE_OBJC
    dispatch_retain(queue);
#endif
    
    __weak __block ContinuationBlock weakContinuationBlock = nil;
    void (^continuationBlock)(BOOL) = ^(BOOL keepGoing){
        if (!keepGoing) {
            if (completionBlock) {
                dispatch_async(queue, ^{
                    completionBlock(NO);
                });
            }
#if !OS_OBJECT_USE_OBJC
            dispatch_release(queue);
#endif
            return;
        }
        id object = [enumerator nextObject];
        ContinuationBlock strongContinuationBlock = weakContinuationBlock;
        if (object && strongContinuationBlock) {
            dispatch_async(queue, ^{
                iterationBlock(object, strongContinuationBlock);
            });
        } else {
            if (completionBlock)
                completionBlock(YES);
#if !OS_OBJECT_USE_OBJC
            dispatch_release(queue);
#endif
        }
    };
    weakContinuationBlock = continuationBlock;
    
    continuationBlock(YES);
}

