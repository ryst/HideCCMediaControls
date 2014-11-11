/*
 * HideCCMediaControls
 *
 * This tweak hides the media controls in the portrait control center when there is no "now playing" app.
 * Media controls are always shown in the landscape control center because there is nothing saved by hiding it.
 * iPhone only.
 *
 */

#ifndef kCFCoreFoundationVersionNumber_iOS_7_0
#define kCFCoreFoundationVersionNumber_iOS_7_0 847.20
#endif

#ifndef kCFCoreFoundationVersionNumber_iOS_8_0
#define kCFCoreFoundationVersionNumber_iOS_8_0 1140.10
#endif

#ifndef kCFCoreFoundationVersionNumber_iOS_8_1
#define kCFCoreFoundationVersionNumber_iOS_8_1 1141.14
#endif

#define isiOS7 (kCFCoreFoundationVersionNumber >= 847.20)
#define isiOS8 (kCFCoreFoundationVersionNumber >= 1140.10)

@class SBApplication;

@interface SpringBoard
-(id)nowPlayingApp; // iOS7
-(int)nowPlayingProcessPID; // iOS8
@end

static UIInterfaceOrientation currentOrientation = UIInterfaceOrientationPortrait;
static bool hideMediaControlsLast = NO;
static bool hideMediaControls = NO;

%group HideCCMediaControls
%hook SBControlCenterViewController
-(CGFloat) contentHeightForOrientation:(UIInterfaceOrientation)orientation {
	currentOrientation = orientation;

	if (UIInterfaceOrientationIsPortrait(currentOrientation)) {
		if (hideMediaControls != hideMediaControlsLast) {
			SBControlCenterContentView *contentView = MSHookIvar<SBControlCenterContentView *>(self, "_contentView");
			[contentView setNeedsLayout];

			hideMediaControlsLast = hideMediaControls;
		}
	} else {
		hideMediaControls = NO;
	}

	return %orig;
}

-(void)controlCenterWillPresent {
	if (isiOS8) {
		int nowPlayingProcessPID = [(SpringBoard*)[UIApplication sharedApplication] nowPlayingProcessPID];
		hideMediaControls = (nowPlayingProcessPID <= 0);
	} else {
		SBApplication* nowPlayingApp = [(SpringBoard*)[UIApplication sharedApplication] nowPlayingApp];
		hideMediaControls = (nowPlayingApp == nil);
	}

	%orig;
}
%end

%hook SBCCMediaControlsSectionController
-(CGSize) contentSizeForOrientation:(int)orientation {
	if (hideMediaControls) {
		return CGSizeMake(0, 0);
	} else {
		return %orig;
	}
}
%end
%end

%group HideCCMediaControls7
%hook SBControlCenterContentView
-(id) _separatorAtIndex:(unsigned)index {
	if (index == 1 && hideMediaControls) { // separator between brightness and media controls
		return nil;
	} else {
		return %orig;
	}
}
%end
%end

%ctor {
	if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
		if (isiOS7) {
			%init(HideCCMediaControls);
			if (!isiOS8) {
				%init(HideCCMediaControls7);
			}
		}
	}
}

