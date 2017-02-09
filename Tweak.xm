#import "headers.h"
#import "genousvw.h"

#define SYSTEM_VERSION_LESS_THAN(v) ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)


//create memory addresses keys for associated objects
static char rowsASO;
static char columnsASO;
static char rightInsetASO;
static char leftInsetASO;
static char bottomInsetASO;
static char topInsetASO;
static char iconSizeASO;
static char labelDisplayASO;
static char badgesASO;

static BOOL isHarborInstalled;




//Dock specific hooks just to layout the dock (most of theses are generally the same to the normal list views, just slight changes/reduced functionality)
%group genousdock
%hook SBDockIconListView
%new
- (void)addValuesForOrientation:(NSInteger)orientation {
	GNLog(@"GENOUS adding values for an orientation");
	NSInteger key;
	char *b[6] = {&columnsASO,&rightInsetASO,&leftInsetASO,&iconSizeASO,&labelDisplayASO,&badgesASO};
	NSString *values[6] = {@"columns",@"rightSideInset",@"leftSideInset",@"sizes",@"labels",@"badges"};
	if (orientation == 1 || orientation == 2) {
		key = 0;
	}
	else {
		key = 1;
	}
	for (int i = 0; i < 6; i++) {
		char *pointer = b[i];
		
		NSNumber *newV = nil;
		NSArray *valueArray = [[[NSUserDefaults standardUserDefaults] objectForKey:@"dock" inDomain:@"com.broganminer.genous"] objectForKey:values[i]];
		if ([valueArray count] > 0)
		newV = [[[[NSUserDefaults standardUserDefaults] objectForKey:@"dock" inDomain:@"com.broganminer.genous"] objectForKey:values[i]] objectAtIndex:key];
		objc_setAssociatedObject(self,pointer,newV,OBJC_ASSOCIATION_RETAIN);
	}
}
%new
- (void)writeValue:(id)value forSetting:(NSString *)setting {
	NSMutableDictionary *oldDefaults = [[[NSUserDefaults standardUserDefaults] objectForKey:@"dock" inDomain:@"com.broganminer.genous"] mutableCopy];
	if(oldDefaults == nil)oldDefaults = [[NSMutableDictionary alloc] init];
	if ([setting isEqual:@"pages"]) {
		NSArray *oldThing = [oldDefaults objectForKey:@"columns"];
		NSArray *changing;
		if ([oldThing isKindOfClass:[NSArray class]] && [oldThing count] == 2) {
			if (self.orientation == 1 || self.orientation == 2) {
				changing = @[[value firstObject],[oldThing lastObject]];
			}
			else {
				changing = @[[oldThing firstObject],[value firstObject]];
			}
		}
		else {
			changing = @[[value firstObject],[value firstObject]];
		}
		[oldDefaults setObject:changing forKey:@"columns"];
	}
	else {
		NSArray *oldvalue = [oldDefaults objectForKey:setting];
		if ([oldvalue isKindOfClass:[NSArray class]] && [oldvalue count] == 2) {
			if (self.orientation == 1 || self.orientation == 2) {
				[oldDefaults setObject:@[value,[oldvalue lastObject]] forKey:setting];
			}
			else {
				[oldDefaults setObject:@[[oldvalue firstObject],value] forKey:setting];
			}
		}
		else {
			[oldDefaults setObject:@[value,value] forKey:setting];
		}
	}
	
	[[NSUserDefaults standardUserDefaults] setObject:oldDefaults forKey:@"dock" inDomain:@"com.broganminer.genous"];
	[oldDefaults release];
}
%new
- (void)rowsChangedTo:(NSInteger)rows {
	return;
}
%new
- (void)genousReset {
	[[NSUserDefaults standardUserDefaults] setObject:@{} forKey:@"dock" inDomain:@"com.broganminer.genous"];
	[self addValuesForOrientation:self.orientation];
	[self genousValuesChanged];
}
%end
%end
%group genous
%hook SBIconStateArchiver
//write the correct values for each page as soon as its initialized after a respring
+ (id)_listFromRepresentation:(id)arg1 withMaxIconCount:(NSUInteger)arg2 context:(id)arg3 overflow:(id)arg4 {
	GNLog(@"GENOUS making a list from a representation");

	NSArray *rootLists = [[[[%c(SBIconController) sharedInstance] model] iconState] objectForKey:@"iconLists"];
	NSArray *buttonBar;
	for (id object in rootLists) {
		if ([arg1 isEqual:object]) {

			NSUInteger index = [rootLists indexOfObject:object];

			//make sure max iconcount changes to the correct listing
			arg2 = [%c(SBRootIconListView) maxIconsForIndex:index];
			goto end;
		}
	}
	//set the buttonBar variable to the dock lists
	GNLog(@"GENOUS dock loading from representation");
	buttonBar = [[[[%c(SBIconController) sharedInstance] model] iconState] objectForKey:@"buttonBar"];
	//see if the representation we loaded is the dock
	if ([arg1 isEqual:buttonBar] && !isHarborInstalled) {
		//if its the dock set the max icon count to the correct one
		arg2 = [%c(SBRootIconListView) maxIconsForDock];
	}
	end:

	GNLog(@"GENOUS done");
	return %orig(arg1,arg2,arg3,arg4);
}
%end
%hook SBRootIconListView

