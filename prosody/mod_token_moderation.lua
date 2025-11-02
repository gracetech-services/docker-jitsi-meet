-- Token moderation
-- this module looks for a field on incoming JWT tokens called "moderator". 
-- If it is true the user is added to the room as a moderator, otherwise they are set to a normal user.
-- Note this may well break other affiliation based features like banning or login-based admins
local log = module._log;
local jid_bare = require"util.jid".bare;
local json = require "cjson";
local basexx = require "basexx";
local util = module:require 'util';
local is_admin = util.is_admin;
local it = require "util.iterators";
local jid_resource = require"util.jid".resource;
local jid_node = require'util.jid'.node;
local jid_split = require"util.jid".split;
local http = require "net.http";

log('info', 'Loaded token moderation plugin');

local username_to_displayname_map = {};
local function dumpSessions(hide_user_name)
    local index = 0;
    for _, session in pairs(prosody.full_sessions) do
        local username = session.username;
        if (username ~= 'focus' and username ~= 'jvb' and username ~= hide_user_name) then
            index = index + 1;
            local user_info = username_to_displayname_map[username] or {};
            log('info', "#%d: [%s(%s)] IP: [%s] Email: [%s] in room [%s]", 
                index, user_info.name or "unknown", username, user_info.ip or "unknown", user_info.email or "unknown",
                session.jitsi_web_query_room);
        end
    end
    log('info', "Total online users: %d", index);
end;

module:hook("muc-occupant-joined", function(event)
    local occupant, room = event.occupant, event.room;
    if jid_node(occupant.jid) == 'focus' then
        return;
    end

    local display_name = occupant:get_presence():get_child_text('nick', 'http://jabber.org/protocol/nick');
    local room_node, _, _ = jid_split(room.jid);
    local occupant_node, _, _ = jid_split(occupant.jid);
    log('info', "[%s(%s)] joined [%s]", display_name, occupant_node, room_node);
    
    -- Initialize user info with display name
    username_to_displayname_map[occupant_node] = {
        name = display_name,
        email = nil,
        ip = nil
    };
    dumpSessions("");
end);

module:hook('muc-occupant-left', function(event)
    local occupant, room = event.occupant, event.room;
    if jid_node(occupant.jid) == 'focus' then
        return;
    end

    local room_node, _, _ = jid_split(room.jid);
    local occupant_node, _, _ = jid_split(occupant.jid);
    local user_info = username_to_displayname_map[occupant_node] or {};
    log('info', "[%s(%s)] left [%s]", user_info.name or "unknown", occupant_node, room_node);
    username_to_displayname_map[occupant_node] = nil;
    dumpSessions(occupant_node);

    -- Make HTTP request to notify left event
    local url = "https://s1.idigest.app/meet/left?userId=" .. occupant_node;
    http.request(url, {}, function(body, code, headers, status)
        if code ~= 200 then
            log('warn', 'Failed to notify left event for %s: code=%s, status=%s', occupant_node, code, status);
        end
    end);
end);

-- Hook into room creation to add this wrapper to every new room
module:hook("muc-room-created", function(event)
    log('info', 'room created, adding token moderation code');
    local room = event.room;
    local _handle_normal_presence = room.handle_normal_presence;
    local _handle_first_presence = room.handle_first_presence;
    -- Wrap presence handlers to set affiliations from token whenever a user joins
    room.handle_normal_presence = function(thisRoom, origin, stanza)
        local pres = _handle_normal_presence(thisRoom, origin, stanza);
        setupAffiliation(thisRoom, origin, stanza);
        return pres;
    end;
    room.handle_first_presence = function(thisRoom, origin, stanza)
        local pres = _handle_first_presence(thisRoom, origin, stanza);
        setupAffiliation(thisRoom, origin, stanza);
        return pres;
    end;
    -- Wrap set affilaition to block anything but token setting owner (stop pesky auto-ownering)
    local _set_affiliation = room.set_affiliation;
    room.set_affiliation = function(room, actor, jid, affiliation, reason)
        -- let this plugin do whatever it wants
        if actor == "token_plugin" then
            return _set_affiliation(room, true, jid, affiliation, reason)
            -- noone else can assign owner (in order to block prosody/jisti's built in moderation functionality
        elseif affiliation == "owner" then
            return nil, "modify", "not-acceptable"
            -- keep other affil stuff working as normal (hopefully, haven't needed to use/test any of it)
        else
            return _set_affiliation(room, actor, jid, affiliation, reason);
        end
    end;
end);

function setupAffiliation(room, origin, stanza)
    if origin.auth_token then
        -- Extract token body and decode it
        local dotFirst = origin.auth_token:find("%.");
        if dotFirst then
            local dotSecond = origin.auth_token:sub(dotFirst + 1):find("%.");
            if dotSecond then
                local bodyB64 = origin.auth_token:sub(dotFirst + 1, dotFirst + dotSecond - 1);
                local body = json.decode(basexx.from_url64(bodyB64));
                local jid = jid_bare(stanza.attr.from);
                local occupant_node, _, _ = jid_split(jid);
                
                -- Initialize if not already present
                if not username_to_displayname_map[occupant_node] then
                    username_to_displayname_map[occupant_node] = {};
                end
                
                -- Extract user info from JWT token
                if body["context"] and body["context"]["user"] then
                    username_to_displayname_map[occupant_node].email = body["context"]["user"]["email"];
                    username_to_displayname_map[occupant_node].name = body["context"]["user"]["name"];
                end
                
                -- Get IP from connection
                if origin.conn then
                    username_to_displayname_map[occupant_node].ip = origin.conn:ip();
                end
                
                local user_info = username_to_displayname_map[occupant_node];
                log('info', "%s(%s) Email: %s IP: %s: %s", user_info.name or "unknown", occupant_node, 
                    user_info.email or "unknown", user_info.ip or "unknown", basexx.from_url64(bodyB64));
                
                -- If user is a moderator or an admin, set their affiliation to be an owner
                if body["moderator"] == true or is_admin(jid) then
                    room:set_affiliation("token_plugin", jid, "owner");
                else
                    room:set_affiliation("token_plugin", jid, "member");
                end
            end
        end
    else
        log('info', "origin.auth_token not exist!");
    end
end
