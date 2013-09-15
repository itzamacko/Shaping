
//  arduinopodbox v.9.14.13
//
// Created by Tony Marchante on 9/14/13.
// Derivative of Shaping v.1.1.1 for Human Participants.
// COPYRIGHT © 2013 Oskar Pineño
// (*) Please acknowledge the source of this software: Pineño, O. (2013). ArduiPod: A Low-Cost and Open-Source Skinner Box Using an iPod Touch and an Arduino Microcontroller (Version [v.#]). [Computer software]. Hempstead, NY: Hofstra University. Retrieved [date]. Available from http:www.opineno.com.

#import <UIKit/UIKit.h>

#define kNoStimulusSegmentIndex 0
#define kSPlusSegmentIndex 1
#define kSPlusSMinusSegmentIndex 2

#define kGreenSegmentIndex 0
#define kBlueSegmentIndex 1

#define kNoContextSegmentIndex 0
#define kToneSegmentIndex 1
#define kNoiseSegmentIndex 2

@class FlipsideViewController;

@protocol FlipsideViewControllerDelegate
- (void)flipsideViewControllerDidFinish:(FlipsideViewController *)controller;
@end

@interface FlipsideViewController : UIViewController
{
    NSString *trainingType, *stimulusPlus, *stimulusMinus, *context;
    UISegmentedControl *trainingTypeSegment, *sPlusSegment, *sMinusSegment;
    UILabel *stimulusDurationLabel, *ITIDurationLabel, *trialsLabel;
    UIStepper *stimulusDurationStepper, *ITIDurationStepper;

}

@property (nonatomic, retain) NSString *trainingType, *stimulusPlus, *stimulusMinus, *context;
@property (nonatomic, retain) IBOutlet UISegmentedControl *trainingTypeSegment, *sPlusSegment, *sMinusSegment;
@property (nonatomic, retain) IBOutlet UILabel *stimulusDurationLabel, *ITIDurationLabel, *trialsLabel;
@property (nonatomic, retain) IBOutlet UIStepper *stimulusDurationStepper, *ITIDurationStepper;
@property (strong, nonatomic) id <FlipsideViewControllerDelegate> delegate;

- (IBAction)done:(id)sender;
- (IBAction)trainingTypeSelection:(id)sender;
- (IBAction)stimulusSelection:(id)sender;
- (IBAction)contextSelection:(id)sender;
- (IBAction)stepperUpdate:(id)sender;

@end