%new
+ (void)applyGenousSettingsToAllRootListsFromList:(SBRootIconListView *)list orientation:(NSInteger)orientation {
	CGFloat insetValues[4] = {[list topIconInset],list.frame.size.height-([list bottomIconInset]+buttonSize.height),list.frame.size.width-([list rightInset]+buttonSize.height),[list sideIconInset]};
	NSInteger rows = [list iconRowsForCurrentOrientation];
	NSInteger cols = [list iconColumnsForCurrentOrientation];
	CGFloat iconSize = [list iconSizePercentage];
	BOOL badges = [list genousResizeBadges];
	NSInteger label = [list genousLabelDisplay];
	for (SBRootIconListView *listToChange in [[%c(SBIconController) sharedInstance] _rootFolderController].iconListViews) {
		if (![listToChange isKindOfClass:[%c(SBDockIconListView) class]]) {
			listToChange.orientation = orientation;
			[listToChange rowsChangedTo:rows];
			[listToChange colsChangedTo:cols];
			for (int u = 0; u < 4; u++) {
				[listToChange setInsetFromPoint:CGPointMake(insetValues[u],insetValues[u]) ofType:u];
			}
			[listToChange iconSizedChangedTo:iconSize];
			[listToChange changeLabelDisplay:label];
			[listToChange changeResizeBadges:badges];
			listToChange.orientation = [(SpringBoard *)[UIApplication sharedApplication] interfaceOrientationForCurrentDeviceOrientation];
			[listToChange genousValuesChanged];
		}
	}
}

%new
- (void)applySettingsToOppositeOrientation {
	NSInteger rows = [self iconRowsForCurrentOrientation];
	NSInteger cols = [self iconColumnsForCurrentOrientation];
	CGFloat size = [self iconSizePercentage];
	BOOL badges = [self genousResizeBadges];
	NSInteger label = [self genousLabelDisplay];
	CGFloat insetValues[4] = {[self topIconInset],self.frame.size.height-([self bottomIconInset]+buttonSize.height),self.frame.size.width-([self rightInset]+buttonSize.height),[self sideIconInset]};
	if (self.orientation == 1 || self.orientation == 2) {
		self.orientation = 4;
	}
	else {
		self.orientation = 1;
	}
	[self rowsChangedTo:rows];
	[self colsChangedTo:cols];
	for (int u = 0; u < 4; u++) {
		[self setInsetFromPoint:CGPointMake(insetValues[u],insetValues[u]) ofType:u];
	}
	[self iconSizedChangedTo:size];
	[self changeLabelDisplay:label];
	[self changeResizeBadges:badges];
	self.orientation = [(SpringBoard *)[UIApplication sharedApplication] interfaceOrientationForCurrentDeviceOrientation];
	[self genousValuesChanged];
}
%new
- (void)setInsetFromPoint:(CGPoint)point ofType:(NSInteger)type {
	GNLog(@"GENOUS setting inset");
	CGFloat inset = 0.0;
	NSString *keyType = nil;
	if ([self isKindOfClass:[%c(SBDockIconListView) class]] && (type == 0 || type == 1))return;
	if (type == 0) {
		inset = point.y;
		keyType = @"topInset";

		objc_setAssociatedObject(self,&topInsetASO,[NSNumber numberWithFloat:inset],OBJC_ASSOCIATION_RETAIN);
	}
	else if (type == 1) {
		inset = self.frame.size.height-(point.y+buttonSize.height);
		keyType = @"bottomInset";

		objc_setAssociatedObject(self,&bottomInsetASO,[NSNumber numberWithFloat:inset],OBJC_ASSOCIATION_RETAIN);
	}
	else if (type == 2) {
		inset =  self.frame.size.width-(point.x+buttonSize.height);
		keyType = @"rightSideInset";

		objc_setAssociatedObject(self,&rightInsetASO,[NSNumber numberWithFloat:inset],OBJC_ASSOCIATION_RETAIN);
	}
	else if (type == 3) {
		inset = point.x;
		keyType = @"leftSideInset";

		objc_setAssociatedObject(self,&leftInsetASO,[NSNumber numberWithFloat:inset],OBJC_ASSOCIATION_RETAIN);
	}
	[self genousValuesChanged];
	[self writeValue:[NSNumber numberWithFloat:inset] forSetting:keyType];
}
- (void)updateEditingStateAnimated:(BOOL)arg1 {
	%orig;
	if ([self isKindOfClass:[%c(SBDockIconListView) class]] && isHarborInstalled) {
		return;
	}
	if (!self.editing) {
		[self removeSizingViews];
		CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.broganminer.genous.dismissController"), NULL, NULL, TRUE);
	}
}
- (void)prepareToRotateToInterfaceOrientation:(NSInteger)arg1 {
	if (([self isKindOfClass:[%c(SBDockIconListView) class]] && !isHarborInstalled) ||  ![self isKindOfClass:[%c(SBDockIconListView) class]]){
		self.orientation = arg1;
		[self addValuesForOrientation:arg1];
		[self genousValuesChanged];
		[self removeSizingViews];
	}
	%orig;
}

- (NSUInteger)iconRowsForSpacingCalculation {
	if (![self isKindOfClass:[%c(SBDockIconListView) class]]) {
		return [self iconRowsForCurrentOrientation];
	}
	else {
		return %orig;
	}
} 
- (NSUInteger)iconsInRowForSpacingCalculation {
	if ([self isKindOfClass:[%c(SBDockIconListView) class]] && isHarborInstalled) {
		return %orig;
	}
	else {
		return [self iconColumnsForCurrentOrientation];
	}
}

- (NSUInteger)iconColumnsForCurrentOrientation {
	if ([self isKindOfClass:[%c(SBDockIconListView) class]] && isHarborInstalled){
		return %orig;
	}
	NSNumber *columns = objc_getAssociatedObject(self,&columnsASO);
	if (columns != nil) {
		return [columns integerValue];
	}
	else {
		return %orig;
	}
}
- (NSUInteger)iconRowsForCurrentOrientation {
	if ([self isKindOfClass:[%c(SBDockIconListView) class]] && isHarborInstalled){
		return %orig;
	}
	NSNumber *rows = objc_getAssociatedObject(self,&rowsASO);
	if (rows != nil) {
		return [rows integerValue];
	}
	else {
		return %orig;
	}
}

