--[[

  Copyright (C) 2016 Masatoshi Teruya

  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in
  all copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
  THE SOFTWARE.

  udp.lua
  lua-writelog-udp
  Created by Masatoshi Teruya on 16/07/07.

--]]

-- assign to local
local writelog = require('writelog');
local InetClient = require('net.dgram.inet');
local UnixClient = require('net.dgram.unix');
local concat = table.concat;


local function sendlog( ctx, sender, ... )
    if select( '#', ... ) > 1 then
        return sender( ctx.sock, concat( {...}, ' ' ) );
    end

    return sender( ctx.sock, ... );
end


local function send( ctx, ... )
    sendlog( ctx, ctx.sock.send, ... );
end


local function sendq( ctx, ... )
    sendlog( ctx, ctx.sock.sendq, ... );
end


local function flush( ctx )
    ctx.sock:flushq();
end


local function close( ctx )
    ctx.sock:close();
    return true;
end


--- new
-- @param lv
-- @param ctx
-- @param opts
-- @return logger
-- @return err
local function new( lv, ctx, opts )
    local formatter = opts and opts.formatter;
    local sendfn = send;
    local err;

    -- set flush method if non-blocking mode
    if opts and opts.nonblock == true then
        ctx.flush = flush;
        ctx.nonblock = true;
        sendfn = sendq;
    end

    -- inet socket
    if ctx.host then
        ctx.sock, err = InetClient.new({
            host = ctx.host,
            port = ctx.port
        });
    -- unix domain socket
    else
        ctx.sock, err = UnixClient.new({
            path = ctx.path
        });
    end

    err = err or ctx.sock:connect();
    if err then
        return nil, err;
    elseif ctx.nonblock then
        ctx.sock:nonblock( true );
    end

    ctx.close = close;

    return writelog.create( ctx, lv, sendfn, formatter );
end


-- exports
return {
    new = new
};
