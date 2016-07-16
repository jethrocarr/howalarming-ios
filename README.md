# howalarming-ios

Companion application for [HowAlarming](https://github.com/jethrocarr/howalarming)
which offers a native iOS client which can recieve push messages from a house
alarm via the HowAlarming platform.

This is an open source application which you'll need to build yourself, you
won't find it on the app store. See the instructions below.


# Functionality

* Notification and display of alarm events sent by the [HowAlarming GCM server](https://github.com/jethrocarr/howalarming-gcm).
* Allows the alarm to be armed or disarmed directly from the app.
* Automatic registration of active apps to the GCM server.

Unlike the Android app, this one doesn't do tricks like vibrate and ring
non-stop in the event of an alarm, iOS doesn't offer us as much flexibilty as
Android in this space.

![Screenshot1](https://raw.githubusercontent.com/jethrocarr/howalarming-ios/master/doc/howalarming-screenshot1.jpg)
![Screenshot2](https://raw.githubusercontent.com/jethrocarr/howalarming-ios/master/doc/howalarming-screenshot2.jpg)



# Installation

Firstly make sure you have a functional [HowAlarming](https://github.com/jethrocarr/howalarming)
environment up and running. Recommend testing with the email alerter to ensure
the basics are working first before setting up `alert_gcm.py` to support this
application.

Then you need to build this application. To do so:

1. Check out this source code repository.

2. Create a new project in Google Apps and enable Google Compute Messaging in
   it at the [Google Developer Console](https://developers.google.com/mobile/add).
   As part of this step, you will import your APNS certs from Apple into Google
   as they'll do the actual pushes to APNS for you.

3. Copy the provided `GoogleService-Info.plist` file to the root of the repo.

4. Open this project with XCode.

5. Connect an iOS device and do a build/run. You unfortunatly can't test this
   application in the simulator since the simulator can't do any kind of push
   notification.

6. Do an arm & disarm of your alarm. It should generate a notification on your
   device. If this works, good job - celebrate your new
   internet-of-mobile-things alarm system.


# I'm lazy, can you send me a prebuilt app or put this on the App Store?

I've intentionally not done this. Two main reasons - the first is that I don't
want to feel liable to people for guaranteeing their app/alarm works properly.

The second is that the only way to make a distributable version of this app
given that the user also controls the server, would be to setup an intermediary
service to authenticate/register users and pass messages to Google Cloud
Messaging which would instantly make people dependent on my systems. And then
I'm just another dodgy Internet-of-Things vendors with no SLA and no recourse if
I just turned it off one day.

Setting up GCM with Google and building the app is more work, but it guarantees
that the only third party between your HowAlarming server-side and your
HowAlarming client-side is yourself, Google's GCM service and Apple's APNS.

Annoyingly Apple *do* require you to have a current developer account to get a
signed cert for APNS so you'll have to fork up $100 a year if you don't already
have one. :-(



# Troubleshooting

Open Xcode and start from there.


# About

Written by Jethro Carr. Possibly not my greatest iOS app effort since it's
the first I've written for this platform. If it somehow doesn't crash and is
actually useful for you, please send me beer. :-)

Pull requests including docs, bug fixes, better build/setup instructions and of
course application UI & functionality improvements are all very welcome as well
instead (or in addition?) to beer.


# License

Unless otherwise stated, all source code is:

    Copyright (c) 2016 Jethro Carr

    Permission is hereby granted, free of charge, to any person obtaining a copy of
    this software and associated documentation files (the "Software"), to deal in
    the Software without restriction, including without limitation the rights to
    use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
    of the Software, and to permit persons to whom the Software is furnished to do
    so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
