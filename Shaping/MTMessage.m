// ------------------------------------------------------------------------------------
// Copyright (c) 2008, Drew McCormack
//
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without modification,
// are permitted provided that the following conditions are met:
//
// Redistributions of source code must retain the above copyright notice,
// this list of conditions and the following disclaimer.
// Redistributions in binary form must reproduce the above copyright notice,
// this list of conditions and the following disclaimer in the documentation and/or
// other materials provided with the distribution.
// Neither the name of the MTMessage nor the names of its
// contributors may be used to endorse or promote products derived from this software
// without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
// CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
// EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
// PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
// PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
// LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
// NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
// SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.=======
// ------------------------------------------------------------------------------------

#import "MTMessage.h"


@implementation MTMessage

-(id)initWithCoder:(NSCoder *)coder
{
    if ( self = [super init] )
    {
        tag = [coder decodeIntForKey:@"tag"];
        dataContent = [coder decodeObjectForKey:@"dataContent"];
    }
    return self;
}

-(void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeInt:tag forKey:@"tag"];
    [coder encodeObject:dataContent forKey:@"dataContent"];
}

-(void)dealloc
{
}

-(int)tag
{
    return tag;
}

-(void)setTag:(int)value
{
    tag = value;
}

-(NSData *)dataContent
{
    return dataContent;
}

-(void)setDataContent:(NSData *)value
{
    if (dataContent != value)
    {
        dataContent = [value copy];
    }
}

@end
