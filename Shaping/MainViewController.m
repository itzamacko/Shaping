
//  arduinopodbox v.9.14.13
//
// Created by Tony Marchante on 9/14/13.
// Derivative of Shaping v.1.1.1 for Human Participants.
// COPYRIGHT © 2013 Oskar Pineño
// (*) Please acknowledge the source of this software: Pineño, O. (2013). ArduiPod: A Low-Cost and Open-Source Skinner Box Using an iPod Touch and an Arduino Microcontroller (Version [v.#]). [Computer software]. Hempstead, NY: Hofstra University. Retrieved [date]. Available from http:www.opineno.com.


#import "MainViewController.h"
#import "AsyncSocket.h"
#import "MTMessageBroker.h"
#import "MTMessage.h"

@interface MainViewController ()

@end

@implementation MainViewController

@synthesize flipside;
@synthesize startTrainingButton, responseButton, smileyButton;
@synthesize toneSoundID, noiseSoundID;

@synthesize netService;
@synthesize listeningSocket;
@synthesize connectionSocket;
@synthesize messageBroker;
@synthesize connectionStatusLabel;



#pragma mark - IBActions

-(IBAction)switchService:(UISwitch *)sender
{
    if ([sender isOn])
    {
        isOnline = YES;
        [self startService];
        self.connectionStatusLabel.text = @"Online";
        self.connectionStatusLabel.textColor = [UIColor greenColor];
    }
    else
    {
        isOnline = NO;
        [self stopService];
        self.connectionStatusLabel.text = @"Offline";
        self.connectionStatusLabel.textColor = [UIColor redColor];
    }
}


-(IBAction)startTraining:(id)sender
{
    if (!trainingInProgress)
    {
        trainingInProgress = YES;
        [self resetCounters];
        ITIDuration = [self.flipside.ITIDurationLabel.text integerValue];
        stimulusDuration = [self.flipside.stimulusDurationLabel.text integerValue];
        totalNumberTrials = [self.flipside.trialsLabel.text integerValue];
    }
    
    else
    {
        trainingInProgress = NO;
        if (isOnline)
            [self trainingEnded];
        [self saveDataToDisk];
    }
    
    if (trainingInProgress)
        startTrainingButton.titleLabel.text = @"Stop training session";
    else
        startTrainingButton.titleLabel.text = @"Start training session";
    
    if ((trainingInProgress) && (trialNumber < totalNumberTrials))
    {
        if (isOnline)
        {
            [self sendSummaryToChart];
            [self requestNewChart];
        }
        [self timingPreTraining];
    }
    
    if (trainingInProgress)
        [self startContext];
    else
        [self endContext];
    
    while ((trainingInProgress) && (trialNumber < totalNumberTrials))
        [self trial];
    
    if (trialNumber == totalNumberTrials)
    {
        trainingInProgress = NO;
        if (isOnline)
            [self trainingEnded];
        [self endContext];
        [self saveDataToDisk];
        // The following code will send a signal to the Arduino, which will blink the LED to announce the end of  training
        txBuffer[0] = 0;
        [rscMgr write:txBuffer length:1];
    }
}


- (IBAction)sendPellet:(id)sender
{
    if (canDeliverPellet)
    {
        txBuffer[0] = 1;
        [rscMgr write:txBuffer length:1];
        
        self.smileyButton.hidden = NO;
        [self performSelector:@selector(clearSmiley) withObject:nil afterDelay:1];
    }
    responseCounter++;
    if (isOnline)
        [self sendDataToCounter:responseCounter];
}

- (void)clearSmiley
{
    self.smileyButton.hidden = YES;
}

- (IBAction)sendMail:(id)sender
{
    if ([MFMailComposeViewController canSendMail])
    {
        //Creates path for txt file
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *filePath = [documentsDirectory stringByAppendingPathComponent:@"data.txt"];
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:filePath])
        {
            NSData *data = [NSData dataWithContentsOfFile:filePath];
            NSArray *emailArray = [NSArray arrayWithObject:@"myemail@address.com"];
            MFMailComposeViewController *mailController = [[MFMailComposeViewController alloc] init];
            [mailController setToRecipients:emailArray];
            [mailController setSubject:@"Shaping App Data"];
            [mailController setMessageBody:@"Attached are the results from your Shaping App" isHTML:NO];
            [mailController addAttachmentData:data mimeType:@"text/plain" fileName:@"data.txt"];
            [mailController setMailComposeDelegate:self];
            [self presentModalViewController:mailController animated:YES];
        }
        
        else
        {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"NO FILE"
                                                                message:@"The data file (data.txt) must exist in order to send an email with the data. This file will be created automatically after you run an experimental session."
                                                               delegate:self
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil, nil];
            [alertView show];
        }
    }
}


