//
//  NSNLDataSource.m
//  NSTimes
//
//  Created by Simon Maddox on 06/12/2012.
//  Copyright (c) 2012 Robert Dougan. All rights reserved.
//

#import "NSNLDataSource.h"
#import "Train.h"
#import "DDXML.h"
#import "TFHpple.h"

@implementation NSNLDataSource

- (NSURLRequest *)requestWithFrom:(NSString *)from to:(NSString *)to
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://www.ns.nl/reisplanner-v2/index.shtml"]];
    [request setHTTPMethod:@"POST"];
    
    NSDateComponents *components = [[NSCalendar currentCalendar] components:NSDayCalendarUnit|NSMonthCalendarUnit|NSYearCalendarUnit|NSHourCalendarUnit|NSMinuteCalendarUnit fromDate:[NSDate date]];
    NSInteger day = [components day];
    NSInteger month = [components month];
    NSInteger year = [components year];
    NSInteger hour = [components hour];
    NSInteger minute = [components minute];
    
    NSString *postString = [NSString stringWithFormat:@"show-reisplannertips=true&language=en&js-action=%%2Freisplanner-v2%%2Findex.shtml&SITESTAT_ELEMENTS=sitestatElementsReisplannerV2&POST_AUTOCOMPLETE=%%2Freisplanner-v2%%2Fautocomplete.ajax&POST_VALIDATE=%%2Freisplanner-v2%%2FtravelAdviceValidation.ajax&outwardTrip.fromLocation.locationType=STATION&outwardTrip.fromLocation.name=%@&outwardTrip.toLocation.locationType=STATION&outwardTrip.toLocation.name=%@&outwardTrip.viaStationName=&outwardTrip.dateType=specified&outwardTrip.day=%i&outwardTrip.month=%i&outwardTrip.year=%i&outwardTrip.hour=%i&outwardTrip.minute=%i&outwardTrip.arrivalTime=false&submit-search=Give+trip+and+price", from, to, day, month, year, hour, minute];
    
    [request setHTTPBody:[postString dataUsingEncoding:NSUTF8StringEncoding]];
    
    return request;
}

- (NSURLRequest *)requestForMoreWithFrom:(NSString *)from to:(NSString *)to
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://www.ns.nl/reisplanner-v2/earlierLater.ajax"]];
    [request setHTTPMethod:@"POST"];
    
    NSString *postString = @"direction=outwardTrip&type=later";
    
    [request setHTTPBody:[postString dataUsingEncoding:NSUTF8StringEncoding]];
    
    return request;
}

- (NSString *)XPathQueryForTrains
{
    return @"//table[@class='time-table']/tbody/tr";
}

- (NSDate *)train:(Train *)train departureDateFromElement:(TFHppleElement *)element
{
    NSString *departureString = [NSString stringWithFormat:@"%@ %@", [[NSRailConnection sharedInstance] normalizeString:[[element firstChildWithClassName:@"departure-date"] text]], [[NSRailConnection sharedInstance] normalizeString:[[element firstChildWithClassName:@"departure"] text]]];
    
    return [[NSRailConnection sharedInstance] dateForString:departureString];
    
}

- (NSDate *)train:(Train *)train arrivalDateFromElement:(TFHppleElement *)element
{
    NSString *arrivalString = [NSString stringWithFormat:@"%@ %@", [[NSRailConnection sharedInstance] normalizeString:[[element firstChildWithClassName:@"arrival-date"] text]], [[NSRailConnection sharedInstance] normalizeString:[[element firstChildWithClassName:@"arrival"] text]]];
    
    return [[NSRailConnection sharedInstance] dateForString:arrivalString];
}

- (NSString *)train:(Train *)train platformFromElement:(TFHppleElement *)element
{
    return [[NSRailConnection sharedInstance] normalizeString:[[element firstChildWithClassName:@"platform"] text]];
}

- (NSString *)train:(Train *)train travelTimeFromElement:(TFHppleElement *)element
{
    return [[NSRailConnection sharedInstance] normalizeString:[[element firstChildWithClassName:@"travel-time"] text]];
}

- (NSString *)train:(Train *)train departureDelayFromElement:(TFHppleElement *)element
{
    NSArray *departureDelay = [[element firstChildWithClassName:@"departure"] childrenWithTagName:@"strong"];
    if (departureDelay && [departureDelay count] > 0) {
        return [[NSRailConnection sharedInstance] normalizeString:[[departureDelay objectAtIndex:0] text]];
    } else {
        return @"";
    }
}

- (NSString *)train:(Train *)train arrivalDelayFromElement:(TFHppleElement *)element
{
    NSArray *arrivalDelay = [[element firstChildWithClassName:@"arrival"] childrenWithTagName:@"strong"];
    if (arrivalDelay && [arrivalDelay count] > 0) {
        return [[NSRailConnection sharedInstance] normalizeString:[[arrivalDelay objectAtIndex:0] text]];
    } else {
        return @"";
    }
    

}

- (BOOL)shouldDisplayTrain:(Train *)train
{
    NSInteger diff = ([train.departure timeIntervalSinceReferenceDate] - [NSDate timeIntervalSinceReferenceDate]) / 60;
    
    return (diff <= 60);
}

@end
