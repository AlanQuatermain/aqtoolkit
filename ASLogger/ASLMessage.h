/*
 *  ASLMessage.h
 *  AQToolkit
 *
 *  Created by Jim Dovey on 27/8/2008.
 *
 *  Copyright (c) 2008-2009, Jim Dovey
 *  All rights reserved.
 *  
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions
 *  are met:
 *
 *  Redistributions of source code must retain the above copyright notice,
 *  this list of conditions and the following disclaimer.
 *  
 *  Redistributions in binary form must reproduce the above copyright
 *  notice, this list of conditions and the following disclaimer in the
 *  documentation and/or other materials provided with the distribution.
 *  
 *  Neither the name of this project's author nor the names of its
 *  contributors may be used to endorse or promote products derived from
 *  this software without specific prior written permission.
 *
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT 
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS 
 *  FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 *  HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 *  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 *  TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF 
 *  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING 
 *  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS 
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 */

#import <Foundation/Foundation.h>
#import <asl.h>

@interface ASLMessage : NSObject
{
	aslmsg	_message;
	BOOL	_nofree;
}

@property (nonatomic, readonly) aslmsg aslmessage;

// standard message key accessors
// readonly properties are those set by the server, and are only valid when receiver is the 
//  result of an ASL query.
@property (nonatomic, readonly) NSDate * time;			// "Time" for KVC
@property (nonatomic, readonly) NSHost * host;		// "Host"
@property (nonatomic, copy) NSString * sender;		// "Sender"
@property (nonatomic, copy) NSString * facility;	// "Facility"
@property (nonatomic, readonly) pid_t processID;	// "PID"	-- no value returns  0
@property (nonatomic, readonly) uid_t userID;		// "UID"	-- no value returns -1
@property (nonatomic, readonly) gid_t groupID;		// "GID"	-- no value returns -1
@property (nonatomic) int level;					// "Level"
@property (nonatomic, copy) NSString * message;		// "Message"

// security-related properties: set one or both of these to limit query access to the message
//  to the specified user/group
@property (nonatomic) uid_t readUID;		// "ReadUID" for KVC -- no value returns -1
@property (nonatomic) gid_t readGID;		// "ReadGID"		 -- no value returns -1

// all other values can be set via KVC. Note that since all aslmsg values are strings, any values
//  returned from -valueForKey: (except those handled by the property accessors above) will be
//  returned as NSString instances; it is up to the caller to convert to other objects.
// Passing in arbitrary non-NSString objects as values will result in -stringValue being called, or
//  if that method is not available, -description. So consider yourself warned (if you really 
// To remove a custom value, call -setValue:forKey: specifying nil as the value

@end
