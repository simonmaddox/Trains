//
//  TrainsViewController.m
//  NSTimes
//
//  Created by Robert Dougan on 11/29/12.
//  Copyright (c) 2012 Robert Dougan. All rights reserved.
//

#import "TrainsViewController.h"

#import "Train.h"
#import "NSRailConnection.h"

#import "TrainsTableViewCell.h"

@interface TrainsViewController () {
    NSMutableArray *_objects;
    
    UILabel *titleView;
    UILabel *subtitleView;
}
@end

@implementation TrainsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self initTitleView];
        _objects = [NSMutableArray array];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Setup the pull to refresh control
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(fetchTrains:) forControlEvents:UIControlEventValueChanged];
    [self setRefreshControl:refreshControl];
}

/**
 * Sets up the custom title view which adds a subtitle and tapable navigation bar
 */
- (void)initTitleView
{
    CGRect headerTitleSubtitleFrame = CGRectMake(0, 0, 200, 44);
    UIView *_headerTitleSubtitleView = [[UILabel alloc] initWithFrame:headerTitleSubtitleFrame];
    _headerTitleSubtitleView.backgroundColor = [UIColor clearColor];
    _headerTitleSubtitleView.autoresizesSubviews = YES;
    
    CGRect titleFrame = CGRectMake(0, 4, 200, 24);
    titleView = [[UILabel alloc] initWithFrame:titleFrame];
    titleView.backgroundColor = [UIColor clearColor];
    titleView.font = [UIFont boldSystemFontOfSize:20];
    titleView.textAlignment = NSTextAlignmentCenter;
    titleView.textColor = [UIColor whiteColor];
    titleView.shadowColor = [UIColor colorWithWhite:0 alpha:.4];
    titleView.shadowOffset = CGSizeMake(0, -1);
    titleView.text = NSLocalizedString(@"Trains", @"Trains");
    titleView.adjustsFontSizeToFitWidth = YES;
    [_headerTitleSubtitleView addSubview:titleView];
    
    CGRect subtitleFrame = CGRectMake(0, 22, 200, 44-24);
    subtitleView = [[UILabel alloc] initWithFrame:subtitleFrame];
    subtitleView.backgroundColor = [UIColor clearColor];
    subtitleView.font = [UIFont systemFontOfSize:13];
    subtitleView.textAlignment = NSTextAlignmentCenter;
    subtitleView.textColor = [UIColor colorWithWhite:1 alpha:.8];
    subtitleView.shadowColor = [UIColor colorWithWhite:0 alpha:.3];
    subtitleView.shadowOffset = CGSizeMake(0, -1);
    subtitleView.text = @"Haarlem → Amsterdam";
    subtitleView.adjustsFontSizeToFitWidth = YES;
    [_headerTitleSubtitleView addSubview:subtitleView];
    
    _headerTitleSubtitleView.autoresizingMask = (UIViewAutoresizingFlexibleLeftMargin |
                                                 UIViewAutoresizingFlexibleRightMargin |
                                                 UIViewAutoresizingFlexibleTopMargin |
                                                 UIViewAutoresizingFlexibleBottomMargin);
    
    self.navigationItem.titleView = _headerTitleSubtitleView;
    
    // Tap recognizer for navigation title
    UIGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(switchStations)];
    
    [self.navigationItem.titleView setUserInteractionEnabled:YES];
    [self.navigationItem.titleView addGestureRecognizer:tapRecognizer];
}

#pragma mark - Trains

/**
 * Swaps the current stations
 */
- (void)switchStations
{
    NSRailConnection *sharedInstance = [NSRailConnection sharedInstance];
    
    if ([subtitleView.text isEqualToString:@"Haarlem → Amsterdam"]) {
        subtitleView.text = @"Amsterdam → Haarlem";
        
        [sharedInstance setTo:@"Haarlem"];
        [sharedInstance setFrom:@"Amsterdam"];
    } else {
        subtitleView.text = @"Haarlem → Amsterdam";
        
        [sharedInstance setTo:@"Amsterdam"];
        [sharedInstance setFrom:@"Haarlem"];
    }
    
    [self fetchTrains:self];
}

/**
 * Fetches the latest trains from NS.nl
 */
- (void)fetchTrains:(id)sender
{
    NSMutableArray *allTrains = [NSMutableArray array];
    
    NSRailConnection *sharedInstance = [NSRailConnection sharedInstance];
    [sharedInstance fetchWithSuccess:^(NSArray *trains) {
        [allTrains addObjectsFromArray:trains];
        
        [sharedInstance fetchMoreWithSuccess:^(NSArray *moreTrains) {
            [allTrains addObjectsFromArray:moreTrains];
            
            [self setTrains:allTrains];
        }];
    }];
}

/**
 * Updates the `_objects` array with the trains, and handles all the insert/reload/delete animations in the TableView
 */
- (void)setTrains:(NSArray *)trains
{
    [[self refreshControl] endRefreshing];
    
    [_objects removeAllObjects];
    [_objects addObjectsFromArray:trains];
    
    [[self tableView] beginUpdates];
    [[self tableView] reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
    [[self tableView] endUpdates];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _objects.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    TrainsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[TrainsTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }

    Train *train = _objects[indexPath.row];
    [cell setTrain:train];

    return (UITableViewCell *)cell;
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 64.f;
}

@end
