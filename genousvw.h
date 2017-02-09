#import <objc/runtime.h>
#import "headers.h"

@interface GenousPrefView : UIView
@property (nonatomic,assign) UILabel *amount;
@property NSInteger type;
@property NSInteger amountInteger;
@property (nonatomic,assign)UIView *controller;
@property (nonatomic,assign)NSTimer *looper;
@property BOOL holdable;
@end

enum {
	GenousPrefViewTypeRow = 0,
	GenousPrefViewTypeCol = 1,
	GenousPrefViewTypeSize = 2
};

@interface GenousView : UIView
@property BOOL dock;
@property (nonatomic,assign) UIVisualEffectView *blurryView;
@property (nonatomic,assign) UIView *cropView;
@property (nonatomic,assign) UIScrollView *scrollView;
@property (nonatomic,assign) UIView *dimView;
@property (nonatomic,assign) UIImageView *genousImage;
@property (nonatomic,assign) UILabel *genousLabel;
@property (nonatomic,assign) UITapGestureRecognizer *dismissGesture;
@property (nonatomic,assign) UILabel *rowTitle;
@property (nonatomic,assign) UILabel *colTitle;
@property (nonatomic,assign) UILabel *insetTitle;
@property (nonatomic,assign) UIButton *resetButton;
@property (nonatomic,assign) UIButton *applyButton;
@property (nonatomic, assign) id listView;
@property (nonatomic,assign) GenousPrefView *colSettings;
@property (nonatomic,assign) GenousPrefView *rowSettings;
@property (nonatomic,assign) GenousPrefView *sizeSettings;
@property (nonatomic,assign) UILabel *sizeTitle;
@property (nonatomic,assign) UILabel *badgesTitle;
@property (nonatomic,assign) UILabel *labelsTitle;
@property (nonatomic,assign) NSMutableArray *lines;
- (void)resetListView:(UIButton *)sender;
- (GenousPrefView *)viewWithSomeButtonsAndAlabelFromView:(UILabel *)view;
- (id)initWithListView:(id)listView;
- (void)addSubviews;
- (void)addLineForView:(UIView *)view;
@end