- (SBIconCoordinate)iconCoordinateForIndex:(NSUInteger)arg1 forOrientation:(NSInteger)arg2 {
	if ([self isKindOfClass:[%c(SBDockIconListView) class]] && isHarborInstalled){
		return %orig;
	}
	NSUInteger maxCols = [self iconColumnsForCurrentOrientation];
	SBIconCoordinate cor;
	cor.row = (NSInteger)(arg1/maxCols)+1;
	cor.col = (NSInteger)(arg1%maxCols)+1;
	return cor;

}
- (NSUInteger)indexForCoordinate:(SBIconCoordinate)arg1 forOrientation:(NSInteger)arg2 {
	if ([self isKindOfClass:[%c(SBDockIconListView) class]] && isHarborInstalled){
		return %orig;
	}
	NSUInteger I;
	NSInteger maxCols = [self iconColumnsForCurrentOrientation];
	I = (arg1.col-1) + (maxCols * (arg1.row-1));
	return I;

}
- (NSUInteger)firstFreeSlotOrLastSlotIndexForType:(int)arg1 {
	if ([self isKindOfClass:[%c(SBDockIconListView) class]] && isHarborInstalled){
		return %orig;
	}
	NSUInteger s = [[self model] firstFreeSlotIndexForType:arg1];
	if (s != INT_MAX) {
    	return s;
    }
    NSUInteger max;
    object_getInstanceVariable([self model],"_maxIconCount",(void**)&max);
	return max;

}
- (void)setModel:(id)arg1 {
	if ([self isKindOfClass:[%c(SBDockIconListView) class]] && isHarborInstalled){
		%orig(arg1);
		return;
	}
	NSUInteger newMax;
	if (![self isKindOfClass:[%c(SBDockIconListView) class]]) {
		newMax = [[self class] maxIconsForIndex:[self indexOfListInRootFolder]];
	}
	else {
		newMax = [[self class] maxIconsForDock];
	}
	NSUInteger NMAddr = (NSUInteger)&newMax;
	object_setInstanceVariable(arg1, "_maxIconCount", *(NSUInteger**)NMAddr);
}
- (id)initWithModel:(id)arg1 orientation:(NSInteger)arg2 viewMap:(id)arg3 {
	self = %orig;
	if (self) {
		if ([self isKindOfClass:[%c(SBDockIconListView) class]] && isHarborInstalled){
			return self;
		}
		NSUInteger newMax;
		if (![self isKindOfClass:[%c(SBDockIconListView) class]]) {
			newMax = [[self class] maxIconsForIndex:[self indexOfListInRootFolder]];
		}
		else {
			newMax = [[self class] maxIconsForDock];
		}
		NSUInteger NMAddr = (NSUInteger)&newMax;
		object_setInstanceVariable([self model], "_maxIconCount", *(NSUInteger**)NMAddr);

		UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTappedList)];
		doubleTap.numberOfTapsRequired = 2;
		[self addGestureRecognizer:doubleTap];
		[doubleTap release];
		[self addValuesForOrientation:arg2];
	}
	
	
	return self;
}
%new
- (void)addValuesForOrientation:(NSInteger)orientation {
	GNLog(@"GENOUS adding values for an orientation");
	NSString *key;
	char *b[9] = {&columnsASO,&rowsASO,&rightInsetASO,&leftInsetASO,&bottomInsetASO,&topInsetASO,&iconSizeASO,&labelDisplayASO,&badgesASO};
	NSString *values[9] = {@"pages",@"pages",@"rightSideInset",@"leftSideInset",@"bottomInset",@"topInset",@"sizes",@"labels",@"badges"};
	if (orientation == 1 || orientation == 2) {
		key = @"portrait";
	}
	else {
		key = @"landscape";
	}
	for (int i = 0; i < 9; i++) {
		GNLog(@"GENOUS value type %i", i);
		char *pointer = b[i];
		NSNumber *n = objc_getAssociatedObject(self,&pointer);
		[n release];

		NSNumber *valueNumber = nil;
		NSArray *dictionarys = [[NSUserDefaults standardUserDefaults] objectForKey:values[i] inDomain:@"com.broganminer.genous"];
		GNLog(@"GENOUS list done adding values");
		if ([dictionarys count] > [self indexOfListInRootFolder]) {

			NSDictionary *dictionary = [dictionarys objectAtIndex:[self indexOfListInRootFolder]];
			if ([dictionary count] > 0 ) {
				if (i < 2) {
					valueNumber = [[dictionary objectForKey:key] objectAtIndex:i];
				}
				else {
					valueNumber = [dictionary objectForKey:key];
				}
			}
			else {
				if (i < 2) {
					valueNumber = [[dictionary objectForKey:@"portrait"] objectAtIndex:i];
				}
				else {
					valueNumber = [dictionary objectForKey:@"portrait"];
				}
			}
		}
		
		objc_setAssociatedObject(self,pointer,valueNumber,OBJC_ASSOCIATION_RETAIN);
	}
}
%new
- (void)removeSizingViews {
	for (UIView *view in [self subviews]) {
		if ([view isKindOfClass:[GenousMovingView class]]) {
			[view removeFromSuperview];
			[view release];
		}
		else if ([view isKindOfClass:[%c(SBIconView) class]]){
			view.userInteractionEnabled = YES;
		}
	}
}
%new
- (NSInteger)genousLabelDisplay {
	return [objc_getAssociatedObject(self, &labelDisplayASO) integerValue];
}
%new
- (BOOL)genousResizeBadges {
	return [objc_getAssociatedObject(self, &badgesASO) boolValue];
}
%new
- (void)changeLabelDisplay:(NSInteger)display {
	NSNumber *n = objc_getAssociatedObject(self, &labelDisplayASO);
	[n release];
	objc_setAssociatedObject(self, &labelDisplayASO, [NSNumber numberWithInteger:display], OBJC_ASSOCIATION_RETAIN);
	[self genousValuesChanged];
	[self writeValue:[NSNumber numberWithInteger:display] forSetting:@"labels"];
}
%new
- (void)changeResizeBadges:(BOOL)display {
	NSNumber *n = objc_getAssociatedObject(self, &labelDisplayASO);
	[n release];
	objc_setAssociatedObject(self, &badgesASO, [NSNumber numberWithInteger:display], OBJC_ASSOCIATION_RETAIN);
	[self genousValuesChanged];
	[self writeValue:[NSNumber numberWithBool:display] forSetting:@"badges"];
}
%new
- (void)addSizingViews {
	if (self.editing) {
		CGRect topFrame = CGRectMake((self.frame.size.width-([self rightInset]+[self sideIconInset]))/2-buttonSize.height+[self sideIconInset],[self topIconInset],buttonSize.width,buttonSize.height);
		CGRect bottomFrame = CGRectMake((self.frame.size.width-([self rightInset]+[self sideIconInset]))/2-buttonSize.height+[self sideIconInset],self.frame.size.height - [self bottomIconInset]-buttonSize.height,buttonSize.width,buttonSize.height);

		CGRect rightSideFrame = CGRectMake(self.frame.size.width - [self rightInset]-buttonSize.height,(self.frame.size.height-([self topIconInset]+[self bottomIconInset]))/2-buttonSize.height+[self topIconInset],buttonSize.height,buttonSize.width);
		CGRect leftSideFrame = CGRectMake([self sideIconInset],(self.frame.size.height-([self topIconInset]+[self bottomIconInset]))/2-buttonSize.height+[self topIconInset],buttonSize.height,buttonSize.width);

		CGRect frames[4] = {topFrame, bottomFrame, rightSideFrame, leftSideFrame};
		int i = 0;
		if ([self isKindOfClass:[%c(SBDockIconListView) class]]) i = 2;
		while (i < 4) {
			GenousMovingView *view = [[GenousMovingView alloc] initWithFrame:frames[i]];
			view.type = i;
			[view fixArrow];
			[self addSubview:view];
			view.layer.zPosition = 300;
			i++;
		}
		for (UIView *view in self.subviews) {
			if ([view isKindOfClass:[%c(SBIconView) class]]) {
				view.userInteractionEnabled = NO;
			}
		}
	}
}
%new
- (void)doubleTappedList {
	if (self.editing) {
		GNLog(@"GENOUS double tapped list");
		GenousView *presenting = [[GenousView alloc] initWithListView:self];
		[[[%c(SBIconController) sharedInstance] contentView] addSubview:presenting];
		presenting.alpha = 0;
		[UIView animateWithDuration:0.4 delay:0.0 options:UIViewAnimationCurveEaseOut 
			animations:^{
				presenting.alpha = 1.0;
			}
			completion:^(BOOL finished){
				presenting.userInteractionEnabled = YES;
			}];
		[presenting release];
	}
}