-(void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
    [self dismissModalViewControllerAnimated:YES];
}


- (IBAction)cleanData:(id)sender
{
    UIActionSheet *actionSheet = [[UIActionSheet alloc]
                                  initWithTitle:@"Delete saved results?"
                                  delegate:self
                                  cancelButtonTitle:@"Cancel"
                                  destructiveButtonTitle:@"Delete"
                                  otherButtonTitles:nil];
    [actionSheet showInView:self.view];
}


- (void) actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0)
    {
        //Creates txt file for saving data later on...
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *filePath = [documentsDirectory stringByAppendingPathComponent:@"data.txt"];
        
        //    if (![[NSFileManager defaultManager] fileExistsAtPath:filePath])
        [[NSFileManager defaultManager] createFileAtPath:filePath contents:nil attributes:nil];        
    }
}


# pragma mark - Methods for the experimental treatment

- (void) resetCounters
{
    responseCounter = 0;
    trialNumber = 0;
    trialNumberSPlus = 0;
    trialNumberSMinus = 0;
}


- (void)trial
{
    if ([self.flipside.trainingType isEqualToString:@"None"])
    {
        [self presentCue];
        [self timingCue];
        [self hideCue];
    }
    
    else
    {
        [self timingITI];
        [self presentCue];
        [self timingCue];
        [self hideCue];
    }
}


- (void) selectTrainingType
{
    if ([self.flipside.trainingType isEqualToString:@"None"])
    {
        [responseButton setBackgroundColor:[UIColor clearColor]];
        canDeliverPellet = YES;
    }
    
    else if ([self.flipside.trainingType isEqualToString:@"S+ only"])
    {
        [self selectStimulusTypeSPlus];
        if (isOnline)
            [self sendCurrentStimulusToChart:@"S+"];
        canDeliverPellet = YES;
    }
    
    else if ([self.flipside.trainingType isEqualToString:@"S+ and S-"])
    {
        currentStimulus = arc4random() % 2;
        if (currentStimulus == 1)
        {
            [self selectStimulusTypeSPlus];
            if (isOnline)
                [self sendCurrentStimulusToChart:@"S+"];
            canDeliverPellet = YES;
        }
        else if (currentStimulus == 0)
        {
            [self selectStimulusTypeSMinus];
            if (isOnline)
                [self sendCurrentStimulusToChart:@"S-"];
            canDeliverPellet = NO;
        }
    }
}


- (void)selectStimulusTypeSPlus
{
    if ([self.flipside.stimulusPlus isEqualToString:@"Green"])
    {
        [responseButton setBackgroundColor:[UIColor greenColor]];
        if (isOnline)
            [self sendCurrentColorToChart:@"Green"];
    }
    else if ([self.flipside.stimulusPlus isEqualToString:@"Red"])
    {
        [responseButton setBackgroundColor:[UIColor redColor]];
        if (isOnline)
            [self sendCurrentColorToChart:@"Red"];
    }
}


- (void)selectStimulusTypeSMinus
{
    if ([self.flipside.stimulusMinus isEqualToString:@"Green"])
    {
        [responseButton setBackgroundColor:[UIColor greenColor]];
        if (isOnline)
            [self sendCurrentColorToChart:@"Green"];
    }
    else if ([self.flipside.stimulusMinus isEqualToString:@"Red"])
    {
        [responseButton setBackgroundColor:[UIColor redColor]];
        if (isOnline)
            [self sendCurrentColorToChart:@"Red"];
    }
}


