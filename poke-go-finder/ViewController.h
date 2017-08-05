//
//  ViewController.h
//  poke-go-finder
//
//  Created by Stephen Bahr on 7/23/16.
//  Copyright © 2016 Stephen Bahr. All rights reserved.
//

#import <UIKit/UIKit.h>

@import GoogleMaps;

@interface ViewController : UIViewController<UISearchBarDelegate, NSURLConnectionDelegate, CLLocationManagerDelegate > {
    
    // for search bar
    IBOutlet UISearchBar *searchBar;
    NSString *searchVariable;
    BOOL isSearching;
    
    CLLocationManager *locationManager;
    
    // google maps attributes
    GMSCameraPosition *camera;
    GMSMapView *mapView;
    
    // for Google API request
    NSMutableData *_responseData;
}
@end

