//
//  ViewController.h
//  SamaritanF
//
//  Created by Alexander Ou on 1/31/16.
//  Copyright © 2016 ChrineApps. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <AudioToolbox/AudioServices.h>

@interface ViewController : UIViewController <CLLocationManagerDelegate, MKMapViewDelegate, NSStreamDelegate>

@property (strong, nonatomic) CLLocationManager *LocationManager;

@property (weak, nonatomic) NSInputStream *inputStream;
@property (weak, nonatomic) NSOutputStream *outputStream;
@property (strong, nonatomic) NSMutableArray *messages;


- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations;
- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error;

- (void) messageReceived:(NSString *)message;
- (void) initNetworkCommunication;

@property (weak, nonatomic) IBOutlet MKMapView *mapView;

- (IBAction)panicPressed:(id)sender;
- (IBAction)signalPressed:(id)sender;

@end

