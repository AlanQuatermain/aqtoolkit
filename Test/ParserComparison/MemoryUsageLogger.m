/*
 *  MemoryUsageLogger.h
 *  ParserComparison
 *
 *  Created by Jim Dovey on 6/4/2009.
 *
 *  Copyright (c) 2009 Jim Dovey
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

#import <mach/mach_host.h>
#import <mach/task.h>
#import <mach/task_info.h>
#import <mach/vm_statistics.h>
#import <mach/machine/vm_param.h>
#import <sys/sysctl.h>

#import <Foundation/Foundation.h>

void LogHostMemoryUsage( void )
{
    mach_msg_type_number_t count = HOST_VM_INFO_COUNT;
    vm_statistics_t vmstat;
    if ( host_statistics(mach_host_self(), HOST_VM_INFO, (host_info_t)&vmstat, &count) != KERN_SUCCESS )
        return;
    
    double total = vmstat->wire_count + vmstat->active_count + vmstat->inactive_count + vmstat->free_count;
    double wired = vmstat->wire_count / total;
    double active = vmstat->active_count / total;
    double inactive = vmstat->inactive_count / total;
    double free = vmstat->free_count / total;
    
    NSMutableString * str = [[NSMutableString alloc] initWithCapacity: 160];
	
	[str appendFormat: @"Total =    %8d pages\n", vmstat->wire_count + vmstat->active_count + vmstat->inactive_count + vmstat->free_count];
	[str appendString: @"\n"];
	
	[str appendFormat: @"Wired =    %8d bytes\n", vmstat->wire_count * vm_page_size];
	[str appendFormat: @"Active =   %8d bytes\n", vmstat->active_count * vm_page_size];
	[str appendFormat: @"Inactive = %8d bytes\n", vmstat->inactive_count * vm_page_size];
	[str appendFormat: @"Free =     %8d bytes\n", vmstat->free_count * vm_page_size];
	[str appendString: @"\n"];
	
	[str appendFormat: @"Total =    %8d bytes\n", (vmstat->wire_count + vmstat->active_count + vmstat->inactive_count + vmstat->free_count) * vm_page_size];
	[str appendString: @"\n"];
	
	[str appendFormat: @"Wired =    %0.2f %%\n", wired * 100.0];
	[str appendFormat: @"Active =   %0.2f %%\n", active * 100.0];
	[str appendFormat: @"Inactive = %0.2f %%\n", inactive * 100.0];
	[str appendFormat: @"Free =     %0.2f %%\n", free * 100.0];
	
	NSLog( @"Memory Usage:\n%@", str );
	[str release];
}

mach_vm_size_t GetProcessMemoryUsage( void )
{
    task_basic_info_64_data_t info;
    mach_msg_type_number_t count = TASK_BASIC_INFO_64_COUNT;
    if ( task_info(mach_task_self(), TASK_BASIC_INFO_64, (task_info_t) &info, &count) != KERN_SUCCESS )
        return ( 0 );
    
    return ( info.virtual_size );
}
