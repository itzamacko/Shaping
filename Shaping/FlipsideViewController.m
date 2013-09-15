
//  arduinopodbox v.9.14.13
//
// Created by Tony Marchante on 9/14/13.
// Derivative of Shaping v.1.1.1 for Human Participants.
// COPYRIGHT © 2013 Oskar Pineño
// (*) Please acknowledge the source of this software: Pineño, O. (2013). ArduiPod: A Low-Cost and Open-Source Skinner Box Using an iPod Touch and an Arduino Microcontroller (Version [v.#]). [Computer software]. Hempstead, NY: Hofstra University. Retrieved [date]. Available from http:www.opineno.com.


#import "FlipsideViewController.h"

@interface FlipsideViewController ()

@end

@implementation FlipsideViewController

@synthesize trainingType, stimulusPlus, stimulusMinus, context;
@synthesize trainingTypeSegment, sPlusSegment, sMinusSegment;
@synthesize stimulusDurationLabel, ITIDurationLabel, trialsLabel;
@synthesize stimulusDurationStepper, ITIDurationStepper;

- (void)viewDidLoad
{
    [super viewDidLoad];    
    self.trainingType = @"None";
    self.stimulusPlus = @"Green";
    self.stimulusMinus = @"Red";
    self.context = @"None";
    self.stimulusDurationLabel.text = @"10";
    self.ITIDurationLabel.text = @"30";
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Actions

- (IBAction)done:(id)sender
{
    [self.delegate flipsideViewControllerDidFinish:self];
}

- (IBAction)trainingTypeSelection:(id)sender
{
    switch ([sender selectedSegmentIndex])
    {
        case kNoStimulusSegmentIndex:
            self.trainingType = @"None";
            break;
            
        case kSPlusSegmentIndex:
            self.trainingType = @"S+ only";
            break;
            
        case kSPlusSMinusSegmentIndex:
            self.trainingType = @"S+ and S-";
            break;
    }
}

- (IBAction)stimulusSelection:(id)sender
{
    if ([sender tag] == 1) // S+
    {
        switch ([sender selectedSegmentIndex])
        {
            case kGreenSegmentIndex:
                self.stimulusPlus = @"Green";
                break;
                
            case kBlueSegmentIndex:
                self.stimulusPlus = @"Red";
                break;
                
            default:
                break;
        }
    }
 
    if ([sender tag] == 0) // S-
    {
        switch ([sender selectedSegmentIndex])
        {
            case kGreenSegmentIndex:
                self.stimulusMinus = @"Green";
                break;
                
            case kBlueSegmentIndex:
                self.stimulusMinus = @"Red";
                break;
                
            default:
                break;
        }
    }
}

- (IBAction)contextSelection:(id)sender
{
    switch ([sender selectedSegmentIndex])
    {
        case kNoContextSegmentIndex:
            self.context = @"None";
            break;
                
        case kToneSegmentIndex:
            self.context = @"Tone";
            break;
                
        case kNoiseSegmentIndex:
            self.context = @"Noise";
            break;
            
        default:
            break;
    }
}


- (IBAction)stepperUpdate:(UIStepper *)sender
{
    if ([sender tag] == 0)
    {
        double seconds = [sender value];
        self.stimulusDurationLabel.text = [NSString stringWithFormat:@"%d", (int)seconds];
    }

    if ([sender tag] == 1)
    {
        double seconds = [sender value];
        self.ITIDurationLabel.text = [NSString stringWithFormat:@"%d", (int)seconds];
    }

    if ([sender tag] == 2)
    {
        double trials = [sender value];
        self.trialsLabel.text = [NSString stringWithFormat:@"%d", (int)trials];
    }
}


@end
