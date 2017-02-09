#import "genousvw.h"
@implementation GenousView
- (id)initWithListView:(id)listView {
	self = [super init];
	if (self) {
		if ([listView isKindOfClass:[objc_getClass("SBDockIconListView") class]])self.dock = YES;
		self.backgroundColor = [UIColor clearColor];
		self.frame = [UIScreen mainScreen].bounds;
		_dimView = [[UIView alloc] init];
		_cropView = [[UIView alloc] init];
		_blurryView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleLight]];
		_genousLabel = [[UILabel alloc] init];
		_genousImage = [[UIImageView alloc] initWithImage:[UIImage imageWithContentsOfFile:@"/Library/Application Support/Genous/Genous_full.png"]];
		_dismissGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismiss)];
		_dismissGesture.numberOfTapsRequired = 1;
		_resetButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
		_colTitle = [[UILabel alloc] init];
		_insetTitle = [[UILabel alloc] init];
		_sizeTitle = [[UILabel alloc] init];
		_badgesTitle = [[UILabel alloc] init];
		_labelsTitle = [[UILabel alloc] init];
		_listView = listView;
		_lines = [[NSMutableArray alloc] init];
		_scrollView = [[UIScrollView alloc] init];
		if (!_dock) {
			_applyButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
			_rowTitle = [[UILabel alloc] init];
		}
		
		

		CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), (__bridge const void *)(self), wrapper, CFSTR("com.broganminer.genous.dismissController"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
		CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), (__bridge const void *)(self), wrapper2, CFSTR("com.broganminer.genous.rotatewillhappen"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
	}
	return self;
}
void wrapper(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
	NSLog(@"GENOUS notification told to dismiss pref pane");
	CFNotificationCenterRemoveEveryObserver(CFNotificationCenterGetDarwinNotifyCenter(), (__bridge const void *)(observer));
	[(GenousView *)observer dismiss];
}
void wrapper2(CFNotificationCenterRef center, void *observer2, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
	NSLog(@"GENOUS notification told to rotate view");
	GenousView *observer = (GenousView *)observer2;
	observer.frame = [UIScreen mainScreen].bounds;
	CGRect portraitFrame = CGRectMake(observer.frame.size.width/14,observer.frame.size.height/6,6*observer.frame.size.width/7,5*observer.frame.size.height/9);
	CGRect landscapeFrame = CGRectMake(observer.frame.size.width/6,observer.frame.size.height/10,5*observer.frame.size.width/9,8*observer.frame.size.height/10);
	NSInteger orientation = [(SpringBoard *)[UIApplication sharedApplication] interfaceOrientationForCurrentDeviceOrientation];
	if (orientation == 1 || orientation == 2) {
		observer.cropView.frame = portraitFrame;
	}
	else {
		observer.cropView.frame = landscapeFrame;
	}
	[observer addSubviews];
}
- (void)layoutSubviews {
	[super layoutSubviews];
	CGRect portraitFrame = CGRectMake(self.frame.size.width/14,self.frame.size.height/6,6*self.frame.size.width/7,5*self.frame.size.height/9);
	CGRect landscapeFrame = CGRectMake(self.frame.size.width/6,self.frame.size.height/10,5*self.frame.size.width/9,8*self.frame.size.height/10);
	NSInteger orientation = [(SpringBoard *)[UIApplication sharedApplication] interfaceOrientationForCurrentDeviceOrientation];
	_dimView.frame = self.frame;
	[_dimView addGestureRecognizer:_dismissGesture];
	if (orientation == 1 || orientation == 2) {
		_cropView.frame = portraitFrame;
	}
	else {
		_cropView.frame = landscapeFrame;
	}
	_cropView.layer.masksToBounds = YES;
	_cropView.layer.cornerRadius = 20.0f;
	_blurryView.frame = self.frame;
	[_cropView addSubview:_blurryView];
	[self addSubviews];
	
}
- (void)addSubviews {
	

	[_rowSettings.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
	[_colSettings.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
	[_sizeSettings.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
	[_insetTitle.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
	[_labelsTitle.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
	[_badgesTitle.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
	NSArray *linesCopy = [_lines copy];
	for (UIView *view in linesCopy) {
		[view removeFromSuperview];
		[_lines removeObject:view];
	}
	[linesCopy release];
	_genousImage.frame = CGRectMake(20,15,_cropView.frame.size.width/6,_cropView.frame.size.height/6);
	_genousLabel.frame = CGRectMake(_cropView.frame.size.width-20-3*_cropView.frame.size.width/4,15,3*_cropView.frame.size.width/4,_cropView.frame.size.height/6);
	_genousImage.contentMode = UIViewContentModeScaleAspectFit;
	_genousLabel.text = @"Genous";
	_genousLabel.numberOfLines = 1;
	_genousLabel.minimumScaleFactor = 0.4;
	_genousLabel.adjustsFontSizeToFitWidth = YES;
	_genousLabel.font = [_genousLabel.font fontWithSize:32.0]; 
	_genousLabel.textAlignment = NSTextAlignmentCenter;
	[_cropView addSubview:_genousLabel];
	[_cropView addSubview:_genousImage];
	[self addSubview:_dimView];
	_dimView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.2f];
	[self addSubview:_cropView];

	_rowTitle.text = @"Rows";
	_colTitle.text = @"Columns";
	_sizeTitle.text = @"Icon Size";
	_insetTitle.text = @"Edit Size";
	_labelsTitle.text = @"Labels";
	_badgesTitle.text = @"Resize Badges";

	[_resetButton setTitle:@"Reset" forState:UIControlStateNormal];
	[_resetButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
	[_resetButton setTitleColor:[UIColor colorWithRed:(1.0)*0.5 green:(0.0)*0.5 blue:(0.0)*0.5 alpha:1.0] forState:UIControlStateHighlighted];
	[_resetButton addTarget:self action:@selector(resetListView:) forControlEvents:UIControlEventTouchUpInside];
	_resetButton.titleLabel.textAlignment = NSTextAlignmentCenter;
	[_resetButton.titleLabel sizeToFit];

	[_applyButton setTitle:@"Apply to..." forState:UIControlStateNormal];
	[_applyButton addTarget:self action:@selector(applyToAll:) forControlEvents:UIControlEventTouchUpInside];
	[_applyButton setTitleColor:[UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:1.0] forState:UIControlStateNormal];
	[_applyButton setTitleColor:[UIColor colorWithRed:(0.0)*0.5 green:(122.0/255.0)*0.5 blue:(1.0)*0.5 alpha:1.0] forState:UIControlStateHighlighted];
	_applyButton.titleLabel.numberOfLines = 1;
	_applyButton.titleLabel.textAlignment = NSTextAlignmentCenter;
	[_applyButton.titleLabel sizeToFit];

	CGFloat inset = 15.0;
	CGFloat startingYOrigin = _genousLabel.frame.origin.y+_genousLabel.frame.size.height;
	CGFloat width = _cropView.frame.size.width - (2*inset);
	CGFloat height = (_cropView.frame.size.height - (startingYOrigin+(1.5*inset)))/5;

	_scrollView.frame = CGRectMake(inset,startingYOrigin,width,4*height);
	_scrollView.contentSize = CGSizeMake(width,6*height);
	[_cropView addSubview:_scrollView];

	_rowTitle.frame = CGRectMake(0,height,width,height);
	_colTitle.frame = CGRectMake(0,0,width,height);
	
	if (_dock) {
		_scrollView.contentSize = CGSizeMake(width,5*height);
		_insetTitle.frame = CGRectMake(0,(2*height),width,height);
		_sizeTitle.frame = CGRectMake(0,(1*height),width,height);
		_badgesTitle.frame = CGRectMake(0,3*height,width,height);
		_labelsTitle.frame = CGRectMake(0,4*height,width,height);
		_resetButton.frame = CGRectMake(inset,startingYOrigin+(4*height)+inset,width-inset,height-inset);
	}
	else {
		_applyButton.frame = CGRectMake(inset+width/2,startingYOrigin+(4*height)+inset,width/2,height-inset);
		_insetTitle.frame = CGRectMake(0,(3*height),width,height);
		_sizeTitle.frame = CGRectMake(0,(2*height),width,height);
		_badgesTitle.frame = CGRectMake(0,4*height,width,height);
		_labelsTitle.frame = CGRectMake(0,5*height,width,height);
		_resetButton.frame = CGRectMake(inset,startingYOrigin+(4*height)+inset,width/2,height-inset);
		UIView *line = [[UIView alloc] initWithFrame:CGRectMake(inset+width/2,startingYOrigin+(4*height)+inset/2,1,height-inset/2)];
		line.backgroundColor = [UIColor darkGrayColor];
		line.alpha = 0.7;
		[_cropView addSubview:line];
		[_lines addObject:line];
		[line release];
	}
	

	
	UIView *line2 = [[UIView alloc] initWithFrame:CGRectMake(inset,startingYOrigin+(4*height),width,1)];
	line2.backgroundColor = [UIColor darkGrayColor];
	line2.alpha = 0.7;
	[_cropView addSubview:line2];
	[_lines addObject:line2];
	[line2 release];

	[_scrollView addSubview:_rowTitle];
	[self addLineForView:_rowTitle];
	[_scrollView addSubview:_colTitle];
	[self addLineForView:_colTitle];
	[_scrollView addSubview:_insetTitle];
	[self addLineForView:_insetTitle];
	[_scrollView addSubview:_sizeTitle];
	[self addLineForView:_sizeTitle];
	[_scrollView addSubview:_labelsTitle];
	[self addLineForView:_labelsTitle];
	[_scrollView addSubview:_badgesTitle];
	[self addLineForView:_badgesTitle];

	_rowTitle.userInteractionEnabled = YES;
	_colTitle.userInteractionEnabled = YES;
	_insetTitle.userInteractionEnabled = YES;
	_sizeTitle.userInteractionEnabled = YES;
	_labelsTitle.userInteractionEnabled = YES;
	_badgesTitle.userInteractionEnabled = YES;

	[_cropView addSubview:_resetButton];
	[_cropView addSubview:_applyButton];

	_rowSettings = [self viewWithSomeButtonsAndAlabelFromView:_rowTitle];
	_rowSettings.type = GenousPrefViewTypeRow;
	_rowSettings.amountInteger = [self.listView iconRowsForCurrentOrientation];
	_rowSettings.amount.text = [[NSNumber numberWithInteger:_rowSettings.amountInteger] stringValue];
	[_rowTitle addSubview:_rowSettings];


	_colSettings = [self viewWithSomeButtonsAndAlabelFromView:_colTitle];
	_colSettings.type = GenousPrefViewTypeCol;
	_colSettings.amountInteger = [self.listView iconColumnsForCurrentOrientation];
	_colSettings.amount.text = [[NSNumber numberWithInteger:_colSettings.amountInteger] stringValue];
	[_colTitle addSubview:_colSettings];

	_sizeSettings = [self viewWithSomeButtonsAndAlabelFromView:_sizeTitle];
	_sizeSettings.type = GenousPrefViewTypeSize;
	_sizeSettings.amountInteger = [self.listView iconSizePercentage] * 100;
	_sizeSettings.amount.text = [[NSNumber numberWithInteger:_sizeSettings.amountInteger] stringValue];
	[_sizeTitle addSubview:_sizeSettings];


	UISwitch *insetSwitch = [[UISwitch alloc] init];
	insetSwitch.frame = CGRectMake((2*_insetTitle.frame.size.width/3),_insetTitle.frame.size.height/2-insetSwitch.frame.size.height/2,insetSwitch.frame.size.width,insetSwitch.frame.size.height);
	if ([self.listView editSizeOn]) {
		insetSwitch.on = YES;
	}
	[insetSwitch addTarget:self action:@selector(switchTouched:) forControlEvents:UIControlEventTouchUpInside];
	[_insetTitle addSubview:insetSwitch];
	insetSwitch.onTintColor = [UIColor darkGrayColor];
	insetSwitch.tintColor = [UIColor darkGrayColor];
	[insetSwitch release];

	UISwitch *badgeSwitch = [[UISwitch alloc] init];
	badgeSwitch.frame = CGRectMake(2*_badgesTitle.frame.size.width/3,_badgesTitle.frame.size.height/2-badgeSwitch.frame.size.height/2,badgeSwitch.frame.size.width,badgeSwitch.frame.size.height);
	if ([self.listView genousResizeBadges]) {
		badgeSwitch.on = YES;
	}
	[badgeSwitch addTarget:self action:@selector(altSwitchTouched:) forControlEvents:UIControlEventTouchUpInside];
	badgeSwitch.onTintColor = [UIColor darkGrayColor];
	badgeSwitch.tintColor = [UIColor darkGrayColor];
	[_badgesTitle addSubview:badgeSwitch];
	[badgeSwitch release];

	UISegmentedControl *labelControl = [[UISegmentedControl alloc] initWithItems:@[@"Default",@"Resize",@"None"]];
	[labelControl addTarget:self action:@selector(segmentChanged:) forControlEvents:UIControlEventValueChanged];
	labelControl.selectedSegmentIndex = [self.listView genousLabelDisplay];
	labelControl.tintColor = [UIColor darkGrayColor];
	labelControl.frame = CGRectMake(2*width/3-labelControl.frame.size.width/2,height/2-labelControl.frame.size.height/2,labelControl.frame.size.width*0.95,labelControl.frame.size.height);
	[_labelsTitle addSubview:labelControl];
	[labelControl release];
}
- (void)segmentChanged:(UISegmentedControl *)segment {
	[self.listView changeLabelDisplay:segment.selectedSegmentIndex];
}
- (void)addLineForView:(UIView *)view {
	if (view == nil)return;
	UIView *line = [[UIView alloc] initWithFrame:CGRectMake(view.frame.origin.x,view.frame.size.height+view.frame.origin.y,view.frame.size.width,1)];
	line.backgroundColor = [UIColor darkGrayColor];
	line.alpha = 0.7;
	[_scrollView addSubview:line];
	[_lines addObject:line];
	[line release];
}
- (void)switchTouched:(UISwitch *)switchT {
	if (switchT.on) {
		[self.listView addSizingViews];
	}
	else {
		[self.listView removeSizingViews];
	}
}
- (void)altSwitchTouched:(UISwitch *)switchT {
	if (switchT.on) {
		[self.listView changeResizeBadges:YES];
	}
	else {
		[self.listView changeResizeBadges:NO];
	}
}
- (GenousPrefView *)viewWithSomeButtonsAndAlabelFromView:(UILabel *)view {
	if (view == nil) return nil;
	CGFloat inset = 5.0;
	GenousPrefView *main = [[GenousPrefView alloc] initWithFrame:CGRectMake(view.frame.size.width/2+inset,0,view.frame.size.width/2 - (2*inset),view.frame.size.height)];
	if ([view.text isEqual:@"Icon Size"]) {
		main.holdable = YES;
	}
	UIButton *plusButton = [UIButton buttonWithType:UIButtonTypeCustom];
	[plusButton setTitle:@"+" forState:UIControlStateNormal];
	[plusButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
	plusButton.backgroundColor = [UIColor darkGrayColor];

	[plusButton sizeToFit];
	[plusButton addTarget:main action:@selector(buttonDownPlus) forControlEvents:UIControlEventTouchDown];
	[plusButton addTarget:main action:@selector(buttonUp) forControlEvents:UIControlEventTouchUpInside];
	[plusButton addTarget:main action:@selector(buttonUp) forControlEvents:UIControlEventTouchUpOutside];

	UIButton *minusButton = [UIButton buttonWithType:UIButtonTypeCustom];
	[minusButton setTitle:@"-" forState:UIControlStateNormal];
	[minusButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
	minusButton.backgroundColor = [UIColor darkGrayColor];
	[minusButton sizeToFit];
	[minusButton addTarget:main action:@selector(buttonDownMinus) forControlEvents:UIControlEventTouchDown];
	[minusButton addTarget:main action:@selector(buttonUp) forControlEvents:UIControlEventTouchUpInside];
	[minusButton addTarget:main action:@selector(buttonUp) forControlEvents:UIControlEventTouchUpOutside];

	main.amount = [[UILabel alloc] initWithFrame:CGRectMake(main.frame.size.width/3,0,main.frame.size.width/3,main.frame.size.height)];
	main.amount.text = [[NSNumber numberWithInteger:main.amountInteger] stringValue];
	main.amount.textColor = [UIColor blackColor];
	main.amount.textAlignment = NSTextAlignmentCenter;
	main.amount.font = [main.amount.font fontWithSize:20];

	minusButton.frame = CGRectMake(0+(main.frame.size.width/6-main.frame.size.height/4),(main.frame.size.height/2)-(main.frame.size.height/4),main.frame.size.height/2,main.frame.size.height/2);
	plusButton.frame = CGRectMake(2*main.frame.size.width/3+(main.frame.size.width/6-main.frame.size.height/4),(main.frame.size.height/2)-(main.frame.size.height/4),main.frame.size.height/2,main.frame.size.height/2);
	plusButton.layer.cornerRadius = plusButton.frame.size.width/2;
	minusButton.layer.cornerRadius = minusButton.frame.size.width/2;
	[main addSubview:minusButton];
	[main addSubview:plusButton];
	[main addSubview:main.amount];

	main.controller = self;

	return main;
}
- (void)dismiss {
	CFNotificationCenterRemoveEveryObserver(CFNotificationCenterGetDarwinNotifyCenter(), (__bridge const void *)(self));
	self.alpha = 1.0;
	[UIView animateWithDuration:0.4 delay:0.0 options:UIViewAnimationCurveEaseOut 
			animations:^{
				self.alpha = 0;
			}
			completion:^(BOOL finnished){
				[self removeFromSuperview];
			}];
}
- (void)resetListView:(UIButton *)sender  {
	[self.listView genousReset];
	_colSettings.amountInteger = [self.listView iconColumnsForCurrentOrientation];
	_colSettings.amount.text = [[NSNumber numberWithInteger:_colSettings.amountInteger] stringValue];
	_rowSettings.amountInteger = [self.listView iconRowsForCurrentOrientation];
	_rowSettings.amount.text = [[NSNumber numberWithInteger:_rowSettings.amountInteger] stringValue];
	_sizeSettings.amountInteger = 100;
	_sizeSettings.amount.text = [[NSNumber numberWithInteger:100] stringValue];
}

/*
Note this causes a crash on iOS 10
*/
- (void)applyToAll:(UIButton *)sender {
	GenousAddToAlert *alert = [[objc_getClass("GenousAddToAlert") alloc] init]; 
  	[[alert class] activateAlertItem:alert]; 
}
- (void)dealloc {
	[_labelsTitle release];
	[_badgesTitle release];
	[_lines release];
	[_applyButton release];
	[_resetButton release];
	[_blurryView release];
	[_cropView release];
	[_dimView release];
	[_genousImage release];
	[_genousLabel release];
	[_dismissGesture release];
	[_rowTitle release];
	[_colTitle release];
	[_insetTitle release];
	[_colSettings release];
	[_rowSettings release];
	[_sizeSettings release];
	[_sizeTitle release];
	[super dealloc];
}
@end

@implementation GenousPrefView
- (void)buttonDownPlus {
	if (self.holdable) {
		_looper = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(plusClicked) userInfo:nil repeats:YES];
	}
	else {
		[self plusClicked];
	}
}
- (void)buttonDownMinus {
	if (self.holdable) {
		_looper = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(minusClicked) userInfo:nil repeats:YES];
	}
	else {
		[self minusClicked];
	}
}
- (void)buttonUp {
	[_looper invalidate];
}
- (void)plusClicked {
	if (_amountInteger < 20 && _type <= GenousPrefViewTypeCol) {
		_amountInteger++;
		_amount.text = [[NSNumber numberWithInteger:_amountInteger] stringValue];
		if (_type == GenousPrefViewTypeRow) {
			[(SBRootIconListView *)((GenousView *)self.controller).listView rowsChangedTo:_amountInteger];
		}
		else {
			[(SBRootIconListView *)((GenousView *)self.controller).listView colsChangedTo:_amountInteger];
		}
	}
	else if (_amountInteger < 180 && _type == GenousPrefViewTypeSize) {
		_amountInteger++;
		_amount.text = [[NSNumber numberWithInteger:_amountInteger] stringValue];
		[(SBRootIconListView *)((GenousView *)self.controller).listView iconSizedChangedTo:((float)_amountInteger/100.0f)];
	}
}
- (void)minusClicked {
	if (_amountInteger > 1 && _type <= GenousPrefViewTypeCol) {
		_amountInteger--;
		_amount.text = [[NSNumber numberWithInteger:_amountInteger] stringValue];
		if (_type == GenousPrefViewTypeRow) {
			[(SBRootIconListView *)((GenousView *)self.controller).listView rowsChangedTo:_amountInteger];
		}
		else {
			[(SBRootIconListView *)((GenousView *)self.controller).listView colsChangedTo:_amountInteger];
		}
	}
	else if (_amountInteger > 35 && _type == GenousPrefViewTypeSize) {
		_amountInteger--;
		_amount.text = [[NSNumber numberWithInteger:_amountInteger] stringValue];
		[(SBRootIconListView *)((GenousView *)self.controller).listView iconSizedChangedTo:((float)_amountInteger/100.0f)];
	}
}
- (void)dealloc {
	[_amount release];

	[super dealloc];
}
@end