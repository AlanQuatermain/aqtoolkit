/*
 *  b64.m
 *  AQToolkit
 *
 *  Created by Jim Dovey on 11-01-11.
 *  Based on b64.c by Bob Trower
 *  <http://base64.sourceforge.net/b64.c>
 *
 */
/*********************************************************************\
 
MODULE NAME:    b64.c

AUTHOR:         Bob Trower 08/04/01

PROJECT:        Crypt Data Packaging

COPYRIGHT:      Copyright (c) Trantor Standard Systems Inc., 2001

NOTE:           This source code may be used as you wish, subject to
                the MIT license.  See the LICENCE section below.
DESCRIPTION:
                This little utility implements the Base64
                Content-Transfer-Encoding standard described in
                RFC1113 (http://www.faqs.org/rfcs/rfc1113.html).

                This is the coding scheme used by MIME to allow
                binary data to be transferred by SMTP mail.

                Groups of 3 bytes from a binary stream are coded as
                groups of 4 bytes in a text stream.

                The input stream is 'padded' with zeros to create
                an input that is an even multiple of 3.

                A special character ('=') is used to denote padding so
                that the stream can be decoded back to its exact size.

                Encoded output is formatted in lines which should
                be a maximum of 72 characters to conform to the
                specification.  This program defaults to 72 characters,
                but will allow more or less through the use of a
                switch.  The program enforces a minimum line size
                of 4 characters.

                Example encoding:

                The stream 'ABCD' is 32 bits long.  It is mapped as
                follows:

                ABCD

                 A (65)     B (66)     C (67)     D (68)   (None) (None)
                01000001   01000010   01000011   01000100

                16 (Q)  20 (U)  9 (J)   3 (D)    17 (R) 0 (A)  NA (=) NA (=)
                010000  010100  001001  000011   010001 000000 000000 000000


                QUJDRA==

                Decoding is the process in reverse.  A 'decode' lookup
                table has been created to avoid string scans.

LICENCE:        Copyright (c) 2001 Bob Trower, Trantor Standard Systems Inc.
                
                Permission is hereby granted, free of charge, to any person
                obtaining a copy of this software and associated
                documentation files (the "Software"), to deal in the
                Software without restriction, including without limitation
                the rights to use, copy, modify, merge, publish, distribute,
                sublicense, and/or sell copies of the Software, and to
                permit persons to whom the Software is furnished to do so,
                subject to the following conditions:
                
                The above copyright notice and this permission notice shall
                be included in all copies or substantial portions of the
                Software.
                
                THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY
                KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
                WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
                PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS
                OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
                OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
                OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
                SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
                
VERSION HISTORY:
                Bob Trower 08/04/01 -- Create Version 0.00.00B

\******************************************************************* */

#import "b64.h"
#import <Foundation/Foundation.h>

/*
** Translation Table as described in RFC1113
*/
static const char cb64[]="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

/*
** Translation Table to decode (created by author)
*/
static const char cd64[]="|$$$}rstuvwxyz{$$$$$$$>?@ABCDEFGHIJKLMNOPQRSTUVW$$$$$$XYZ[\\]^_`abcdefghijklmnopq";

/*
** encodeblock
**
** encode 3 8-bit binary bytes as 4 '6-bit' characters
*/
static void encodeblock( unsigned char in[3], unsigned char out[4], int len )
{
    out[0] = cb64[ in[0] >> 2 ];
    out[1] = cb64[ ((in[0] & 0x03) << 4) | ((in[1] & 0xf0) >> 4) ];
    out[2] = (unsigned char) (len > 1 ? cb64[ ((in[1] & 0x0f) << 2) | ((in[2] & 0xc0) >> 6) ] : '=');
    out[3] = (unsigned char) (len > 2 ? cb64[ in[2] & 0x3f ] : '=');
}

/*
** encode
**
** base64 encode a stream adding padding and line breaks as per spec.
*/
NSData * b64_encode( NSData * data )
{
    uint8_t in[3], out[4];
    int i, len;
    
    const uint8_t *bytes = (const uint8_t *)[data bytes];
    NSUInteger bytesLen = [data length];
    NSUInteger offset = 0;
    
    NSMutableData * outputData = [[NSMutableData alloc] initWithCapacity: bytesLen + (bytesLen/4) + 1];

    while( offset < bytesLen )
    {
        len = 0;
        for( i = 0; i < 3; i++ )
        {
            if ( offset < bytesLen )
            {
                in[i] = bytes[offset++];
                len++;
            }
            else
            {
                in[i] = 0;
            }
        }
        
        if ( len != 0 )
        {
            encodeblock( in, out, len );
            [outputData appendBytes: out length: 4];
        }
    }
    
    NSData * result = [outputData copy];
    [outputData release];
    return ( [result autorelease] );
}

/*
** decodeblock
**
** decode 4 '6-bit' characters into 3 8-bit binary bytes
*/
void decodeblock( unsigned char in[4], unsigned char out[3] )
{   
    out[ 0 ] = (unsigned char ) (in[0] << 2 | in[1] >> 4);
    out[ 1 ] = (unsigned char ) (in[1] << 4 | in[2] >> 2);
    out[ 2 ] = (unsigned char ) (((in[2] << 6) & 0xc0) | in[3]);
}

/*
** decode
**
** decode a base64 encoded stream discarding padding, line breaks and noise
*/
NSData * b64_decode( NSData * data )
{
    uint8_t in[4], out[3], v;
    int i, len;
    
    const uint8_t *bytes = (const uint8_t *)[data bytes];
    NSUInteger bytesLen = [data length];
    NSUInteger offset = 0;
    
    NSMutableData * outputData = [[NSMutableData alloc] initWithCapacity: bytesLen];

    while ( offset < bytesLen )
    {
        for ( len = 0, i = 0; i < 4 && offset < bytesLen; i++ )
        {
            v = 0;
            while ( offset < bytesLen && v == 0 )
            {
                v = bytes[offset++];
                v = ((v < 43 || v > 122) ? 0 : cd64[ v - 43 ]);
                
                if ( v != 0 )
                {
                    v = ((v == '$') ? 0 : v - 61);
                }
            }
            
            if ( (offset < (bytesLen+1)) && (v != 0) )
            {
                len++;
                if ( v != 0 )
                {
                    in[ i ] = (v - 1);
                }
            }
            else
            {
                in[i] = 0;
            }
        }
        
        if ( len )
        {
            decodeblock( in, out );
            [outputData appendBytes: out length: len-1];
        }
    }
    
    NSData * result = [outputData copy];
    [outputData release];
    return ( [result autorelease] );
}