- (void)startContext
{
    dispatch_async(dispatch_get_global_queue(0, 0),
    ^{
        [self playSound];
        [self resetSoundCycleElapsedTime];
        
        while (trainingInProgress)
        {
            [self updateSoundCycleElapsedTime];
            if (soundCycleElapsedTime > 29.925) // Sound clip duration is 30.00. Doing this prevents gap.
            {
                [self playSound];
                [self resetSoundCycleElapsedTime];
            }
        }
    });
}


- (void) playSound
{
    if ([self.flipside.context isEqualToString:@"Tone"])
    {
        NSString *path = [[NSBundle mainBundle] pathForResource:@"tone" ofType:@"wav"];
        AudioServicesCreateSystemSoundID((__bridge CFURLRef) [NSURL fileURLWithPath:path], &toneSoundID);
        AudioServicesPlaySystemSound (toneSoundID);
    }
    else if ([self.flipside.context isEqualToString:@"Noise"])
    {
        NSString *path = [[NSBundle mainBundle] pathForResource:@"noise" ofType:@"wav"];
        AudioServicesCreateSystemSoundID((__bridge CFURLRef) [NSURL fileURLWithPath:path], &noiseSoundID);
        AudioServicesPlaySystemSound (noiseSoundID);
    }
}


- (void)endContext
{
    if ([self.flipside.context isEqualToString:@"Tone"])
        AudioServicesDisposeSystemSoundID (toneSoundID);
    else if ([self.flipside.context isEqualToString:@"Noise"])
        AudioServicesDisposeSystemSoundID (noiseSoundID);
}


- (void)presentCue
{
    [responseButton setHidden:NO];
    [responseButton setEnabled:YES];
    [self selectTrainingType];
    if (isOnline)
        [self sendCurrentTrialToChart:trialNumber+1];
}


- (void)hideCue
{
    [responseButton setHidden:YES];
    [responseButton setEnabled:NO];
    if (isOnline)
    {
        [self sendDataToChart:responseCounter];
        [self sendCurrentColorToChart:@"Hide"];
    }
    [self saveTrialData];
}


- (void)resetElapsedTime
{
    startTime = [NSDate timeIntervalSinceReferenceDate];
    currentTime = [NSDate timeIntervalSinceReferenceDate];
    elapsedTime = currentTime - startTime;
}


- (void)updateElapsedTime
{
    currentTime = [NSDate timeIntervalSinceReferenceDate];
    elapsedTime = currentTime - startTime;
}


- (void)resetSoundCycleElapsedTime
{
    soundCycleStartTime = [NSDate timeIntervalSinceReferenceDate];
    soundCycleCurrentTime = [NSDate timeIntervalSinceReferenceDate];
    soundCycleElapsedTime = soundCycleCurrentTime - soundCycleStartTime;
}


- (void)updateSoundCycleElapsedTime
{
    soundCycleCurrentTime = [NSDate timeIntervalSinceReferenceDate];
    soundCycleElapsedTime = soundCycleCurrentTime - soundCycleStartTime;
}


- (void)timingPreTraining
{
    @autoreleasepool
    {
        [self resetElapsedTime];
        while ((trainingInProgress) && (elapsedTime < PRETRAINING_TIME))
        {
            [self updateElapsedTime];
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate date]];
        }
    }
}


- (void)timingITI
{
    @autoreleasepool
    {
        [self resetElapsedTime];
        while ((trainingInProgress) && (elapsedTime < ITIDuration))
        {
            [self updateElapsedTime];
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate date]];
        }
    }
}


- (void)timingCue
{
    @autoreleasepool
    {
        [self resetElapsedTime];
        while ((trainingInProgress) && (elapsedTime < stimulusDuration))
        {
            [self updateElapsedTime];
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate date]];
        }
    }
}



#pragma mark - Methods for registering subject's responses

- (void) saveTrialData
{
    if ([self.flipside.trainingType isEqualToString:@"None"])
    {
        responses [trialNumber] = responseCounter;
        trialNumber++;
    }
    
    else if ([self.flipside.trainingType isEqualToString:@"S+ only"])
    {
        responsesSPlus [trialNumberSPlus] = responseCounter;
        trialNumberSPlus++;
        trialNumber++;
        if (isOnline)
            [self sendCurrentStimulusToChart:@""];
    }
    
    else if ([self.flipside.trainingType isEqualToString:@"S+ and S-"])
    {
        if (currentStimulus == 1)
        {
            responsesSPlus [trialNumberSPlus] = responseCounter;
            trialNumberSPlus++;
            trialNumber++;
        }
        else if (currentStimulus == 0)
        {
            responsesSMinus [trialNumberSMinus] = responseCounter;
            trialNumberSMinus++;
            trialNumber++;
        }
        if (isOnline)
            [self sendCurrentStimulusToChart:@""];
    }
    responseCounter = 0;
}


