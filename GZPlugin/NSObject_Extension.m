//
//  NSObject_Extension.m
//  GZPlugin
//
//  Created by MoMing on 16/3/7.
//  Copyright © 2016年 GuZhe. All rights reserved.
//


#import "NSObject_Extension.h"
#import "GZPlugin.h"

@implementation NSObject (Xcode_Plugin_Template_Extension)

+ (void)pluginDidLoad:(NSBundle *)plugin
{
    static dispatch_once_t onceToken;
    NSString *currentApplicationName = [[NSBundle mainBundle] infoDictionary][@"CFBundleName"];
    if ([currentApplicationName isEqual:@"Xcode"]) {
        dispatch_once(&onceToken, ^{
            sharedPlugin = [[GZPlugin alloc] initWithBundle:plugin];
        });
    }
}
@end
