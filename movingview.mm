#import "genousmovingview.h"
@interface UIView (fake)
- (void)setInsetFromPoint:(CGPoint)point ofType:(NSInteger)type;
- (CGFloat)sideIconInset;
- (CGFloat)topIconInset;
- (CGFloat)bottomIconInset;
- (CGFloat)rightInset;
@end
@implementation GenousMovingView
- (id)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];
	if (self) {
		if (frame.size.width > frame.size.height) {
			_wide = YES;
		}
		else {
			_wide = NO;
		}
		_gesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panned:)];
		[_gesture setMinimumNumberOfTouches:1];
    	[_gesture setMaximumNumberOfTouches:1];
    	[self addGestureRecognizer:_gesture];
    	_blur = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleLight]];
    	_blur.frame = CGRectMake(0,0,frame.size.width,frame.size.height);
    	[self addSubview:_blur];
    	self.layer.masksToBounds = YES;
    	self.layer.cornerRadius = 10;
    	_arrow = [[UIImageView alloc] initWithImage:[UIImage imageWithContentsOfFile:@"/Library/Application Support/Genous/arrow.png"]];
    	_arrow.frame = CGRectMake(frame.size.width/4,frame.size.height/4,frame.size.width/2,frame.size.height/2);
    	[self addSubview:_arrow];
	}
	return self;
}
- (void)panned:(UIPanGestureRecognizer *)gesture {
	CGPoint trans = [gesture velocityInView:self.superview];
	CGRect cFrame = self.frame;
	CGFloat amount = 0;
	if (_wide) {
		if (self.frame.origin.y >= 0 && self.frame.origin.y <= self.superview.frame.size.height-self.frame.size.height) {
			cFrame.origin.y += trans.y*0.02;
			amount = cFrame.origin.y - self.frame.origin.y;
		}
		if (cFrame.origin.y < 0) {
			cFrame.origin.y = 0;
			amount = 0;
		}
		else if (cFrame.origin.y > self.superview.frame.size.height-self.frame.size.height) {
			cFrame.origin.y = self.superview.frame.size.height-self.frame.size.height;
			amount = 0;
		}
	}
	else {
		if (self.frame.origin.x >= 0 && self.frame.origin.x <= self.superview.frame.size.width-self.frame.size.width) {
			cFrame.origin.x += trans.x*0.02;
			amount = cFrame.origin.x - self.frame.origin.x;
		}
		if (cFrame.origin.x < 0) {
			cFrame.origin.x = 0;
			amount = 0;
		}
		else if (cFrame.origin.x > self.superview.frame.size.width-self.frame.size.width) {
			cFrame.origin.x = self.superview.frame.size.width-self.frame.size.width;
			amount = 0;
		}
	}
	self.frame = cFrame;
	[self moveIconsInSuperviewWithAmount:amount];
	if ([gesture state] == UIGestureRecognizerStateEnded) {
		for (UIView *view in self.fakeListView.subviews) {
			CGPoint convertedOrigin = [self.fakeListView convertPoint:view.frame.origin toView:self.superview];
			[self.superview addSubview:view];
			view.frame = CGRectMake(convertedOrigin.x,convertedOrigin.y,view.frame.size.width,view.frame.size.height);
		}
		[self.fakeListView removeFromSuperview];
		[self.fakeListView release];
		self.fakeListView = nil;
		[self.superview setInsetFromPoint:self.frame.origin ofType:_type];
	}
}
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	self.fakeListView = [[UIView alloc] initWithFrame:CGRectMake([self.superview sideIconInset],[self.superview topIconInset],self.superview.frame.size.width-([self.superview rightInset] +[self.superview sideIconInset]),self.superview.frame.size.height-([self.superview topIconInset] +[self.superview bottomIconInset]))];
	[self.superview insertSubview:self.fakeListView atIndex:0];
	for (UIView *view in [self.superview subviews]) {
		if (![view isKindOfClass:[self class]] && view != self.fakeListView) {
			[self.fakeListView addSubview:view];
			CGRect o = view.frame;
			o.origin = [self.superview convertPoint:o.origin toView:self.fakeListView];
			view.frame = o;
		}
	}
}
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	for (UIView *view in self.fakeListView.subviews) {
		CGPoint convertedOrigin = [self.fakeListView convertPoint:view.frame.origin toView:self.superview];
		[self.superview addSubview:view];
		view.frame = CGRectMake(convertedOrigin.x,convertedOrigin.y,view.frame.size.width,view.frame.size.height);
	}
	[self.fakeListView removeFromSuperview];
	[self.fakeListView release];
	self.fakeListView = nil;
}
- (void)moveIconsInSuperviewWithAmount:(CGFloat)amount {
	NSMutableDictionary *viewPer = [[NSMutableDictionary alloc] init];
	int i = 0;
	for (UIView *view in self.fakeListView.subviews) {
		CGFloat xPer = view.frame.origin.x/(self.fakeListView.frame.size.width-self.frame.size.width);
		CGFloat yPer = view.frame.origin.y/(self.fakeListView.frame.size.height-self.frame.size.height);
		[viewPer setObject:@[[NSNumber numberWithFloat:xPer],[NSNumber numberWithFloat:yPer]] forKey:[NSString stringWithFormat:@"%li",(long)i]];
		view.tag = i;
		i++;
	}
	CGRect cFrame = self.fakeListView.frame;
	if (_type == 0) {
		//top
		cFrame.origin.y += amount;
		cFrame.size.height -= amount;
	}
	else if (_type == 1) {
		//bottom
		cFrame.size.height += amount;
	}
	else if (_type == 2) {
		//right
		cFrame.size.width += amount;
	}
	else if (_type == 3) {
		//left
		cFrame.origin.x += amount;
		cFrame.size.width -= amount;
	}
	self.fakeListView.frame = cFrame;
	for (UIView *view in self.fakeListView.subviews) {
		NSArray *perCor = [viewPer objectForKey:[NSString stringWithFormat:@"%li",(long)view.tag]];
		CGRect f = view.frame;
		f.origin.x = [[perCor objectAtIndex:0] floatValue] * (self.fakeListView.frame.size.width-self.frame.size.width);
		f.origin.y = [[perCor objectAtIndex:1] floatValue] * (self.fakeListView.frame.size.height-self.frame.size.height);
		view.frame = f;
	}
	[viewPer release];
	for (UIView *view in self.superview.subviews) {
		if ([view isKindOfClass:[self class]]) {
			CGRect p = view.frame;
			if (((GenousMovingView *)view).wide) {
				p.origin.x = ((self.fakeListView.frame.size.width/2) - (view.frame.size.width/2)) + self.fakeListView.frame.origin.x;
			}
			else {
				p.origin.y = ((self.fakeListView.frame.size.height/2) - (view.frame.size.height/2)) + self.fakeListView.frame.origin.y;
			}
			view.frame = p;
		}
	}
}
- (void)fixArrow {
	switch (_type) {
		case 1:
			//bottom
			_arrow.layer.transform = CATransform3DMakeRotation (M_PI, 0, 0, 1);
			break;
		case 2:
			//right
			_arrow.layer.transform = CATransform3DMakeRotation (M_PI_2, 0, 0, 1);
			_arrow.layer.bounds = _arrow.frame;
			break;
		case 3:
			//left
			_arrow.layer.transform = CATransform3DMakeRotation (-M_PI_2, 0, 0, 1);
			_arrow.layer.bounds = _arrow.frame;
			break;
		default:
			break;
	}
}
- (void)dealloc {
	[_gesture release];
	[_blur release];
	[_arrow release];
	[super dealloc];
}
@end