- (void) requestNewChart
{
    NSData *data = [@"" dataUsingEncoding:NSUTF8StringEncoding];
    MTMessage *newMessage = [[MTMessage alloc] init];
    newMessage.tag = TAG_NEW_CHART;
    newMessage.dataContent = data;
    [self.messageBroker sendMessage:newMessage];
}


- (void) trainingEnded
{
    NSData *data = [@"" dataUsingEncoding:NSUTF8StringEncoding];
    MTMessage *newMessage = [[MTMessage alloc] init];
    newMessage.tag = TAG_TRAINING_ENDED;
    newMessage.dataContent = data;
    [self.messageBroker sendMessage:newMessage];
}


- (void) sendDataToChart:(int)anInt
{
    NSString *stringInt = [NSString stringWithFormat:@"%d", anInt];
    NSData *data = [stringInt dataUsingEncoding:NSUTF8StringEncoding];
    MTMessage *newMessage = [[MTMessage alloc] init];
    newMessage.tag = TAG_RESPONSES;
    newMessage.dataContent = data;
    [self.messageBroker sendMessage:newMessage];
}


- (void) sendDataToCounter:(int)anInt
{
    NSString *stringInt = [NSString stringWithFormat:@"%d", anInt];
    NSData *data = [stringInt dataUsingEncoding:NSUTF8StringEncoding];
    MTMessage *newMessage = [[MTMessage alloc] init];
    newMessage.tag = TAG_RESPONSE_COUNTER;
    newMessage.dataContent = data;
    [self.messageBroker sendMessage:newMessage];
}


- (void) sendCurrentTrialToChart:(int)anInt
{
    NSString *stringInt = [NSString stringWithFormat:@"%d", anInt];
    NSData *data = [stringInt dataUsingEncoding:NSUTF8StringEncoding];
    MTMessage *newMessage = [[MTMessage alloc] init];
    newMessage.tag = TAG_CURRENT_TRIAL;
    newMessage.dataContent = data;
    [self.messageBroker sendMessage:newMessage];
}


- (void) sendCurrentColorToChart:(NSString *)string
{
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    MTMessage *newMessage = [[MTMessage alloc] init];
    newMessage.tag = TAG_CURRENT_COLOR;
    newMessage.dataContent = data;
    [self.messageBroker sendMessage:newMessage];
}


- (void) sendCurrentStimulusToChart:(NSString *)string
{
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    MTMessage *newMessage = [[MTMessage alloc] init];
    newMessage.tag = TAG_CURRENT_STIMULUS;
    newMessage.dataContent = data;
    [self.messageBroker sendMessage:newMessage];
}


