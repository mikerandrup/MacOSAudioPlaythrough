/*
     File: CAPlayThroughController.mm 
 Abstract: CAPlayThough Classes. 
  Version: 1.2.2 
  
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
  
 Copyright (C) 2013 Apple Inc. All Rights Reserved. 
  
*/ 

#import "CAPlayThroughController.h"

@implementation CAPlayThroughController
static void	BuildDeviceMenu(AudioDeviceList *devlist, NSPopUpButton *menu, AudioDeviceID initSel);
AudioDeviceID AudioDeviceWithNameWithPrefixInDeviceList(NSString*prefix,AudioDeviceList*devList);

- (id)init
{
	mInputDeviceList = new AudioDeviceList(true);
	mOutputDeviceList = new AudioDeviceList(false);
	return self;
}

- (void)awakeFromNib
{
    // BlackHole can be found at https://github.com/ExistentialAudio/BlackHole
    // I got this info from https://forums.macrumors.com/threads/mac-cant-control-display-monitor-volume.2270285/ 
    inputDevice=AudioDeviceWithNameWithPrefixInDeviceList(@"BlackHole 2ch", mInputDeviceList);
    outputDevice=AudioDeviceWithNameWithPrefixInDeviceList(@"BenQ", mOutputDeviceList);
	playThroughHost = new CAPlayThroughHost(inputDevice,outputDevice);
    [self startStop:nil];
}

- (void) dealloc 
{
	delete playThroughHost;			
	playThroughHost =0;

	delete mInputDeviceList;
	delete mOutputDeviceList;

	[super dealloc];
}

- (void)start: (id)sender
{
	if( !playThroughHost->IsRunning())
	{
		[mStartButton setTitle:@" Press to Stop"];
		playThroughHost->Start();
		[mProgress setHidden: NO];
		[mProgress startAnimation:sender];
	}
}

- (void)stop: (id)sender
{
	if( playThroughHost->IsRunning())
	{	
		[mStartButton setTitle:@"Start Play Through"];
		playThroughHost->Stop();
		[mProgress setHidden: YES];
		[mProgress stopAnimation:sender];
	}
}

- (void)resetPlayThrough
{
	if(playThroughHost->PlayThroughExists())
		playThroughHost->DeletePlayThrough();
	
	playThroughHost->CreatePlayThrough(inputDevice, outputDevice);
}
- (IBAction)openSystemPref:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"x-apple.systempreferences:com.apple.preference.security?Privacy"]];
    // see https://macosxautomation.com/system-prefs-links.html
}

- (IBAction)startStop:(id)sender
{

	if(!playThroughHost->PlayThroughExists())
	{
		playThroughHost->CreatePlayThrough(inputDevice, outputDevice);
	}
		
	if( !playThroughHost->IsRunning())
		[self start:sender];
	
	else
		[self stop:sender];
}

- (IBAction)inputDeviceSelected:(id)sender
{
	int val = (int)[mInputDevices indexOfSelectedItem];
	AudioDeviceID newDevice =(mInputDeviceList->GetList())[val].mID;
	
	if(newDevice != inputDevice)
	{		
		[self stop:sender];
		inputDevice = newDevice;
		[self resetPlayThrough];
	}
}

- (IBAction)outputDeviceSelected:(id)sender
{
	int val = (int)[mOutputDevices indexOfSelectedItem];
	AudioDeviceID newDevice = (mOutputDeviceList->GetList())[val].mID;
	
	if(newDevice != outputDevice)
	{ 
		[self stop:sender];
		outputDevice = newDevice;
		[self resetPlayThrough];
	}
}
AudioDeviceID AudioDeviceWithNameWithPrefixInDeviceList(NSString*prefix,AudioDeviceList*devList){
    int index=0;
    AudioDeviceList::DeviceList &thelist = devList->GetList();
    for (AudioDeviceList::DeviceList::iterator i = thelist.begin(); i != thelist.end(); ++i, ++index) {
        NSString*name=[NSString stringWithUTF8String:(*i).mName];
        if([name hasPrefix:prefix]){
            return (*i).mID;
        }
    }
    abort();
}

static void	BuildDeviceMenu(AudioDeviceList *devlist, NSPopUpButton *menu, AudioDeviceID initSel)
{
	[menu removeAllItems];

	AudioDeviceList::DeviceList &thelist = devlist->GetList();
	int index = 0;
	for (AudioDeviceList::DeviceList::iterator i = thelist.begin(); i != thelist.end(); ++i, ++index) {
/*		while([menu itemWithTitle:[NSString stringWithCString: (*i).mName encoding:NSASCIIStringEncoding]] != nil) {
			strcat((*i).mName, " ");
		}
*/
		if([menu itemWithTitle:[NSString stringWithCString: (*i).mName encoding:NSASCIIStringEncoding]] == nil) {
			[menu insertItemWithTitle: [NSString stringWithCString: (*i).mName encoding:NSASCIIStringEncoding] atIndex:index];

		if (initSel == (*i).mID)
			[menu selectItemAtIndex: index];
		}
	}
}

@end
