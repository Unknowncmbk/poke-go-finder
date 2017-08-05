//
//  ViewController.m
//  poke-go-finder
//
//  Created by Stephen Bahr on 7/23/16.
//  Copyright © 2016 Stephen Bahr. All rights reserved.
//

#import "ViewController.h"
@import GoogleMaps;

@interface ViewController ()

@end

@implementation ViewController

// google map attributes
//GMSCameraPosition *camera;
//GMSMapView *mapView;
CGRect *rect;

double lat;
double lng;
int zoom;

// instance method
- (void)viewDidLoad {
    [super viewDidLoad];
    
    searchBar.delegate = self;
    
    [self startStandardUpdates];
    
    camera = [GMSCameraPosition alloc];
    //mapView = [[GMSMapView alloc] initWithFrame:self.view.bounds];
    mapView = [[GMSMapView alloc] initWithFrame:CGRectMake(0, 50, self.view.bounds.size.width, self.view.bounds.size.height - 75)];
    [mapView animateToZoom:12];
    
    // what does this do?
    [self.view addSubview:mapView];
    
    lat = 40.860836;
    lng = -82.32043799999997;
    zoom = 15;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)startStandardUpdates{
    NSLog(@"Start standard updates");
    
    // Create the location manager if this object does not
    // already have one.
    if (nil == locationManager)
        locationManager = [[CLLocationManager alloc] init];
    
    locationManager.delegate = self;
    locationManager.desiredAccuracy = kCLLocationAccuracyKilometer;
    
    // Set a movement threshold for new events.
    locationManager.distanceFilter = 500; // meters
    
    [locationManager startUpdatingLocation];
}

// MARK: Delegate method for CLLocationManagerDelegate

// Delegate method from the CLLocationManagerDelegate protocol.
- (void)locationManager:(CLLocationManager *)manager
     didUpdateLocations:(NSArray *)locations {
    
    NSLog(@"didUpdateLocations");
    
    // If it's a relatively recent event, turn off updates to save power.
    CLLocation* location = [locations lastObject];
    NSDate* eventDate = location.timestamp;
    NSTimeInterval howRecent = [eventDate timeIntervalSinceNow];
    
    if (abs(howRecent) < 15.0) {
        // If the event is recent, do something with it.
        NSLog(@"latitude %+.6f, longitude %+.6f\n",
              location.coordinate.latitude,
              location.coordinate.longitude);
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    NSLog(@"didFailWithError: %@", error);
    UIAlertView *errorAlert = [[UIAlertView alloc]
                               initWithTitle:@"Error" message:@"Failed to Get Your Location" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [errorAlert show];
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    isSearching = YES;
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText{
    NSLog(@"textDidChange");
    
    if ([searchVariable length] != 0){
        isSearching = YES;
    }
    else{
        isSearching = NO;
    }
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    NSLog(@"Cancel clicked");
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    NSLog(@"Search Clicked");
    
    //Perform the JSON query.
    [self searchCoordinatesForAddress:[searchBar text]];
    
    //Hide the keyboard.
    [searchBar resignFirstResponder];
}

- (void) searchCoordinatesForAddress:(NSString *)inAddress {
    NSLog(@"Searching: %@", inAddress);
    
    // TODO grab coordinates from Google GEO
    // TODO populate path with those coordinates
    
    // get location from address string using Google Geolcation
    CLLocationCoordinate2D center = [self getLocationFromAddressString:inAddress];
    lat = center.latitude;
    lng = center.longitude;
    
    // convert lat/lng from float to string
    NSString *latString = [NSString stringWithFormat:@"%1.6f", lat];
    NSString *lngString = [NSString stringWithFormat:@"%1.6f", lng];
    
    // build URL to request
    NSString *path = [NSString stringWithFormat:@"http://162.243.166.250:5000/req/%@/%@", latString, lngString];
    
    [self processPokemonMap:lat lng:lng zoom:zoom];

    // Create the request.
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:path]];
    
    // Create url connection and fire request
    NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:request delegate:self];
}

