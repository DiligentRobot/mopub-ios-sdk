#import "MPAdServerURLBuilder.h"
#import "MPConstants.h"
#import "MPIdentityProvider.h"
#import "MPGlobal.h"
#import <CoreLocation/CoreLocation.h>

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

static BOOL advertisingTrackingEnabled = YES;

@implementation MPAdServerURLBuilder (Spec)

+ (BOOL)advertisingTrackingEnabled
{
    return advertisingTrackingEnabled;
}

@end


SPEC_BEGIN(MPAdServerURLBuilderSpec)

describe(@"MPAdServerURLBuilder", ^{
    __block NSURL *URL;
    __block NSString *expected;

    describe(@"base case", ^{
        it(@"should have the right things", ^{
            URL = [MPAdServerURLBuilder URLWithAdUnitID:@"guy"
                                               keywords:nil
                                               location:nil
                                                testing:YES];
            expected = [NSString stringWithFormat:@"http://testing.ads.mopub.com/m/ad?v=8&udid=%@&id=guy&nv=%@",
                        [MPIdentityProvider identifier],
                        MP_SDK_VERSION];
            URL.absoluteString should contain(expected);

            URL = [MPAdServerURLBuilder URLWithAdUnitID:@"guy"
                                               keywords:nil
                                               location:nil
                                                testing:NO];
            expected = [NSString stringWithFormat:@"http://ads.mopub.com/m/ad?v=8&udid=%@&id=guy&nv=%@",
                        [MPIdentityProvider identifier],
                        MP_SDK_VERSION];
            URL.absoluteString should contain(expected);
        });
    });

    it(@"should process keywords", ^{
        [UIPasteboard removePasteboardWithName:@"fb_app_attribution"];
        URL = [MPAdServerURLBuilder URLWithAdUnitID:@"guy"
                                           keywords:@"  something with whitespace,another  "
                                           location:nil
                                            testing:YES];
        URL.absoluteString should contain(@"&q=something%20with%20whitespace,another");

        URL = [MPAdServerURLBuilder URLWithAdUnitID:@"guy"
                                           keywords:nil
                                           location:nil
                                            testing:YES];
        URL.absoluteString should_not contain(@"&q=");

        UIPasteboard *pb = [UIPasteboard pasteboardWithName:@"fb_app_attribution" create:YES];
        pb.string = @"from zuckerberg with love";
        URL = [MPAdServerURLBuilder URLWithAdUnitID:@"guy"
                                           keywords:@"a=1"
                                           location:nil
                                            testing:YES];
        URL.absoluteString should contain(@"&q=a=1,FBATTRID:from%20zuckerberg%20with%20love");
        [UIPasteboard removePasteboardWithName:@"fb_app_attribution"];
    });

    it(@"should process orientation", ^{
        [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationPortrait];
        URL = [MPAdServerURLBuilder URLWithAdUnitID:@"guy"
                                           keywords:nil
                                           location:nil
                                            testing:YES];
        URL.absoluteString should contain(@"&o=p");

        [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationLandscapeRight];
        URL = [MPAdServerURLBuilder URLWithAdUnitID:@"guy"
                                           keywords:nil
                                           location:nil
                                            testing:YES];
        URL.absoluteString should contain(@"&o=l");
    });

    it(@"should process scale factor", ^{
        URL = [MPAdServerURLBuilder URLWithAdUnitID:@"guy"
                                           keywords:nil
                                           location:nil
                                            testing:YES];

        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"&sc=\\d\\.0"
                                                                               options:0
                                                                                 error:NULL];
        [regex numberOfMatchesInString:URL.absoluteString options:0 range:NSMakeRange(0, URL.absoluteString.length)] should equal(1);
    });

    it(@"should process time zone", ^{
        URL = [MPAdServerURLBuilder URLWithAdUnitID:@"guy"
                                           keywords:nil
                                           location:nil
                                            testing:YES];

        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"&z=[-+]\\d{4}"
                                                                               options:0
                                                                                 error:NULL];
        [regex numberOfMatchesInString:URL.absoluteString options:0 range:NSMakeRange(0, URL.absoluteString.length)] should equal(1);
    });

    it(@"should process location", ^{
        URL = [MPAdServerURLBuilder URLWithAdUnitID:@"guy"
                                           keywords:nil
                                           location:nil
                                            testing:YES];
        URL.absoluteString should_not contain(@"&ll=");

        CLLocation *validLocationNoAccuracy = [[[CLLocation alloc] initWithLatitude:10.1 longitude:-40.23] autorelease];
        URL = [MPAdServerURLBuilder URLWithAdUnitID:@"guy"
                                           keywords:nil
                                           location:validLocationNoAccuracy
                                            testing:YES];
        URL.absoluteString should contain(@"&ll=10.1,-40.23");
        URL.absoluteString should_not contain(@"&lla=");

        CLLocation *validLocationWithAccuracy = [[[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(10.1, -40.23)
                                                                               altitude:30.4
                                                                     horizontalAccuracy:500.1
                                                                       verticalAccuracy:60
                                                                              timestamp:[NSDate date]] autorelease];
        URL = [MPAdServerURLBuilder URLWithAdUnitID:@"guy"
                                           keywords:nil
                                           location:validLocationWithAccuracy
                                            testing:YES];
        URL.absoluteString should contain(@"&ll=10.1,-40.23");
        URL.absoluteString should contain(@"&lla=500.1");

        CLLocation *invalidLocation = [[[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(10.1, -40.23)
                                                                     altitude:30.4
                                                           horizontalAccuracy:-1
                                                             verticalAccuracy:60
                                                                    timestamp:[NSDate date]] autorelease];
        URL = [MPAdServerURLBuilder URLWithAdUnitID:@"guy"
                                           keywords:nil
                                           location:invalidLocation
                                            testing:YES];
        URL.absoluteString should_not contain(@"&ll=");
        URL.absoluteString should_not contain(@"&lla=");
    });

    it(@"should have mraid", ^{
        URL = [MPAdServerURLBuilder URLWithAdUnitID:@"guy"
                                           keywords:nil
                                           location:nil
                                            testing:YES];
        URL.absoluteString should contain(@"&mr=1");
    });

    it(@"should turn advertisingTrackingEnabled into DNT", ^{
        URL = [MPAdServerURLBuilder URLWithAdUnitID:@"guy"
                                           keywords:nil
                                           location:nil
                                            testing:YES];
        URL.absoluteString should_not contain(@"&dnt=");

        advertisingTrackingEnabled = NO;
        URL = [MPAdServerURLBuilder URLWithAdUnitID:@"guy"
                                           keywords:nil
                                           location:nil
                                            testing:YES];
        URL.absoluteString should contain(@"&dnt=1");

        advertisingTrackingEnabled = YES;
    });
});

SPEC_END
