#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#import <inspectivec.h>
#import "genousmovingview.h"
#import <CommonCrypto/CommonDigest.h>
#import <dlfcn.h>
#import <mach/port.h>
#import <mach/kern_return.h>
#include <IOKit/IOKitLib.h>
#include <CoreFoundation/CoreFoundation.h>

//#define GNLog NSLog
#define GNLog(...)

@interface SBFolder : NSObject
- (NSArray *)allIcons;
- (id)addIcon:(id)arg1;
@end
@interface SBRootFolderView : UIView
@property(readonly, copy, nonatomic) NSArray *iconListViews;
@property(readonly, nonatomic, getter=isEditing) BOOL editing;
@end
@interface SBRootFolderController : NSObject
@property(readonly, copy, nonatomic) NSArray *iconListViews;
@property(retain, nonatomic) SBFolder *folder;
- (id)currentIconListView;
@end
@interface SBIcon : NSObject
- (id)leafIdentifier;
- (SBFolder *)folder;
@end
@interface SBIconModel : NSObject
- (NSDictionary *)iconState;
@end
@interface SBIconController : UIViewController
+ (SBIconController *)sharedInstance;
- (SBRootFolderController *)_rootFolderController;
- (SBIconModel *)model;
- (void)noteIconStateChangedExternally;
@end
@interface SBIconImageView : UIView
@end
@interface SBIconListModel : NSObject
- (NSUInteger)firstFreeSlotIndexForType:(int)arg1;
- (id)folder;
- (id)listView;
- (NSUInteger)numberOfIcons;
- (void)removeIcon:(id)arg1;
@end


@interface SBIconListView : UIView {
	SBIconListModel *_model;
}
@property NSUInteger rowsASO;
@property NSUInteger columnsASO;
@property (retain) NSValue *insetsASO;
@property CGFloat iconSizeASO;
@property NSUInteger labelDisplayASO;
@property NSUInteger badgesASO;
+ (void)applyGenousSettingsToAllRootListsFromList:(SBIconListView *)list orientation:(NSInteger)orientation;
+ (NSUInteger)maxIconsForDock;
- (id)model;
- (void)applySettingsToOppositeOrientation;
- (NSUInteger)iconColumnsForCurrentOrientation;
- (NSUInteger)iconRowsForCurrentOrientation;
- (id)icons;
- (void)doubleTappedList;
- (CGFloat)sideIconInset;
- (CGFloat)topIconInset;
- (CGFloat)bottomIconInset;
- (NSUInteger)indexOfListInRootFolder;
+ (NSUInteger)maxIconsForIndex:(NSInteger)index;
+ (NSUInteger)maxIcons;
- (CGSize)defaultIconSize;
- (void)layoutIconsNow;
- (void)removeIconsFromModelForMaxIconCountChangeAndThenReAddThemToTheRootFolder;
- (void)genousValuesChanged;
- (BOOL)isEditing;
- (CGFloat)rightInset;
- (void)setInsetFromPoint:(CGPoint)point ofType:(NSInteger)type;
- (void)colsChangedTo:(NSInteger)cols;
- (void)rowsChangedTo:(NSInteger)rows;
@property(nonatomic) NSInteger orientation;
@property(nonatomic, getter=isEditing) BOOL editing;
- (BOOL)editSizeOn;
- (void)addSizingViews;
- (void)removeSizingViews;
- (void)genousReset;
- (CGFloat)iconSizePercentage;
- (void)addValuesForOrientation:(NSInteger)orientation;
- (void)iconSizedChangedTo:(CGFloat)size;
- (id)viewForIcon:(id)arg1;
- (NSInteger)genousLabelDisplay;
- (BOOL)genousResizeBadges;
- (void)changeLabelDisplay:(NSInteger)display;
- (void)changeResizeBadges:(BOOL)display;
- (void)writeValue:(id)value forSetting:(NSString *)setting;
@end
@interface SBRootIconListView : SBIconListView
@end
@interface SBDockIconListView : SBRootIconListView
@end
@interface NSUserDefaults (genous) {
}
- (id)objectForKey:(id)key inDomain:(id)d;
- (void)setObject:(id)r forKey:(id)key inDomain:(id)d;
@end
@interface SBIconStateArchiver : NSObject
+ (id)_representationForList:(id)arg1;
@end
@interface ISIconSupport : NSObject
+ (id)sharedInstance;
- (void)repairAndReloadIconState;
- (void)addExtension:(NSString *)ext;
@end
@interface SpringBoard : UIApplication
- (UIView *)statusBar;
- (NSInteger)interfaceOrientationForCurrentDeviceOrientation;
@end
@interface SBIconView : UIView
@property (assign) BOOL resizeBadgeBool;
@property (assign) NSUInteger labelSizingOption;
@property (assign) CGFloat iconResizingFloat;
- (UIImageView *)_iconImageView;
- (UIImageView *)iconBackgroundView;
- (UIImageView *)_folderIconImageView;
- (CGSize)genousSize;
- (UIView *)labelView;
- (CGFloat)_labelVerticalOffset;
+ (CGSize)defaultIconImageSize;
- (void)_updateAccessoryViewWithAnimation:(BOOL)arg1;
- (void)_updateCloseBoxAnimated:(BOOL)arg1;
- (void)genousResizeIconView;
- (BOOL)isInDock;

@end
@interface SBFolderIconImageView : UIView
@end
@interface SBUIController : NSObject
+ (id)sharedInstance;
- (id)window;
@end
@interface SBAlertItem : NSObject <UIAlertViewDelegate>
+ (void)activateAlertItem:(id)arg1;
- (id)alertSheet;
@end
@interface UIAlertView (GN)
- (id)_addButtonWithTitleText:(id)arg1;
@end
@interface GenousAddToAlert : SBAlertItem
@property(nonatomic,assign)SBRootIconListView *listView;
@end
@interface STKGroupView : UIView
@end
@interface IWWidgetsView : UIView
@end

typedef struct SBIconCoordinate {
    NSInteger row;
    NSInteger col;
} SBIconCoordinate;

enum {
	GenousLabelDisplayNormal = 0,
	GenousLabelDisplayResize = 1,
	GenousLabelDisplayNone = 2
};

static CGSize buttonSize = CGSizeMake(100,50);
