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

- (NSDate *)departureDateFromElement:(DDXMLElement *)element
{
    NSString *departureTimeString = [[NSRailConnection sharedInstance] normalizeString:[[[element nodesForXPath:@"vertrek" error:nil] objectAtIndex:0] stringValue]];

    NSString *departureString = [NSString stringWithFormat:@"%@ %@", [[NSRailConnection sharedInstance] normalizeString:[[[element nodesForXPath:@"vertrekdatum" error:nil] objectAtIndex:0] stringValue]], departureTimeString];
    
    return [[NSRailConnection sharedInstance] dateForString:departureString];
    
}

- (NSDate *)arrivalDateFromElement:(DDXMLElement *)element
{
    
}

- (NSString *)platformFromElement:(DDXMLElement *)element
{
    return [[NSRailConnection sharedInstance] normalizeString:[[[element nodesForXPath:@"aankomstspoor" error:nil] objectAtIndex:0] stringValue]];
}

- (NSString *)travelTimeFromElement:(DDXMLElement *)element
{
    return [[NSRailConnection sharedInstance] normalizeString:[[[element nodesForXPath:@"reistijd" error:nil] objectAtIndex:0] stringValue]];
}

- (NSString *)departureDelayFromElement:(DDXMLElement *)element
{
    
}

- (NSString *)arrivalDelayFromElement:(DDXMLElement *)element
{
    
}

- (BOOL)shouldDisplayTrain:(Train *)train
{
    
}

@end
