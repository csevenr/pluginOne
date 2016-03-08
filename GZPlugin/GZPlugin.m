//
//  GZPlugin.m
//  GZPlugin
//
//  Created by MoMing on 16/3/7.
//  Copyright © 2016年 GuZhe. All rights reserved.
//

#import "GZPlugin.h"
#import "SFDYCIXCodeHelper.h"
#import "SFDYCIClangProxyRecompiler.h"
#import "SFDYCIXcodeObjectiveCRecompiler.h"
#import "SFDYCIViewsHelper.h"
#import "SFDYCICompositeRecompiler.h"
#import "DYCI_CCPXCodeConsole.h"

@interface GZPlugin()
//
@property (nonatomic, strong, readwrite) NSBundle *bundle;
@property(nonatomic, strong) id <SFDYCIRecompilerProtocol> recompiler;
@property(nonatomic, strong) SFDYCIViewsHelper *viewHelper;
@property(nonatomic, strong) SFDYCIXCodeHelper *xcodeStructureManager;
@end

@implementation GZPlugin

+ (instancetype)sharedPlugin
{
    return sharedPlugin;
}

- (id)initWithBundle:(NSBundle *)plugin
{
    if (self = [super init]) {
        // reference to plugin's bundle, for resource access
        self.bundle = plugin;
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didApplicationFinishLaunchingNotification:)
                                                     name:NSApplicationDidFinishLaunchingNotification
                                                   object:nil];
    }
    return self;
}

- (void)didApplicationFinishLaunchingNotification:(NSNotification*)noti
{
    //removeObserver
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSApplicationDidFinishLaunchingNotification object:nil];
    
    NSLog(@"App finished launching");
    
    // Selecting Xcode Recompiler first
    // We'll use Xcode recompiler, and if that one fails, we'll fallback to dyci-recompile.py
    self.recompiler = [[SFDYCICompositeRecompiler alloc]
                       initWithCompilers:@[[SFDYCIXcodeObjectiveCRecompiler new], [SFDYCIClangProxyRecompiler new]]];
    
    self.viewHelper = [SFDYCIViewsHelper new];
    
    self.xcodeStructureManager = [SFDYCIXCodeHelper instance];
    
    [self setupMenu];
    
    
    
}
- (void)setupMenu {
    NSMenuItem *runMenuItem = [[NSApp mainMenu] itemWithTitle:@"Product"];
    if (runMenuItem) {
        
        NSMenu *subMenu = [runMenuItem submenu];
        
        // Adding separator
        [subMenu addItem:[NSMenuItem separatorItem]];
        
        // Adding inject item
        NSMenuItem *recompileAndInjectMenuItem = [[NSMenuItem alloc] initWithTitle:@"inject" action:@selector(recompileAndInject:) keyEquivalent:@"x"];
        [recompileAndInjectMenuItem setKeyEquivalentModifierMask:NSControlKeyMask];
        [recompileAndInjectMenuItem setTarget:self];
        
        [subMenu addItem:recompileAndInjectMenuItem];
        
        
    }
}

- (void)recompileAndInject:(id)sender {
    NSDocument<CDRSXcode_IDEEditorDocument> *currentDocument = (NSDocument<CDRSXcode_IDEEditorDocument> *)[self.xcodeStructureManager currentDocument];
    if ([currentDocument isDocumentEdited]) {
        [currentDocument saveDocumentWithDelegate:self didSaveSelector:@selector(document:didSave:contextInfo:) contextInfo:nil];
    } else {
        [self recompileAndInjectAfterSave:nil];
    }
    
}

- (void)document:(NSDocument *)document didSave:(BOOL)didSaveSuccessfully contextInfo:(void *)contextInfo {
    [self recompileAndInjectAfterSave:nil];
}


- (void)recompileAndInjectAfterSave:(id)sender {
    DYCI_CCPXCodeConsole * console = [DYCI_CCPXCodeConsole consoleForKeyWindow];
    [console log:@"Starting Injection"];
    __weak typeof(self) weakSelf = self;
    
    
    NSURL *openedFileURL = self.xcodeStructureManager.activeDocumentFileURL;
    
    if (openedFileURL) {
        
        [console log:[NSString stringWithFormat:@"Injecting %@(%@)", openedFileURL.lastPathComponent, openedFileURL]];
        
        [self.recompiler recompileFileAtURL:openedFileURL completion:^(NSError *error) {
            if (error) {
                [weakSelf.viewHelper showError:error];
                [console error:[NSString stringWithFormat:@"Recompilation failed %@", error]];
            } else {
                [weakSelf.viewHelper showSuccessResult];
                [console log:@"Recompilation was successful"];
            }
        }];
        
    } else {
        [console error:[NSString stringWithFormat:@"Cannot inject this file right now. If you think that this file is injectable, try again bit later"]];
    }
}

#pragma mark - Dealloc

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


@end
