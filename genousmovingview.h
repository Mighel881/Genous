@interface GenousMovingView : UIView
@property BOOL wide;
@property (nonatomic, assign) UIPanGestureRecognizer *gesture;
@property (nonatomic, assign) UIView *fakeListView;
@property NSInteger type;
@property (nonatomic,assign) UIImageView *arrow;
@property (nonatomic,assign) UIVisualEffectView *blur;
- (void)panned:(UIPanGestureRecognizer *)gesture;
- (void)moveIconsInSuperviewWithAmount:(CGFloat)amount;
- (void)fixArrow;
@end