- (BOOL)isFull {
	if ([self isKindOfClass:[%c(SBDockIconListView) class]] && isHarborInstalled){
		return %orig;
	}
	if ([[self icons] count] >= [self iconColumnsForCurrentOrientation] * [self iconRowsForCurrentOrientation]) {
		return YES;
		}
	else {
		return NO;
	}
}
- (CGFloat)verticalIconPadding {
	if ([self isKindOfClass:[%c(SBDockIconListView) class]] && isHarborInstalled){
		return %orig;
	}
	CGFloat rows = (CGFloat)[self iconRowsForCurrentOrientation];
	if (![self isKindOfClass:[%c(SBDockIconListView) class]] && rows != 1) {
		CGFloat bottom = [self bottomIconInset];
		CGFloat top = [self topIconInset];
		return (self.frame.size.height-((rows*[self defaultIconSize].height)+bottom+top))/(rows-1);
	}
	else {
		return %orig;
	}
}
- (CGFloat)horizontalIconPadding {
	if ([self isKindOfClass:[%c(SBDockIconListView) class]] && isHarborInstalled){
		return %orig;
	}
	CGFloat cols = (CGFloat)[self iconColumnsForCurrentOrientation];
	CGFloat rightInset = [self rightInset];
	CGFloat leftInset = [self sideIconInset];
	if (cols != 1) {
		return (self.frame.size.width-((cols*[self defaultIconSize].width)+rightInset+leftInset))/(cols-1);
	}
	else {
		return %orig;
	}
}
%new
- (CGFloat)rightInset {
	CGFloat rightInset = [self sideIconInset];
	NSNumber *rightInsetNumber = objc_getAssociatedObject(self,&rightInsetASO);
	if (rightInsetNumber) {
		rightInset = [rightInsetNumber floatValue];
	}
	return rightInset;
}
- (CGFloat)sideIconInset {
	if ([self isKindOfClass:[%c(SBDockIconListView) class]] && isHarborInstalled){
		return %orig;
	}
	CGFloat sideIconInset = %orig;
	NSNumber *sideIconInsetNumber = objc_getAssociatedObject(self,&leftInsetASO);
	if (sideIconInsetNumber) {
		sideIconInset = [sideIconInsetNumber floatValue];
	}
	return sideIconInset;
}
- (CGFloat)bottomIconInset {
	if ([self isKindOfClass:[%c(SBDockIconListView) class]] && isHarborInstalled){
		return %orig;
	}
	CGFloat bottomIconInset = %orig;
	NSNumber *bottomIconInsetNumber = objc_getAssociatedObject(self,&bottomInsetASO);
	if (bottomIconInsetNumber) {
		bottomIconInset = [bottomIconInsetNumber floatValue];
	}
	return bottomIconInset;
}
- (CGFloat)topIconInset {
	if ([self isKindOfClass:[%c(SBDockIconListView) class]] && isHarborInstalled){
		return %orig;
	}
	CGFloat topIconInset = %orig;
	NSNumber *topIconInsetNumber = objc_getAssociatedObject(self,&topInsetASO);
	if (topIconInsetNumber) {
		topIconInset = [topIconInsetNumber floatValue];
	}
	return topIconInset;
}
%new
- (BOOL)editSizeOn {
	BOOL p = NO;
	for (UIView *view in self.subviews) {
		if ([view isKindOfClass:[GenousMovingView class]]) {
			p = YES;
			break;
		}
	}
	return p;
}
%new
- (void)colsChangedTo:(NSInteger)cols {
	GNLog(@"GENOUS columns changed");
	NSNumber *n = objc_getAssociatedObject(self,&columnsASO);
	[n release];
	objc_setAssociatedObject(self,&columnsASO,[NSNumber numberWithInteger:cols],OBJC_ASSOCIATION_RETAIN);
	[self genousValuesChanged];
	NSNumber *columnNumber = [NSNumber numberWithInteger:cols];
	NSNumber *rowNumber = [NSNumber numberWithInteger:[self iconRowsForCurrentOrientation]];
	[self writeValue:@[columnNumber,rowNumber] forSetting:@"pages"];
}
%new
- (void)rowsChangedTo:(NSInteger)rows {
	GNLog(@"GENOUS rows changed");
	NSNumber *n = objc_getAssociatedObject(self,&rowsASO);
	[n release];
	objc_setAssociatedObject(self,&rowsASO,[NSNumber numberWithInteger:rows],OBJC_ASSOCIATION_RETAIN);
	[self genousValuesChanged];
	NSNumber *rowNumber = [NSNumber numberWithInteger:rows];
	NSNumber *columnNumber = [NSNumber numberWithInteger:[self iconColumnsForCurrentOrientation]];
	[self writeValue:@[columnNumber,rowNumber] forSetting:@"pages"];
}
%new
- (void)iconSizedChangedTo:(CGFloat)size {
	GNLog(@"GENOUS icon size changed");
	
	objc_setAssociatedObject(self,&iconSizeASO,[NSNumber numberWithFloat:size],OBJC_ASSOCIATION_RETAIN);
	[self genousValuesChanged];
	[self writeValue:[NSNumber numberWithFloat:size] forSetting:@"sizes"];
	
}
%new
- (NSUInteger)indexOfListInRootFolder {
	NSInteger Index = INT_MAX;
	NSArray *listRep = [%c(SBIconStateArchiver) _representationForList:self];
	NSArray *rootLists = [[[[%c(SBIconController) sharedInstance] model] iconState] objectForKey:@"iconLists"];
	for (NSArray *list in rootLists) {
		if ([listRep isEqual:list]) {
			Index = [rootLists indexOfObject:list];
			break;
		}
	}
	return Index;
}
%new
- (void)genousValuesChanged {
	GNLog(@"GENOUS updating list appearance for a value change");
	NSUInteger newMax = [self iconColumnsForCurrentOrientation] * [self iconRowsForCurrentOrientation];
	NSUInteger NMAddr = (NSUInteger)&newMax;
	object_setInstanceVariable([self model], "_maxIconCount", *(NSUInteger**)NMAddr);
	[self removeIconsFromModelForMaxIconCountChangeAndThenReAddThemToTheRootFolder];
	[self layoutIconsNow];	
	for (SBIconView *iconView in self.subviews) {
		if([iconView isKindOfClass:[%c(SBIconView) class]]) {
			GNLog(@"GENOUS %@",[NSNumber numberWithFloat:[self iconSizePercentage]]);
			iconView.iconResizingFloat = [self iconSizePercentage];
			iconView.labelSizingOption = [self genousLabelDisplay];
			iconView.resizeBadgeBool = [self genousResizeBadges];
			[iconView genousResizeIconView];
		}
	}
}
%new
- (void)removeIconsFromModelForMaxIconCountChangeAndThenReAddThemToTheRootFolder {
	GNLog(@"GENOUS moving the backed up icons");
	SBIconListModel *model = [self model];
	NSUInteger maxIcons;
	object_getInstanceVariable(model,"_maxIconCount",(void**)&maxIcons);
	while ([[self icons] count] > maxIcons) {
		SBIcon *removedIcon = [[self icons] lastObject];
		[model removeIcon:removedIcon];
		[[self viewForIcon:removedIcon] removeFromSuperview];
		[[[%c(SBIconController) sharedInstance] _rootFolderController].folder addIcon:removedIcon];
	}

}
%new
+ (NSUInteger)maxIconsForIndex:(NSUInteger)index {
	GNLog(@"GENOUS maxIconsForIndex");
	NSArray *valueArray = [[NSUserDefaults standardUserDefaults] objectForKey:@"pages" inDomain:@"com.broganminer.genous"];
	if (index < [valueArray count] && [[valueArray objectAtIndex:index] count] > 0) {
		return [[[[valueArray objectAtIndex:index] objectForKey:@"portrait"] objectAtIndex:0] integerValue] * [[[[valueArray objectAtIndex:index] objectForKey:@"portrait"] objectAtIndex:1] integerValue];
	}
	else {
		return [[self class] maxIcons];
	}
}
%new
+ (NSUInteger)maxIconsForDock {
	GNLog(@"GENOUS maxIconsForDock");
	NSDictionary *dockValues = [[NSUserDefaults standardUserDefaults] objectForKey:@"dock" inDomain:@"com.broganminer.genous"];
	if ([dockValues objectForKey:@"columns"] != nil) {
		return [[[dockValues objectForKey:@"columns"] firstObject] unsignedIntegerValue];
	}
	else {
		return [[%c(SBDockIconListView) class] maxIcons];
	}
}
%new
- (void)genousReset {
	GNLog(@"GENOUS reseting page");
	NSArray *types = @[@"pages",@"bottomInset",@"leftSideInset",@"rightSideInset",@"topInset",@"sizes",@"badges",@"labels"];
	for (NSString *keyType in types) {
		NSMutableArray *oldDefaults = [[[NSUserDefaults standardUserDefaults] objectForKey:keyType inDomain:@"com.broganminer.genous"] mutableCopy];
		if (oldDefaults == nil) {
			oldDefaults = [[NSMutableArray alloc] init];
		}
		NSInteger index = [[[%c(SBIconController) sharedInstance] _rootFolderController].iconListViews indexOfObject:self];
		NSDictionary *p = [[NSDictionary alloc] init];
		while ([oldDefaults count] <= index) {
			[oldDefaults addObject:@{}];
		}
		[oldDefaults replaceObjectAtIndex:index withObject:p];
		[p release];
		[[NSUserDefaults standardUserDefaults] setObject:oldDefaults forKey:keyType inDomain:@"com.broganminer.genous"];
		[oldDefaults release];
	}
	[self addValuesForOrientation:self.orientation];
	[self genousValuesChanged];
}
- (void)insertSubview:(SBIconView *)view atIndex:(NSInteger)index {
	%orig;
	if ([self isKindOfClass:[%c(SBDockIconListView) class]] && isHarborInstalled){
		return;
	}
	if ([view isKindOfClass:[%c(SBIconView) class]]) {
		view.iconResizingFloat = [self iconSizePercentage];
		view.labelSizingOption = [self genousLabelDisplay];
		view.resizeBadgeBool = [self genousResizeBadges];
		if ([[view.subviews firstObject] isKindOfClass:[%c(STKGroupView) class]]) {
			for (SBIconView *ndIcons in [view.subviews firstObject].subviews) {
				if([ndIcons isKindOfClass:[%c(SBIconView) class]]) {
					ndIcons.iconResizingFloat = [self iconSizePercentage];
					ndIcons.labelSizingOption = [self genousLabelDisplay];
					ndIcons.resizeBadgeBool = [self genousResizeBadges];
				}
			}
		}
	}
}
- (void)addSubview:(SBIconView *)view {
	%orig;
	if ([self isKindOfClass:[%c(SBDockIconListView) class]] && isHarborInstalled){
		return;
	}
	if ([view isKindOfClass:[%c(SBIconView) class]]) {
		view.iconResizingFloat = [self iconSizePercentage];
		view.labelSizingOption = [self genousLabelDisplay];
		view.resizeBadgeBool = [self genousResizeBadges];
		if ([[view.subviews firstObject] isKindOfClass:[%c(STKGroupView) class]]) {
			for (SBIconView *ndIcons in [view.subviews firstObject].subviews) {
				if([ndIcons isKindOfClass:[%c(SBIconView) class]]) {
					ndIcons.iconResizingFloat = [self iconSizePercentage];					
					ndIcons.labelSizingOption = [self genousLabelDisplay];
					ndIcons.resizeBadgeBool = [self genousResizeBadges];
				}
			}
		}
	}
}
%new
- (CGFloat)iconSizePercentage {
	NSNumber *sizeNumber = objc_getAssociatedObject(self,&iconSizeASO);
	if (sizeNumber) {
		return [sizeNumber floatValue];
	}
	return 1.0f;
}
%new
- (void)writeValue:(id)value forSetting:(NSString *)setting {
	NSInteger index = [[[%c(SBIconController) sharedInstance] _rootFolderController].iconListViews indexOfObject:self];
	NSMutableArray *oldDefaults = [[[NSUserDefaults standardUserDefaults] objectForKey:setting inDomain:@"com.broganminer.genous"] mutableCopy];
	if(oldDefaults == nil)oldDefaults = [[NSMutableArray alloc] init];
	while ([oldDefaults count] <= index) {
		[oldDefaults addObject:@{}];
	}
	NSMutableDictionary *oldDict = [[oldDefaults objectAtIndex:index] mutableCopy];
	NSString *key = nil;
	(self.orientation == 1 || self.orientation == 2)?key = @"portrait" : key = @"landscape";
	[oldDict setObject:value forKey:key];
	[oldDefaults replaceObjectAtIndex:index withObject:oldDict];
	[[NSUserDefaults standardUserDefaults] setObject:oldDefaults forKey:setting inDomain:@"com.broganminer.genous"];
	[oldDict release];
	[oldDefaults release];
}