- (void) sendSummaryToChart
{
    //Training type
    NSString *string = [NSString stringWithFormat:@"Training type: %@", self.flipside.trainingType];
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    MTMessage *newMessage = [[MTMessage alloc] init];
    newMessage.tag = TAG_TRAINING_TYPE;
    newMessage.dataContent = data;
    [self.messageBroker sendMessage:newMessage];

    //Number trials
    string = [NSString stringWithFormat:@"Trials: %@", self.flipside.trialsLabel.text];
    data = [string dataUsingEncoding:NSUTF8StringEncoding];
    newMessage.tag = TAG_NUMBER_TRIALS;
    newMessage.dataContent = data;
    [self.messageBroker sendMessage:newMessage];

    //Stimuli
    if ([self.flipside.trainingType isEqualToString:@"None"])
    {
        string = [NSString stringWithFormat:@"S+: N/A"];
        data = [string dataUsingEncoding:NSUTF8StringEncoding];
        newMessage.tag = TAG_SPLUS;
        newMessage.dataContent = data;
        [self.messageBroker sendMessage:newMessage];
        
        string = [NSString stringWithFormat:@"S-: N/A"];
        data = [string dataUsingEncoding:NSUTF8StringEncoding];
        newMessage.tag = TAG_SMINUS;
        newMessage.dataContent = data;
        [self.messageBroker sendMessage:newMessage];
    }
    else if ([self.flipside.trainingType isEqualToString:@"S+ only"])
    {
        string = [NSString stringWithFormat:@"S+: %@", self.flipside.stimulusPlus];
        data = [string dataUsingEncoding:NSUTF8StringEncoding];
        newMessage.tag = TAG_SPLUS;
        newMessage.dataContent = data;
        [self.messageBroker sendMessage:newMessage];
        
        string = [NSString stringWithFormat:@"S-: N/A"];
        data = [string dataUsingEncoding:NSUTF8StringEncoding];
        newMessage.tag = TAG_SMINUS;
        newMessage.dataContent = data;
        [self.messageBroker sendMessage:newMessage];
    }
    else if ([self.flipside.trainingType isEqualToString:@"S+ and S-"])
    {
        string = [NSString stringWithFormat:@"S+: %@", self.flipside.stimulusPlus];
        data = [string dataUsingEncoding:NSUTF8StringEncoding];
        newMessage.tag = TAG_SPLUS;
        newMessage.dataContent = data;
        [self.messageBroker sendMessage:newMessage];

        string = [NSString stringWithFormat:@"S-: %@", self.flipside.stimulusMinus];
        data = [string dataUsingEncoding:NSUTF8StringEncoding];
        newMessage.tag = TAG_SMINUS;
        newMessage.dataContent = data;
        [self.messageBroker sendMessage:newMessage];
    }

    //Stimulus duration
    string = [NSString stringWithFormat:@"Stimulus duration: %@ s", self.flipside.stimulusDurationLabel.text];
    data = [string dataUsingEncoding:NSUTF8StringEncoding];
    newMessage.tag = TAG_STIMULUS_DURATION;
    newMessage.dataContent = data;
    [self.messageBroker sendMessage:newMessage];

    //ITI duration
    string = [NSString stringWithFormat:@"ITI duration: %@ s", self.flipside.ITIDurationLabel.text];
    data = [string dataUsingEncoding:NSUTF8StringEncoding];
    newMessage.tag = TAG_ITI_DURATION;
    newMessage.dataContent = data;
    [self.messageBroker sendMessage:newMessage];
}


