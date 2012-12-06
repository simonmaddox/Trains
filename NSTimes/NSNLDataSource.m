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

- (NSArray *)trainsWithData:(NSData *)data
{
    NSMutableArray *trains = [NSMutableArray array];
    
    DDXMLDocument *document = [[DDXMLDocument alloc] initWithData:data options:0 error:nil];
    NSArray *elements = [document nodesForXPath:@"//reistijden/reizen/reis" error:nil];
    
    for (DDXMLElement *element in elements) {
        Train *train = [[Train alloc] init];
        
        // Simple fields
        [train setPlatform:[[NSRailConnection sharedInstance] normalizeString:[[[element nodesForXPath:@"aankomstspoor" error:nil] objectAtIndex:0] stringValue]]];
        [train setTravelTime:[[NSRailConnection sharedInstance] normalizeString:[[[element nodesForXPath:@"reistijd" error:nil] objectAtIndex:0] stringValue]]];
        
        // Delays
        NSString *departureDeley = @"";
        NSString *departureTimeString = [[NSRailConnection sharedInstance] normalizeString:[[[element nodesForXPath:@"vertrek" error:nil] objectAtIndex:0] stringValue]];
        TFHpple *departureElements = [[TFHpple alloc] initWithHTMLData:[departureTimeString dataUsingEncoding:NSUTF8StringEncoding]];
        
        if ([[train platform] isEqualToString:@"5a"]) {
            NSArray *departureArray = [departureElements searchWithXPathQuery:@"//text()"];
            
            if ([departureArray count] > 0) {
                departureTimeString = [[NSRailConnection sharedInstance] normalizeString:[[departureArray objectAtIndex:0] content]];
            }
            
            if ([departureArray count] > 1) {
                departureDeley = [[NSRailConnection sharedInstance] normalizeString:[[departureArray objectAtIndex:1] content]];
            }
        }
        
        if (departureDeley && ![departureDeley isEqualToString:@""]) {
            [train setDepartureDelay:departureDeley];
        }
        
        NSString *departureString = [NSString stringWithFormat:@"%@ %@", [[NSRailConnection sharedInstance] normalizeString:[[[element nodesForXPath:@"vertrekdatum" error:nil] objectAtIndex:0] stringValue]], departureTimeString];
        NSString *arrivalString = [NSString stringWithFormat:@"%@ %@", [[NSRailConnection sharedInstance] normalizeString:[[[element nodesForXPath:@"aankomstdatum" error:nil] objectAtIndex:0] stringValue]], [[NSRailConnection sharedInstance] normalizeString:[[[element nodesForXPath:@"aankomst" error:nil] objectAtIndex:0] stringValue]]];
        
        NSDate *departure = [[NSRailConnection sharedInstance] dateForString:departureString];
        [train setDeparture:departure];
        [train setArrival:[[NSRailConnection sharedInstance] dateForString:arrivalString]];
        
        NSInteger diff = ([departure timeIntervalSinceReferenceDate] - [NSDate timeIntervalSinceReferenceDate]) / 60;
        if (diff > 60) {
            continue;
        }
        
        [trains addObject:train];
    }
    
    return trains;
}

@end