%end

/* apex compatibility, this is so we can make the icon sizes inside stacks correct*/
%hook STKGroupView
- (void)layoutSubviews {
	%orig;
	for (SBIconView *icon in self.subviews) {
		if([icon isKindOfClass:[%c(SBIconView) class]]) {
			if([self.superview isKindOfClass:[%c(SBIconView) class]]) {
				icon.resizeBadgeBool = ((SBIconView *)self.superview).resizeBadgeBool;
				icon.labelSizingOption = ((SBIconView *)self.superview).labelSizingOption;
				icon.iconResizingFloat = ((SBIconView *)self.superview).iconResizingFloat;
			}
			[icon genousResizeIconView];
		}
	}
}
%end

/*Iwidgets compatibility, it adds an overlay so we have to make sure to register the overlay to our double tap gesture*/
%hook IWWidgetsView
- (id)initWithPlist:(id)arg {
	self = %orig;
	if (self) {
		UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTapped)];
		doubleTap.numberOfTapsRequired = 2;
		[self addGestureRecognizer:doubleTap];
		[doubleTap release];
	}
	return self;
}
%new
- (void)doubleTapped {
	[[[[%c(SBIconController) sharedInstance] _rootFolderController] currentIconListView] doubleTappedList];
	//pass doubletap to the viewcontroller to do the magic
}
%end

