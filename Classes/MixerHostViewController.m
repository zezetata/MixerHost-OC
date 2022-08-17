/*
 File: MixerHostViewController.m
 Abstract: View controller: Sets up the user interface and conveys UI actions
 to the MixerHostAudio object. Also responds to state-change notifications from
 the MixerHostAudio object.
 Version: 1.0
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2010 Apple Inc. All Rights Reserved.
 
 */


#import "MixerHostViewController.h"

#import "MixerHostAudio.h"

NSString *MixerHostAudioObjectPlaybackStateDidChangeNotification = @"MixerHostAudioObjectPlaybackStateDidChangeNotification";

@implementation MixerHostViewController

# pragma mark -
# pragma mark User interface methods

// Set the initial multichannel mixer unit parameter values according to the UI state
- (void)initializeMixerSettingsToUI {
    // Initialize mixer settings to UI
    [self.audioObject enableMixerInput:0 isOn:self.mixerBus0Switch.isOn];
    [self.audioObject enableMixerInput:1 isOn:self.mixerBus1Switch.isOn];

    [self.audioObject setMixerOutputGain:self.mixerOutputLevelFader.value];

    [self.audioObject setMixerInput:0 gain:self.mixerBus0LevelFader.value];
    [self.audioObject setMixerInput:1 gain:self.mixerBus1LevelFader.value];
}

// Handle a change in the mixer output gain slider.
- (IBAction)mixerOutputGainChanged:(UISlider *)sender {
    [self.audioObject setMixerOutputGain:(AudioUnitParameterValue) sender.value];
}

// Handle a change in a mixer input gain slider. The "tag" value of the slider lets this 
//    method distinguish between the two channels.
- (IBAction)mixerInputGainChanged:(UISlider *)sender {
    UInt32 inputBus = (UInt32)sender.tag;
    [self.audioObject setMixerInput:(UInt32) inputBus gain:(AudioUnitParameterValue) sender.value];
}


#pragma mark -
#pragma mark Audio processing graph control

// Handle a play/stop button tap
- (IBAction)playOrStop:(id)sender {
    if (self.audioObject.isPlaying) {
        [self.audioObject stopAUGraph];
        [self.playButton setTitle:@"Play" forState:UIControlStateNormal];
        self.playButton.backgroundColor = [UIColor blueColor];
    } else {
        [self.audioObject startAUGraph];
        [self.playButton setTitle:@"Stop" forState:UIControlStateNormal];
        self.playButton.backgroundColor = [UIColor redColor];
    }
}

// Handle a change in playback state that resulted from an audio session interruption or end of interruption
- (void)handlePlaybackStateChanged:(NSNotification *)notification {
    [self playOrStop:nil];
}


#pragma mark -
#pragma mark Mixer unit control
- (IBAction)enableMixerInput:(UISwitch *)sender {
    UInt32 inputBus = (UInt32)sender.tag;
    AudioUnitParameterValue isOn = (AudioUnitParameterValue)sender.isOn;
    [self.audioObject enableMixerInput:inputBus isOn:isOn];
}


#pragma mark -
#pragma mark Remote-control event handling

// Respond to remote control events
- (void)remoteControlReceivedWithEvent:(UIEvent *)receivedEvent {
    if (receivedEvent.type == UIEventTypeRemoteControl) {
        switch (receivedEvent.subtype) {
            case UIEventSubtypeRemoteControlTogglePlayPause:
                [self playOrStop:nil];
                break;
            default:
                break;
        }
    }
}


#pragma mark -
#pragma mark Notification registration
- (void)registerForAudioObjectNotifications {
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];

    [notificationCenter addObserver:self
                           selector:@selector(handlePlaybackStateChanged:)
                               name:MixerHostAudioObjectPlaybackStateDidChangeNotification
                             object:self.audioObject];
}


#pragma mark -
#pragma mark Application state management

- (void)viewDidLoad {
    [super viewDidLoad];

    self.audioObject = [[MixerHostAudio alloc] init];

    [self registerForAudioObjectNotifications];
    [self initializeMixerSettingsToUI];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    [self becomeFirstResponder];
}

- (BOOL)canBecomeFirstResponder {
    return YES;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


- (void)viewWillDisappear:(BOOL)animated {
    [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
    [self resignFirstResponder];

    [super viewWillDisappear:animated];
}

- (void)dealloc {
    self.audioObject = nil;

    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:MixerHostAudioObjectPlaybackStateDidChangeNotification
                                                  object:self.audioObject];
}

@end
