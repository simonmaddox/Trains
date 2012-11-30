//
//  NSRailConnection.m
//  NSTimes
//
//  Created by Robert Dougan on 11/29/12.
//  Copyright (c) 2012 Robert Dougan. All rights reserved.
//

#import "NSRailConnection.h"

#import "Train.h"

#import "DDXML.h"
#import "AFNetworking.h"
#import "TFHpple.h"

@implementation NSRailConnection

@synthesize from = _from, to = _to;

static NSRailConnection *sharedInstance = nil;

+ (NSRailConnection *)sharedInstance {
    if (!sharedInstance) {
        sharedInstance = [[NSRailConnection alloc] init];
        [sharedInstance setFrom:@"Haarlem"];
        [sharedInstance setTo:@"Amsterdam"];
    }
    
    return sharedInstance;
}

#pragma mark - NSURLRequests

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

#pragma mark - Fetching

- (void)fetchWithSuccess:(void (^)(NSArray *trains))success
{
    NSURLRequest *urlRequest = [self requestWithFrom:self.from to:self.to];
    
    AFHTTPRequestOperation *requestOperation = [[AFHTTPRequestOperation alloc] initWithRequest:urlRequest];
    [requestOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        TFHpple *document = [[TFHpple alloc] initWithHTMLData:responseObject];
        NSArray *elements = [document searchWithXPathQuery:@"//table[@class='time-table']/tbody/tr"];
        
        success([self trainsWithHTMLElements:elements]);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"failure:\n\n%@", error);
    }];
    
    [requestOperation start];
}

- (void)fetchMoreWithSuccess:(void (^)(NSArray *trains))success
{
    NSURLRequest *urlRequest = [self requestForMoreWithFrom:self.from to:self.to];
    
    AFHTTPRequestOperation *requestOperation = [[AFHTTPRequestOperation alloc] initWithRequest:urlRequest];
    [requestOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        success([self trainsWithXMLData:responseObject]);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"failure:\n\n%@", error);
    }];
    
    [requestOperation start];
}

#pragma mark - Element searching

- (NSArray *)trainsWithHTMLElements:(NSArray *)elements {
    NSMutableArray *trains = [NSMutableArray array];
    BOOL foundSelected = NO;
    
    for (TFHppleElement *element in elements) {
        Train *train = [[Train alloc] init];
        
        // Check if something has been selected
        if (!foundSelected) {
            if ([[element objectForKey:@"class"] isEqualToString:@"selected"]) {
                foundSelected = YES;
            } else {
                continue;
            }
        }
        
        // Simple fields
        [train setPlatform:[self normalizeString:[[element firstChildWithClassName:@"platform"] text]]];
        [train setTravelTime:[self normalizeString:[[element firstChildWithClassName:@"travel-time"] text]]];
        
        // Dates
        NSString *departureString = [NSString stringWithFormat:@"%@ %@", [self normalizeString:[[element firstChildWithClassName:@"departure-date"] text]], [self normalizeString:[[element firstChildWithClassName:@"departure"] text]]];
        NSString *arrivalString = [NSString stringWithFormat:@"%@ %@", [self normalizeString:[[element firstChildWithClassName:@"arrival-date"] text]], [self normalizeString:[[element firstChildWithClassName:@"arrival"] text]]];
        
        [train setDeparture:[self dateForString:departureString]];
        [train setArrival:[self dateForString:arrivalString]];
        
        // Delays
        NSArray *departureDelay = [[element firstChildWithClassName:@"departure"] childrenWithTagName:@"strong"];
        if (departureDelay && [departureDelay count] > 0) {
            [train setDepartureDelay:[[departureDelay objectAtIndex:0] text]];
        }
        
        NSArray *arrivalDelay = [[element firstChildWithClassName:@"arrival"] childrenWithTagName:@"strong"];
        if (arrivalDelay && [arrivalDelay count] > 0) {
            [train setArrivalDelay:[[arrivalDelay objectAtIndex:0] text]];
        }
        
        [trains addObject:train];
    }
    
    return trains;
}

- (NSArray *)trainsWithXMLData:(NSData *)data {
    NSMutableArray *trains = [NSMutableArray array];
    
    DDXMLDocument *document = [[DDXMLDocument alloc] initWithData:data options:0 error:nil];
    NSArray *elements = [document nodesForXPath:@"//reistijden/reizen/reis" error:nil];
    
    for (DDXMLElement *element in elements) {
        Train *train = [[Train alloc] init];
    
        // Simple fields
        [train setPlatform:[self normalizeString:[[[element nodesForXPath:@"aankomstspoor" error:nil] objectAtIndex:0] stringValue]]];
        [train setTravelTime:[self normalizeString:[[[element nodesForXPath:@"reistijd" error:nil] objectAtIndex:0] stringValue]]];

        // Dates
        NSString *departureString = [NSString stringWithFormat:@"%@ %@", [self normalizeString:[[[element nodesForXPath:@"vertrekdatum" error:nil] objectAtIndex:0] stringValue]], [self normalizeString:[[[element nodesForXPath:@"vertrek" error:nil] objectAtIndex:0] stringValue]]];
        NSString *arrivalString = [NSString stringWithFormat:@"%@ %@", [self normalizeString:[[[element nodesForXPath:@"aankomstdatum" error:nil] objectAtIndex:0] stringValue]], [self normalizeString:[[[element nodesForXPath:@"aankomst" error:nil] objectAtIndex:0] stringValue]]];

        NSDate *departure = [self dateForString:departureString];
        [train setDeparture:departure];
        [train setArrival:[self dateForString:arrivalString]];
        
        NSInteger diff = ([departure timeIntervalSinceReferenceDate] - [NSDate timeIntervalSinceReferenceDate]) / 60;
        if (diff > 60) {
            continue;
        }

        // Delays
        NSString *arrivalDelay = [self normalizeString:[[[element nodesForXPath:@"overstap" error:nil] objectAtIndex:0] stringValue]];
        if (arrivalDelay && ![arrivalDelay isEqualToString:@""]) {
            [train setArrivalDelay:arrivalDelay];
        }
        
        [trains addObject:train];
    }
    
    return trains;
}

#pragma mark - Helpers

- (NSDate *)dateForString:(NSString *)string
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm"];
    [dateFormatter setTimeZone:[NSTimeZone systemTimeZone]];
    
    NSDate *sourceDate = [dateFormatter dateFromString:string];
    
    return sourceDate;
}

- (NSString *)normalizeString:(NSString *)string
{
    return [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

@end
