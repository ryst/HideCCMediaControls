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

#import <SpringBoard/SpringBoard.h>

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
	SBApplication* nowPlayingApp = [(SpringBoard*)[UIApplication sharedApplication] nowPlayingApp];
	if (nowPlayingApp)
		hideMediaControls = NO;
	else
		hideMediaControls = YES;

	%orig;
}
%end

%hook SBControlCenterContentView
-(id) _separatorAtIndex:(unsigned)index {
	if (index == 1 && hideMediaControls) { // separator between brightness and media controls
		return nil;
	} else {
		return %orig;
	}
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

%ctor {
	if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_7_0) {
		if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
			%init(HideCCMediaControls);
		}
	}
}

