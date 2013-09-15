
//  arduinopodbox v.9.14.13
//
// Created by Tony Marchante on 9/14/13.
// Derivative of Shaping v.1.1.1 for Human Participants.
// COPYRIGHT © 2013 Oskar Pineño
// (*) Please acknowledge the source of this software: Pineño, O. (2013). ArduiPod: A Low-Cost and Open-Source Skinner Box Using an iPod Touch and an Arduino Microcontroller (Version [v.#]). [Computer software]. Hempstead, NY: Hofstra University. Retrieved [date]. Available from http:www.opineno.com.
#import "FlipsideViewController.h"
#import "RscMgr.h"
#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>
#import <AudioToolbox/AudioToolbox.h>

#define BUFFER_LEN 1024
#define RESPONSE_ARRAY_LEN 1000
#define PRETRAINING_TIME 20
#define TAG_NEW_CHART 0
#define TAG_TRAINING_TYPE 1
#define TAG_NUMBER_TRIALS 2
#define TAG_CURRENT_TRIAL 3
#define TAG_SPLUS 4
#define TAG_SMINUS 5
#define TAG_STIMULUS_DURATION 6
#define TAG_ITI_DURATION 7
#define TAG_CURRENT_STIMULUS 8
#define TAG_CURRENT_COLOR 9
#define TAG_RESPONSES 10
#define TAG_RESPONSE_COUNTER 11
#define TAG_TRAINING_ENDED 12


@class AsyncSocket;
@class MTMessageBroker;

@interface MainViewController : UIViewController <FlipsideViewControllerDelegate, RscMgrDelegate, MFMailComposeViewControllerDelegate, UIActionSheetDelegate, UIAlertViewDelegate, NSNetServiceDelegate>

{
    FlipsideViewController *flipside;
    
    int ITIDuration, stimulusDuration, totalNumberTrials;
    
    UIButton *startTrainingButton, *responseButton, *smileyButton;

    NSTimeInterval startTime, currentTime, elapsedTime;
    NSTimeInterval soundCycleStartTime, soundCycleCurrentTime, soundCycleElapsedTime;
    BOOL trainingInProgress, canDeliverPellet, isOnline;

    RscMgr *rscMgr;
    UInt8 rxBuffer[BUFFER_LEN];
	UInt8 txBuffer[BUFFER_LEN];
    
    int currentStimulus;
    int responses [RESPONSE_ARRAY_LEN];
    int responsesSPlus [RESPONSE_ARRAY_LEN];
    int responsesSMinus [RESPONSE_ARRAY_LEN];
    int responseCounter, trialNumber, trialNumberSPlus, trialNumberSMinus;
    
    SystemSoundID toneSoundID, noiseSoundID;
    
    NSNetService *netService;
    AsyncSocket *listeningSocket;
    AsyncSocket *connectionSocket;
    MTMessageBroker *messageBroker;
    UILabel *connectionStatusLabel;
}

@property (nonatomic, retain) FlipsideViewController *flipside;
@property (nonatomic, retain) IBOutlet UIButton *startTrainingButton;
@property (nonatomic, retain) IBOutlet UIButton *responseButton;
@property (nonatomic, retain) IBOutlet UIButton *smileyButton;
@property (nonatomic) SystemSoundID toneSoundID, noiseSoundID;

@property (nonatomic) NSNetService *netService;
@property (readwrite, retain) AsyncSocket *listeningSocket;
@property (readwrite, retain) AsyncSocket *connectionSocket;
@property (readwrite, retain) MTMessageBroker *messageBroker;
@property (nonatomic, retain) IBOutlet UILabel *connectionStatusLabel;


- (IBAction)showInfo:(id)sender;
- (IBAction)startTraining:(id)sender;
- (IBAction)sendPellet:(id)sender;
- (IBAction)sendMail:(id)sender;
- (IBAction)cleanData:(id)sender;

-(void)startService;
-(void)stopService;
-(IBAction)switchService:(id)sender;


@end
