/*
 *  b64.h
 *  AQToolkit
 *
 *  Created by Jim Dovey on 11-01-11.
 *  Based on b64.c by Bob Trower
 *  <http://base64.sourceforge.net/b64.c>
 *
 */

#import <Foundation/NSData.h>

NSData * b64_encode( NSData * data );
NSData * b64_decode( NSData * data );
