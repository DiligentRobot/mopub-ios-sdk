//
//  KIFTestScenario+Greystripe.m
//  MoPub
//
//  Copyright (c) 2013 MoPub. All rights reserved.
//

#import "KIFTestScenario+Greystripe.h"
#import <objc/runtime.h>

@implementation KIFTestScenario (Greystripe)

+ (KIFTestScenario *)scenarioForGreystripeInterstitial
{
    KIFTestScenario *scenario = [MPSampleAppTestScenario scenarioWithDescription:@"Test that a Greystripe interstitial ad works."];
    NSIndexPath *indexPath = [MPAdSection indexPathForAd:@"Greystripe Interstitial" inSection:@"Interstitial Ads"];
    [scenario addStep:[KIFTestStep stepToActuallyTapRowInTableViewWithAccessibilityLabel:@"Ad Table View"
                                                                     atIndexPath:indexPath]];

    [scenario addStep:[KIFTestStep stepToTapViewWithAccessibilityLabel:@"Load"]];
    [scenario addStep:[KIFTestStep stepToWaitUntilActivityIndicatorIsNotAnimating]];
    [scenario addStep:[KIFTestStep stepToTapViewWithAccessibilityLabel:@"Show"]];
    [scenario addStep:[KIFTestStep stepToWaitForPresenceOfViewWithClassName:@"GSFullscreenAdView"]];
    [scenario addStep:[KIFTestStep stepToLogImpressionForAdUnit:[MPAdSection adInfoAtIndexPath:indexPath].ID]];
    [scenario addStep:[KIFTestStep stepToPerformBlock:^{
        // We can't get KIF to tap on Greystripe's webview, so instead, we grab the controller and tell it to go away
        id gsFullScreenAdViewController = [KIFHelper topMostViewController];
        [gsFullScreenAdViewController dismissAnimated:YES];
    }]];
    [scenario addStep:[KIFTestStep stepToWaitForAbsenseOfViewWithClassName:@"GSFullscreenAdView"]];

    [scenario addStep:[KIFTestStep stepToReturnToBannerAds]];

    return scenario;
}

@end