- (void) saveDataToDisk
{
    //Creates path for txt file
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:@"data.txt"];
    
    //Creates file handler
    NSFileHandle *fileHandler = [NSFileHandle fileHandleForUpdatingAtPath:filePath];
    [fileHandler seekToEndOfFile];
    
    //Saves date with format
    NSDate *date = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    [dateFormatter setDateStyle:NSDateFormatterShortStyle];
    NSString *dateString = [NSString stringWithFormat:@"Recorded on: %@\n\n", [dateFormatter stringFromDate:date]];
    [fileHandler writeData:[dateString dataUsingEncoding:NSUTF8StringEncoding]];
    
    //Saves training type
    if ([self.flipside.trainingType isEqualToString:@"None"])
    {
        [fileHandler writeData:[@"Training type: No discriminative stimulus\n" dataUsingEncoding:NSUTF8StringEncoding]];
        NSString *sDuration = [NSString stringWithFormat:@"Response register cycle duration: %d s\n\n", stimulusDuration];
        [fileHandler writeData:[sDuration dataUsingEncoding:NSUTF8StringEncoding]];
    }
    
    if (![self.flipside.trainingType isEqualToString:@"None"])
    {
        NSString *trainingType = [NSString stringWithFormat:@"Training type: %@\n", self.flipside.trainingType];
        [fileHandler writeData:[trainingType dataUsingEncoding:NSUTF8StringEncoding]];
        NSString *sDuration = [NSString stringWithFormat:@"Stimulus duration: %d s\n", stimulusDuration];
        [fileHandler writeData:[sDuration dataUsingEncoding:NSUTF8StringEncoding]];
        NSString *intervalDuration = [NSString stringWithFormat:@"ITI duration: %d s\n\n", ITIDuration];
        [fileHandler writeData:[intervalDuration dataUsingEncoding:NSUTF8StringEncoding]];
    }
    
    //Saves context type
    NSString *contextType = [NSString stringWithFormat:@"Context used: %@\n\n", self.flipside.context];
    [fileHandler writeData:[contextType dataUsingEncoding:NSUTF8StringEncoding]];
    
    //Saves number of trials
    NSString *totalNumberOfTrials = [NSString stringWithFormat:@"Number of trials: %d\n", totalNumberTrials];
    [fileHandler writeData:[totalNumberOfTrials dataUsingEncoding:NSUTF8StringEncoding]];
    if (trialNumber < totalNumberTrials)
    {
        NSString *interruption = [NSString stringWithFormat:@"Training interrupted on Trial %d\n\n", trialNumber];
        [fileHandler writeData:[interruption dataUsingEncoding:NSUTF8StringEncoding]];
    }
    else
    {
        [fileHandler writeData:[@"Training completed\n\n" dataUsingEncoding:NSUTF8StringEncoding]];
    }

    //Saves responses with no S (Option '0')
    if ([self.flipside.trainingType isEqualToString:@"None"])
    {
        NSMutableString *results = [NSMutableString string];
        for (int i=0; i<totalNumberTrials; i++)
            [results appendFormat:@"%d, ", responses[i]];
        [fileHandler writeData:[@"Results:\n" dataUsingEncoding:NSUTF8StringEncoding]];
        [fileHandler writeData:[results dataUsingEncoding:NSUTF8StringEncoding]];
        [fileHandler writeData:[@"\n\n" dataUsingEncoding:NSUTF8StringEncoding]];
    }
    
    //Saves responses to S+ (Options 'S+' and 'S+ / S-')
    if (([self.flipside.trainingType isEqualToString:@"S+ only"]) ||
        ([self.flipside.trainingType isEqualToString:@"S+ and S-"]))
    {
        NSString *stimulusPlusColor = [NSString stringWithFormat:@"S+ color: %@\n", self.flipside.stimulusPlus];
        [fileHandler writeData:[stimulusPlusColor dataUsingEncoding:NSUTF8StringEncoding]];
        NSMutableString *resultsSPlus = [NSMutableString string];
        for (int i=0; i<totalNumberTrials; i++)
            [resultsSPlus appendFormat:@"%d, ", responsesSPlus[i]];
        [fileHandler writeData:[@"Results S+:\n" dataUsingEncoding:NSUTF8StringEncoding]];
        [fileHandler writeData:[resultsSPlus dataUsingEncoding:NSUTF8StringEncoding]];
        [fileHandler writeData:[@"\n\n" dataUsingEncoding:NSUTF8StringEncoding]];
    }
    
    //Saves responses to S- ( (Option 'S+ / S-'))
    if ([self.flipside.trainingType isEqualToString:@"S+ and S-"])
    {
        NSString *stimulusMinusColor = [NSString stringWithFormat:@"S- color: %@\n", self.flipside.stimulusMinus];
        [fileHandler writeData:[stimulusMinusColor dataUsingEncoding:NSUTF8StringEncoding]];
        NSMutableString *resultsSMinus = [NSMutableString string];
        for (int i=0; i<totalNumberTrials; i++)
            [resultsSMinus appendFormat:@"%d, ", responsesSMinus[i]];
        [fileHandler writeData:[@"Results S-:\n" dataUsingEncoding:NSUTF8StringEncoding]];
        [fileHandler writeData:[resultsSMinus dataUsingEncoding:NSUTF8StringEncoding]];
        [fileHandler writeData:[@"\n\n" dataUsingEncoding:NSUTF8StringEncoding]];
    }
    
    //Closes file
    [fileHandler writeData:[@"\n------------------------------------\n\n\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [fileHandler closeFile];
    
    [self cleanResponseArrays];
}


- (void) cleanResponseArrays
{
    for (int i=0; i<RESPONSE_ARRAY_LEN; i++)
    {
        responses[i]=0;
        responsesSPlus[i]=0;
        responsesSMinus[i]=0;
    }
}


#pragma mark - View controller methods

- (void)viewDidLoad
{
    [super viewDidLoad];
    rscMgr = [[RscMgr alloc] init];
	[rscMgr setDelegate:self];
    srand((int)[NSDate date]);  //    srand(time(0));
    trainingInProgress = NO;
    self.startTrainingButton.enabled = NO;
    self.responseButton.enabled = NO;
    self.smileyButton.hidden = YES;
    
    //Creates txt file for saving data later on...
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:@"data.txt"];

    if (![[NSFileManager defaultManager] fileExistsAtPath:filePath])
        [[NSFileManager defaultManager] createFileAtPath:filePath contents:nil attributes:nil];
}


