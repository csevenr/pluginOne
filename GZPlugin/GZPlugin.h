//
//  GZPlugin.h
//  GZPlugin
//
//  Created by MoMing on 16/3/7.
//  Copyright © 2016年 GuZhe. All rights reserved.
//

#import <AppKit/AppKit.h>

@class GZPlugin;

static GZPlugin *sharedPlugin;

@interface GZPlugin : NSObject

+ (instancetype)sharedPlugin;
- (id)initWithBundle:(NSBundle *)plugin;

@property (nonatomic, strong, readonly) NSBundle* bundle;
@end