- (CLLocationCoordinate2D) getLocationFromAddressString: (NSString*) addressStr {
    
    // the escaped address to form the request URL
    double latitude = 0, longitude = 0;
    NSString *esc_addr =  [addressStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSString *req = [NSString stringWithFormat:@"https://maps.googleapis.com/maps/api/geocode/json?address=%@&key=AIzaSyDNhF_MmKX6LkvGOdmf2oQ07xK5k2JbZ5s", esc_addr];
    
    // result of google API call
    NSString *result = [NSString stringWithContentsOfURL:[NSURL URLWithString:req] encoding:NSUTF8StringEncoding error:NULL];
    
    if (result) {
        NSScanner *scanner = [NSScanner scannerWithString:result];
        if ([scanner scanUpToString:@"\"lat\" :" intoString:nil] && [scanner scanString:@"\"lat\" :" intoString:nil]) {
            [scanner scanDouble:&latitude];
            if ([scanner scanUpToString:@"\"lng\" :" intoString:nil] && [scanner scanString:@"\"lng\" :" intoString:nil]) {
                [scanner scanDouble:&longitude];
            }
        }
    }
    
    CLLocationCoordinate2D center;
    center.latitude=latitude;
    center.longitude = longitude;
    
    return center;
    
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    
    NSLog(@"didReceiveResponse");
    
    // A response has been received, this is where we initialize the instance var you created
    // so that we can append data to it in the didReceiveData method
    // Furthermore, this method is called each time there is a redirect so reinitializing it
    // also serves to clear it
    _responseData = [[NSMutableData alloc] init];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    
    NSLog(@"didReceiveData");

    // Append the new data to the instance variable you declared
    [_responseData appendData:data];
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection
                  willCacheResponse:(NSCachedURLResponse*)cachedResponse {
    NSLog(@"willCacheResponse");
    
    // Return nil to indicate not necessary to store a cached response for this connection
    return nil;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    NSLog(@"didFinishLoading");

    NSError * err = nil;
    
    // convert responseData to JSON representation of NSDictionary
    NSDictionary * res = [NSJSONSerialization JSONObjectWithData:_responseData options:NSJSONReadingMutableContainers error:&err];
    if (err) {
        NSLog(@"%@", err);
        return;
    }
    
    // only get what's in the 'result' key
    NSArray * pokemon = [res objectForKey:@"result"];
    
    // call populate map
    [self populateMap:pokemon];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    NSLog(@"didFailWithError");
    NSLog(@"Error: %@", error);
    // The request has failed for some reason!
    // Check the error var
}

- (void) processPokemonMap:(double) lat lng:(double) lng zoom:(int) zoom  {
    // process the coordinates and display the map
    
    // create new google maps camera
    camera = [GMSCameraPosition cameraWithLatitude:lat longitude:lng zoom:zoom];
    
    // create the map view
    //mapView = [GMSMapView mapWithFrame:CGRectZero camera:camera]
    [mapView clear];
    [mapView setCamera:camera];
    mapView.myLocationEnabled = YES;
    mapView.settings.scrollGestures = YES;
    mapView.settings.zoomGestures = YES;
    
    // Creates a marker in the center of the map.
    GMSMarker *marker = [[GMSMarker alloc] init];
    marker.position = CLLocationCoordinate2DMake(lat, lng);
    marker.title = @"Location";
    marker.map = mapView;
    
    [self.view addSubview:mapView];
}

- (void)populateMap:(NSArray *) pokemon_data {
    
    NSError *error;
    
    // iterate over array
    for (int i = 0; i < [pokemon_data count]; i++){
        
        // get the pokemon entry and convert to json dict
        NSString *pk_entry = [pokemon_data objectAtIndex: i];
        NSData *pk_data = [pk_entry dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *pk_json = [NSJSONSerialization JSONObjectWithData:pk_data options:NSJSONReadingAllowFragments error: &error];
        
        if ([pk_json isKindOfClass:[NSDictionary class]]){
            
            NSString *poke_id = [pk_json objectForKey: @"pokemon_id"];
            NSString *lat_str = [pk_json objectForKey: @"lat"];
            NSString *lng_str = [pk_json objectForKey: @"lng"];
            NSString *expiration = [pk_json objectForKey: @"time_left"];
            
            double lat = [lat_str doubleValue];
            double lng = [lng_str doubleValue];
            int time_left = [expiration intValue];
            
            // Creates a marker for the pokemon
            GMSMarker *marker = [[GMSMarker alloc] init];
            marker.position = CLLocationCoordinate2DMake(lat, lng);
            
            marker.title = @"Flees in";
            marker.snippet = [self timeFormatted:time_left];
            marker.icon = [UIImage imageNamed:poke_id];
            marker.map = mapView;
        }
    }

}

- (NSString *)timeFormatted:(int)totalSeconds {
    
    int seconds = totalSeconds % 60;
    int minutes = (totalSeconds / 60) % 60;
    int hours = totalSeconds / 3600;
    
    return [NSString stringWithFormat:@"%02d:%02d:%02d",hours, minutes, seconds];
}
@end