%hook SBIconView

%property (retain) NSUInteger labelSizingOption;
%property (retain) BOOL resizeBadgeBool;
%property (retain) CGFloat iconResizingFloat;
- (void)prepareToCrossfadeImageWithView:(id)arg1 maskCorners:(BOOL)arg2 trueCrossfade:(BOOL)arg3 anchorPoint:(CGPoint)arg4 {
	if(([self isInDock] && isHarborInstalled) || [[self superview] isKindOfClass:[%c(SBFolderIconListView) class]]){
		%orig;
		return;
	}
	%orig(arg1,NO,arg3,arg4);
}

%new
- (void)genousResizeIconView {
	CGFloat percentage = self.iconResizingFloat;
	CGSize size = [self genousSize];
	if (percentage <= 0)percentage = 1;
	GNLog(@"GENOUS icon view percentage %f",percentage);
	if ([self isKindOfClass:[%c(SBFolderIconView) class]]) {
		[self iconBackgroundView].layer.bounds = CGRectMake(0,0,size.width,size.height);
		[self iconBackgroundView].layer.cornerRadius = 13.5 * percentage;
		[self _folderIconImageView].layer.bounds = CGRectMake(0,0,size.width,size.height);
	}
	else {
		[self _iconImageView].layer.bounds = CGRectMake(0,0,size.width,size.height);
		if ([[self _iconImageView] isKindOfClass:[%c(SBClockApplicationIconImageView) class]]) {
			CALayer *hours = nil; //(1x16)
			CALayer *minutes = nil; //(1x23.5)
			CALayer *seconds = nil; //(0.5x27.5)
			CALayer *black = nil; //(3x3)
			CALayer *red = nil; //(1x1)
			object_getInstanceVariable([self _iconImageView],"_hours",(void**)&hours);
			object_getInstanceVariable([self _iconImageView],"_minutes",(void**)&minutes);
			object_getInstanceVariable([self _iconImageView],"_seconds",(void**)&seconds);
			object_getInstanceVariable([self _iconImageView],"_blackDot",(void**)&black);
			object_getInstanceVariable([self _iconImageView],"_redDot",(void**)&red);
			CGFloat iconImageSize = [self _iconImageView].layer.bounds.size.width;
			CGFloat one = 1.0/62;
			CGFloat sixteen = 16.0/62;
			CGFloat half = 0.5/62;
			CGFloat three = 3.0/62;
			CGFloat twentythreehalf = 23.5/62;
			CGFloat twentysevenhalf = 27.5/62;
			hours.bounds = CGRectMake(0,0,one*iconImageSize,sixteen*iconImageSize);
			minutes.bounds = CGRectMake(0,0,one*iconImageSize,twentythreehalf*iconImageSize);
			seconds.bounds = CGRectMake(0,0,half*iconImageSize,twentysevenhalf*iconImageSize);
			black.bounds = CGRectMake(0,0,three*iconImageSize,three*iconImageSize);
			red.bounds = CGRectMake(0,0,one*iconImageSize,one*iconImageSize);
		}
		if ([self isKindOfClass:[%c(SBActivatorIconView) class]]) {
			for (UIView *view in self.subviews){
				if([view isKindOfClass:[%c(SBFolderIconBackgroundView) class]]) {
					view.layer.bounds = CGRectMake(0,0,size.width,size.height);
					view.layer.cornerRadius = 13.5 * percentage;
					break;
				}
			}			
		}
		
	}
	if([self.subviews count] > 0 && [[self.subviews objectAtIndex:0] isKindOfClass:[UIImageView class]]) {
			[self.subviews objectAtIndex:0].layer.bounds = CGRectMake(0,0,size.width*1.387,size.height*1.387);
	}
	UIView *labelView = nil;
	object_getInstanceVariable(self,"_labelView",(void**)&labelView);
	[self addSubview:labelView];
	labelView.frame = CGRectMake(labelView.frame.origin.x,[self _iconImageView].frame.origin.y+[self _iconImageView].frame.size.height+[self _labelVerticalOffset],labelView.frame.size.width,labelView.frame.size.height);
	labelView.transform = CGAffineTransformIdentity;
	if (self.labelSizingOption == GenousLabelDisplayResize) {
		labelView.transform = CGAffineTransformMakeScale(percentage,percentage);
	}
	else if (self.labelSizingOption == GenousLabelDisplayNone) {
		[labelView removeFromSuperview];
	}
	

	[self _updateAccessoryViewWithAnimation:NO];
	UIView *closeBox = nil;
	object_getInstanceVariable(self,"_closeBox",(void**)&closeBox);
	closeBox.frame = CGRectMake([self _iconImageView].frame.origin.x-(0.375*closeBox.frame.size.width),[self _iconImageView].frame.origin.y-(0.375*closeBox.frame.size.height),closeBox.frame.size.width,closeBox.frame.size.height);

}
- (void)layoutSubviews {
	if(([self isInDock] && isHarborInstalled) || [[self superview] isKindOfClass:[%c(SBFolderIconListView) class]]){
		%orig;
		return;
	}
	GNLog(@"GENOUS icon view laying out subviews");
	%orig;
	[self genousResizeIconView];
}
- (CGFloat)_labelVerticalOffset {
	if(([self isInDock] && isHarborInstalled) || [[self superview] isKindOfClass:[%c(SBFolderIconListView) class]])return %orig;
	CGFloat orig = %orig;
	CGFloat percentage = self.iconResizingFloat;
	if (percentage <= 0)percentage = 1;

	return orig * percentage;
}
%new
- (CGSize)genousSize {
	CGFloat percentage = self.iconResizingFloat;
	if (percentage <= 0)percentage = 1;

	return CGSizeMake([[self class] defaultIconImageSize].width * percentage,[[self class] defaultIconImageSize].height * percentage);
}
- (CGRect)_frameForAccessoryView {
	if(([self isInDock] && isHarborInstalled) || [[self superview] isKindOfClass:[%c(SBFolderIconListView) class]])return %orig;
	CGRect orig = %orig;
	orig.origin.x = [self _iconImageView].frame.size.width+[self _iconImageView].frame.origin.x-(0.625*orig.size.width);
	orig.origin.y = [self _iconImageView].frame.origin.y - (orig.size.height * 0.375);
	return orig;
}
- (void)_updateAccessoryViewWithAnimation:(BOOL)animated {
	if(([self isInDock] && isHarborInstalled) || [[self superview] isKindOfClass:[%c(SBFolderIconListView) class]]){
		%orig;
		return;
	}
	%orig;
	CGFloat percentage = self.iconResizingFloat;
	if (percentage <= 0)percentage = 1;

	UIView *badge;
	object_getInstanceVariable(self,"_accessoryView",(void**)&badge);
	if (badge != nil && self.resizeBadgeBool) {
		badge.transform = CGAffineTransformMakeScale(percentage,percentage);
	}
	else if (badge != nil) {
		badge.transform = CGAffineTransformIdentity;
	}
}
%end
%hook SBFolderIconImageView
- (CGSize)_interiorGridSizeClipRect {
	return CGSizeMake(self.frame.size.width*0.76,self.frame.size.height*0.76);
}
%end
%hook SBRootFolderView
- (void)_currentPageIndexDidChange {
	%orig;
	if (self.editing) {
		NSInteger i = 0;
		object_getInstanceVariable(self,"_indexAtScrollBegin",(void**)&i);
		if (i-1 < [self.iconListViews count] && i-1 >= 0)[[self.iconListViews objectAtIndex:i-1] genousValuesChanged];
		if (i+2 < [self.iconListViews count] && i+2 >= 0)[[self.iconListViews objectAtIndex:i+2] genousValuesChanged];
	}
}
%end
%hook SBIconController
- (void)_willRotateToInterfaceOrientation:(NSInteger)arg1 duration:(CGFloat)arg2 {
	%orig;
	GNLog(@"GENOUS rotating device orientation");
	CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.broganminer.genous.rotatewillhappen"), NULL, NULL, TRUE);
}
%end

