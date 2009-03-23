/*
 *  ASLMessage.h
 *  AQToolkit
 *
 *  Created by Jim Dovey on 27/8/2008.
 *  Copyright (c) 2008 Jim Dovey. Some Rights Reserved.
 *
 *  This work is licensed under a Creative Commons
 *  Attribution License. You are free to use, modify,
 *  and redistribute this work, provided you include
 *  the following disclaimer:
 *
 *    Portions Copyright (c) 2008 Jim Dovey
 *
 *  For license details, see:
 *    http://creativecommons.org/licenses/by/3.0/
 *
 */
/*
 * Provided under non-exclusive license to Tenzing Communications.
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