- (void)viewDidUnload
{
    [super viewDidUnload];
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:YES];
    self.responseButton.enabled = NO;
    self.smileyButton.hidden = YES;
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


#pragma mark - Flipside View

- (void)flipsideViewControllerDidFinish:(FlipsideViewController *)flipside
{
    [self dismissModalViewControllerAnimated:YES];
    self.startTrainingButton.enabled = YES;
}


- (IBAction)showInfo:(id)sender
{
    trainingInProgress = NO;
    
    if (!self.flipside)
    {
        self.flipside = [[FlipsideViewController alloc] initWithNibName:@"FlipsideViewController" bundle:nil];
        self.flipside.delegate = self;
        self.flipside.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    }
    
    [self presentModalViewController:self.flipside animated:YES];
}



#pragma mark - RscMgrDelegate methods (to connect to Arduino via RS-232 cable)

- (void) cableConnected:(NSString *)protocol
{
    [rscMgr setBaud:9600];
	[rscMgr open];
}


- (void) cableDisconnected
{
}


- (void) portStatusChanged
{
}


- (void) readBytesAvailable:(UInt32)length
{
    [rscMgr read:rxBuffer length:length];
    
    NSString *string = nil;
    for(int i = 0;i < length;++i)
    {
        if ( string )
        {
            string =  [NSString stringWithFormat:@"%@%c", string, rxBuffer[i]];
        }
        else
        {
            string =  [NSString stringWithFormat:@"%c", rxBuffer[i]];
        }
    }
}


- (BOOL) rscMessageReceived:(UInt8 *)msg TotalLength:(int)len
{
    return FALSE;
}


- (void) didReceivePortConfig
{
}


#pragma mark - Network Connection Methods

-(void)startService
{
    // Start listening socket
    NSError *error;
    self.listeningSocket = [[AsyncSocket alloc] initWithDelegate:self];
    if (![self.listeningSocket acceptOnPort:0 error:&error])
    {
        NSLog(@"Failed to create listening socket");
        return;
    }
    
    // Advertise service with bonjour
    NSString *serviceName = [NSString stringWithFormat:@"ArduiPod: %@", [[NSProcessInfo processInfo] hostName]];
    netService = [[NSNetService alloc] initWithDomain:@"" type:@"_arduipod._tcp." name:serviceName port:self.listeningSocket.localPort];
    netService.delegate = self;
    [netService publish];
}


-(void)stopService
{
    self.listeningSocket = nil;
    self.connectionSocket = nil;
    self.messageBroker.delegate = nil;
    self.messageBroker = nil;
    [netService stop];
}


#pragma mark - Socket Callbacks
-(BOOL)onSocketWillConnect:(AsyncSocket *)sock
{
    if (self.connectionSocket == nil)
    {
        self.connectionSocket = sock;
        return YES;
    }
    return NO;
}


-(void)onSocketDidDisconnect:(AsyncSocket *)sock
{
    if (sock == self.connectionSocket)
    {
        self.connectionSocket = nil;
        self.messageBroker = nil;
    }
}


-(void)onSocket:(AsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port
{
    MTMessageBroker *newBroker = [[MTMessageBroker alloc] initWithAsyncSocket:sock];
    newBroker.delegate = self;
    self.messageBroker = newBroker;
}


#pragma mark - MTMessageBroker Delegate Methods
-(void)messageBroker:(MTMessageBroker *)server didReceiveMessage:(MTMessage *)message
{
    if (message.tag == 100)
    {
//        messageLabel.text = [[NSString alloc] initWithData:message.dataContent encoding:NSUTF8StringEncoding];
    }
}


#pragma mark - Net Service Delegate Methods
-(void)netService:(NSNetService *)aNetService didNotPublish:(NSDictionary *)dict
{
    NSLog(@"Failed to publish: %@", dict);
}


@end