/**
iOS 10 has issues with this class need to update
**/
%subclass GenousAddToAlert : SBAlertItem
- (id)alertSheet {
	NSString *final;
	if ([(SpringBoard *)[UIApplication sharedApplication] interfaceOrientationForCurrentDeviceOrientation] == 1 || [(SpringBoard *)[UIApplication sharedApplication] interfaceOrientationForCurrentDeviceOrientation] == 2) {
		final = @"This Page Landscape";
	}
	else {
		final = @"This Page Portrait";
	}
	return [[UIAlertView alloc] initWithTitle:@"Apply To..." message:@"" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"All Pages Portrait",@"All Pages Landscape",@"All Pages Both",final,nil];
}
- (void)alertView:(id)arg1 clickedButtonAtIndex:(NSInteger)arg2 {
	SBRootIconListView *listView = [[[%c(SBIconController) sharedInstance] _rootFolderController] currentIconListView];

	switch (arg2) {
		case 0:
			GNLog(@"GENOUS 0"); //cancel
			break;
		case 1:
			[[listView class] applyGenousSettingsToAllRootListsFromList:listView orientation:1];
			GNLog(@"GENOUS 1"); //all portrait
			break;
		case 2:
			[[listView class] applyGenousSettingsToAllRootListsFromList:listView orientation:4];
			GNLog(@"GENOUS 2"); //all landscape
			break;
		case 3:
			[[listView class] applyGenousSettingsToAllRootListsFromList:listView orientation:1];
			[[listView class] applyGenousSettingsToAllRootListsFromList:listView orientation:4];
			GNLog(@"GENOUS 3"); //all both
			break;
		case 4:
			[listView applySettingsToOppositeOrientation];
			GNLog(@"GENOUS 4"); //this opposite orientation
			break;
		default:
			break;
	}
	%orig;
}
%end
%end

%ctor {
	%init(genous);
	isHarborInstalled = YES;
	if(![[NSFileManager defaultManager] fileExistsAtPath:@"/Library/MobileSubstrate/DynamicLibraries/Harbor.dylib"]) {
		isHarborInstalled = NO;
		%init(genousdock);
	}
 
}