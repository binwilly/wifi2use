//
//  TestRootViewController.m
//  WiFi2Go-ios
//
//  Created by Nicolas Ameghino on 6/4/13.
//  Copyright (c) 2013 Nicolas Ameghino. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>

#import "TestRootViewController.h"
#import "WiFi2GoServiceProtocol.h"
#import "WiFi2GoServiceFactory.h"
#import "Venue.h"
#import "VenuesListCell.h"

static NSArray *keys;

@interface TestRootViewController () <CLLocationManagerDelegate>
@property(nonatomic, strong) NSArray *data;
@property(nonatomic, strong) CLLocation *currentLocation;
@property(nonatomic, strong) CLLocationManager *locationManager;
@property(nonatomic, strong) UIBarButtonItem *locateMeButton;
@end

@implementation TestRootViewController

+(void)load {
    keys = @[@"ssid", @"password", @"venue_id"];
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        self.navigationItem.title = @"Nearby Public Wi-Fi";
        
        self.locateMeButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
                                                                            target:self
                                                                            action:@selector(loadData:)];
        
        self.navigationItem.leftBarButtonItem = self.locateMeButton;
        
        
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
        self.locationManager.delegate = self;
    }
    return self;
}

-(void) loadData:(id) sender {
    self.locateMeButton.enabled = NO;
    
    // Using real location data
    [self.locationManager startUpdatingLocation];
    
    // Using fake location data
    /*
    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(
                                                                   -34.5968823,
                                                                   -58.3722353
                                                                   );

    self.currentLocation = [[CLLocation alloc] initWithCoordinate:coordinate
                                                         altitude:0
                                               horizontalAccuracy:1
                                                 verticalAccuracy:1
                                                           course:0.0
                                                            speed:0.0
                                                        timestamp:[NSDate date]];
    [self locationManager:nil didUpdateLocations:@[self.currentLocation]];
     */
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.rowHeight = 50.0f;
    [self.tableView registerClass:NSClassFromString(@"VenuesListCell") forCellReuseIdentifier:@"Cell"];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

-(void) viewDidAppear:(BOOL)animated {
    [self loadData:nil];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.data count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    VenuesListCell *cell = (VenuesListCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    Venue *v = self.data[indexPath.row];
    
    NSDictionary *latlng = v[@"location"];
    double lat = [latlng[@"lat"] doubleValue];
    double lng = [latlng[@"lng"] doubleValue];
    
    CLLocation *location = [[CLLocation alloc] initWithLatitude:lat longitude:lng];
    CLLocationDistance distance = [location distanceFromLocation:self.currentLocation];
    
    cell.venueNameLabel.text = [v name];
    cell.detailsLabel.text = [NSString stringWithFormat:@"%.0lf m", round(distance)];
    
    if ([v hasWifi]) {
        cell.venueNameLabel.textColor = [UIColor blackColor];
        cell.venueSignalImageView.image = [UIImage imageNamed:@"signal.png"];
    } else {
        cell.venueNameLabel.textColor = [UIColor grayColor];
        cell.venueSignalImageView.image = nil;
    }
    return cell;
}

-(QRootElement *) createNewWifiForm:(Venue*) venue {
    QRootElement *root = [[QRootElement alloc] init];
    
    root.title = @"New Access Point";
    root.grouped = YES;
    
    QSection *venueDataSection = [[QSection alloc] initWithTitle:@"Venue data"];
    QLabelElement *venueNameLabel = [[QLabelElement alloc] initWithTitle:@"Name"
                                                                   Value:venue.name];
    [venueDataSection addElement:venueNameLabel];
    
    QSection *venueWifiSection = [[QSection alloc] initWithTitle:@"Wi-Fi data"];
    QEntryElement *wifiSSIDEntryElement = [[QEntryElement alloc] initWithKey:@"wifi_ssid"];
    wifiSSIDEntryElement.title = @"Wi-Fi name";
    
    QEntryElement * wifiPasswordEntryElement = [[QEntryElement alloc] initWithKey:@"wifi_password"];
    wifiPasswordEntryElement.title = @"Wi-Fi password";
    
    [venueWifiSection addElement:wifiSSIDEntryElement];
    [venueWifiSection addElement:wifiPasswordEntryElement];
    
    QSection *submitButtonSection = [[QSection alloc] init];
    submitButtonSection.footer = @"Please, do not add private-access wi-fi networks such as home or office networks";
    QButtonElement *submitButtonElement = [[QButtonElement alloc] initWithTitle:@"Submit"];
    submitButtonElement.onSelected = ^{
        
        NSString *ssid = [wifiSSIDEntryElement textValue];
        NSString *password = [wifiPasswordEntryElement textValue];
        NSString *venueId = venue[@"id"];

        
        [[WiFi2GoServiceFactory getService] addNewAccessPointForVenueID: venueId
                                                                   SSID: ssid
                                                               password: [password length] == 0 ? [NSNull null] : password];
        
        [UIAlertView showAlertViewWithTitle:@"Placeholder"
                                    message:@"Aca es donde mandamos los datos"
                          cancelButtonTitle:@"Aceptar"
                          otherButtonTitles:nil
                                    handler:^(UIAlertView *alertView, NSInteger buttonIndex) {
                                        [self.navigationController popViewControllerAnimated:YES];
                                    }];
    };
    [submitButtonSection addElement:submitButtonElement];
    
    [root addSection:venueDataSection];
    [root addSection:venueWifiSection];
    [root addSection:submitButtonSection];

    return root;
}

#pragma mark - Table view delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    Venue *venue = self.data[indexPath.row];    
    if (venue.hasWifi) {
        NSString *message = [NSString stringWithFormat:@"SSID: %@\nPassword: %@", venue.ssid, venue.password];
        [UIAlertView showAlertViewWithTitle:@"Conectate!"
                                    message:message
                          cancelButtonTitle:@"Aceptar"
                          otherButtonTitles:nil
                                    handler:^(UIAlertView *alertView, NSInteger buttonIndex) {
                                        [[UIPasteboard generalPasteboard] setString:venue.password];
                                    }];
    } else {
        QuickDialogController *form = [QuickDialogController controllerForRoot:[self createNewWifiForm:venue]];
        [self.navigationController pushViewController:form animated:YES];
    }
    
}

#pragma mark - CLLocationManager delegate
-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    if ([locations count] == 0) {
        return;
    }
    
    for (CLLocation *location in locations) {
        if (location.horizontalAccuracy < 100.0f) {
            self.currentLocation = location;
            break;
        }
    }
    
    
    
    [self.locationManager stopUpdatingLocation];
    self.locateMeButton.enabled = YES;
    
    [[WiFi2GoServiceFactory getService] queryWiFiForLatitude:self.currentLocation.coordinate.latitude
                                                   longitude:self.currentLocation.coordinate.longitude
                                             completionBlock:^(NSArray *results, NSError *error) {
                                                 if (error) {
                                                     UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                                                                     message:[error localizedDescription]
                                                                                                    delegate:nil
                                                                                           cancelButtonTitle:@"Y bueh..."
                                                                                           otherButtonTitles:nil];
                                                     [alert show];
                                                     return;
                                                 }
                                                 
                                                 
                                                 for (Venue *v in results) {
                                                     NSDictionary *latlng = v[@"location"];
                                                     double lat = [latlng[@"lat"] doubleValue];
                                                     double lng = [latlng[@"lng"] doubleValue];
                                                     
                                                     CLLocation *location = [[CLLocation alloc] initWithLatitude:lat longitude:lng];
                                                     CLLocationDistance distance = [location distanceFromLocation:self.currentLocation];
                                                     v.distanceToCurrentLocation = distance;
                                                 }
                                                 
                                                 
                                                 
                                                 self.data = [results sortedArrayUsingDescriptors:
                                                              @[[NSSortDescriptor sortDescriptorWithKey:@"distanceToCurrentLocation"
                                                                                              ascending:YES]]];
                                                 [self.tableView reloadData];
                                             }];
}

@end
