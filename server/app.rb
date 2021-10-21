# frozen_string_literal: true

require 'eventmachine'
require 'sinatra'
require 'securerandom'
require 'json'
require 'pp'

#100 all EVENT IDs array(for last event ID)
eventq = Array.new
#Map for event ID to eventdata
idtodata = Hash.new
#100 message Array
myq = Array.new
#Map for event ID to event data (for message only)
msgidtodata = Hash.new

#1 - ServerStatus
#2 - Users
#3 - Join
#4 - Part
#5 - Disconnect
#6 - Message


#Waste stream tokens
waste = Set.new

#Map b/w username and password
users = Hash.new

#Map b/w stream to User
streams = Hash.new

#Map b/w User to Stream
user_streams = Hash.new

#List of Opened streams
opened_streams = Set.new

#list of all connected users
conn_users = Set.new

#Map b/w stream token to connection
str_conn = Hash.new 

#Map b/w connection to stream token
conn_str = Hash.new

#Map b/w Users to message token
user_msg_token = Hash.new

#Map b/w message token to Users
msg_user_token = Hash.new

hours = 0;

SCHEDULE_TIME = 3600
connections = []

eventdata = {status:"Server Start",created:Time.now.to_i}.to_json
id = SecureRandom.hex
if(eventq.length >= 100)
  rem_event = eventq.shift
  idtodata.delete(rem_event)
  temp_string = "1"+id
  eventq << temp_string
  idtodata[temp_string] = eventdata
else
  temp_string = "1"+id
  eventq << temp_string
  idtodata[temp_string] = eventdata
end

if(myq.length >= 100)
  rem=myq.shift
  msgidtodata.delete(rem)
  tem = "1"+id
  myq << tem
  msgidtodata[tem] = eventdata
else
  tem = "1"+id
  myq << tem
  msgidtodata[tem] = eventdata
end

EventMachine.schedule do
  EventMachine.add_periodic_timer(SCHEDULE_TIME) do
    hours = hours+1
    # Change this for any timed events you need to schedule.
    ###puts "This message will be output to the server console every #{SCHEDULE_TIME} seconds"
    eventdata = {status:"Server uptime: " + hours.to_s + " hours",created:Time.now.to_i}.to_json
    id = SecureRandom.hex
    if(eventq.length >= 100)
      rem_event = eventq.shift
      idtodata.delete(rem_event)
      temp_string = "1"+id
      eventq << temp_string
      idtodata[temp_string] = eventdata
    else
      temp_string = "1"+id
      eventq << temp_string
      idtodata[temp_string] = eventdata
    end

    if(myq.length >= 100)
      rem=myq.shift
      msgidtodata.delete(rem)
      tem = "1"+id
      myq << tem
      msgidtodata[tem] = eventdata
    else
      tem = "1"+id
      myq << tem
      msgidtodata[tem] = eventdata
    end

    connections.each do |s|     
      s << "event: ServerStatus\n"
      s << "data: #{eventdata}\n"
      s << "id: #{id}\n\n"
    end
  end
end

configure do
  enable :cross_origin
end

before do
  response.headers["Access-Control-Allow-Origin"] = "*"
end

options "*" do
  response.headers["Allow"] = "HEAD,GET,PUT,POST,DELETE,OPTIONS" 
  response.headers["Access-Control-Allow-Headers"] = "X-Requested-With, X-HTTP-Method-Override, Access-Control-Allow-Origin, Content-Type, Cache-Control, Accept, Authorization"
  response.headers["Access-Control-Expose-Headers"] = "token" 
  200
end

get '/stream/:token', provides: 'text/event-stream' do
  headers 'Access-Control-Allow-Origin' => '*'
  if streams.key?(params["token"]) == false
    status 403
    return
  end

  var = opened_streams === params["token"]
  if(var == true)
    status 409
    return
  end
  ret_test = 0

  var = waste === params["token"]
  if(var == true)
    ##puts "WASTE STREAM"
    status 403
    return
  end
  stream(:keep_open) do |connection|
    connections << connection
    if(request.env.key?('HTTP_LAST_EVENT_ID') == true)
      #puts "HISTORY HEADER FOUND"
      last_event = request.env['HTTP_LAST_EVENT_ID']
      #puts "Last event + " + last_event
      len = eventq.length
      l = 0
      while l<len
        ###puts "TEST2"
        if(eventq[l][1..-1] == last_event)
          opened_streams << params["token"]
          ret_test = 1
          #puts "HISTORY FOUND"
          l = l+1
          ##puts "AFTER HISTORY FOUND, l = " + l.to_s + " len = " + len.to_s
          while l<len
            if(eventq[l][0] == '1')
              connection << "event: ServerStatus\n"
              connection << "data: #{idtodata[eventq[l]]}\n"
              connection << "id: #{eventq[l][1..-1]}\n\n"
            elsif(eventq[l][0] == '3')
              connection << "event: Join\n"
              connection << "data: #{idtodata[eventq[l]]}\n"
              connection << "id: #{eventq[l][1..-1]}\n\n"
            elsif(eventq[l][0] == '4')
              connection << "event: Part\n"
              connection << "data: #{idtodata[eventq[l]]}\n"
              connection << "id: #{eventq[l][1..-1]}\n\n"
            elsif(eventq[l][0] == '5')
              connection << "event: Disconnect\n"
              connection << "data: #{idtodata[eventq[l]]}\n"
              connection << "id: #{eventq[l][1..-1]}\n\n"
            elsif(eventq[l][0] == '6')
              connection << "event: Message\n"
              connection << "data: #{idtodata[eventq[l]]}\n"
              connection << "id: #{eventq[l][1..-1]}\n\n"
            end
            l = l+1
          end
          ##puts "COMING HERE 158"
          conn_users.add(streams[params['token']])
          # eventdata = {users:conn_users.to_a,created:Time.now.to_i}.to_json
          # connection << "event: Users\n"
          # connection << "data: #{eventdata}\n"
          # connection << "id: temp\n\n"
          eventdata = {created:Time.now.to_i,user:streams[params["token"]]}.to_json
          id = SecureRandom.hex
          if(eventq.length >= 100)
            rem_event = eventq.shift
            idtodata.delete(rem_event)
            temp_string = "3"+id
            eventq << temp_string
            idtodata[temp_string] = eventdata
          else
            temp_string = "3"+id
            eventq << temp_string
            idtodata[temp_string] = eventdata
          end
          connections.each do |s|
            s << "event: Join\n"
            s << "data: #{eventdata}\n"
            s << "id: #{id}\n\n"
          end
        ##puts "COMING HERE 159"
        end
        l = l+1
      end
    end

    if(ret_test == 1)
      #puts "SUCCESS"
    else
      #puts "TEST1"
      str_conn[params["token"]] = connection
      conn_str[connection] = params["token"]
      opened_streams << params["token"]
      tempq = Array.new
      tempq = myq.clone
      tempa = Array.new
      while !tempq.empty? do
        ##puts "Copying here"
        item = tempq.shift
        tempa << item
        ##puts item
      end
      len = tempa.length
      l = 0
      #puts "Array length: " + len.to_s
      while l<len
        if(tempa[l][0] == '1')
          connection << "event: ServerStatus\n"
          connection << "data: #{msgidtodata[tempa[l]]}\n"
          connection << "id: #{tempa[l][1..-1]}\n\n"
        elsif(tempa[l][0] == '2')
          connection << "event: Message\n"
          connection << "data: #{msgidtodata[tempa[l]]}\n"
          connection << "id: #{tempa[l][1..-1]}\n\n"
        end
        l = l+1
      end
      #puts "Line 242"
      eventdata = {users:conn_users.to_a,created:Time.now.to_i}.to_json
      id = SecureRandom.hex
      #puts "Sharath: Sending users"
      connection << "event: Users\n"
      connection << "data: #{eventdata}\n"
      connection << "id: #{id}\n\n" # SAI: Check
      ##puts "Called Users Connected Users"

      conn_users.add(streams[params['token']])
      eventdata = {created:Time.now.to_i,user:streams[params["token"]]}.to_json
      id = SecureRandom.hex
      if(eventq.length >= 100)
        rem_event = eventq.shift
        idtodata.delete(rem_event)
        temp_string = "3"+id
        eventq << temp_string
        idtodata[temp_string] = eventdata
      else
        temp_string = "3"+id
        eventq << temp_string
        idtodata[temp_string] = eventdata
      end
      connections.each do |s|
        s << "event: Join\n"
        s << "data: #{eventdata}\n"
        s << "id: #{id}\n\n"
      end 
    end

    str_conn[params["token"]] = connection
    conn_str[connection] = params["token"]

    connection.callback do
      ##puts 'callback'
      str = conn_str[connection]
      user = streams[str]
      ##puts "CALLBACK User= : " + user
      eventdata = {created:Time.now.to_i,user:user}.to_json
      connections.delete(connection)
      id = SecureRandom.hex
      if(eventq.length >= 100)
        rem_event = eventq.shift
        idtodata.delete(rem_event)
        temp_string = "4"+id
        eventq << temp_string
        idtodata[temp_string] = eventdata
      else
        temp_string = "4"+id
        eventq << temp_string
        idtodata[temp_string] = eventdata
      end
      connections.each do |s|
        ##puts "Line 292"
        s << "event: Part\n"
        s << "data: #{eventdata}\n"
        s << "id: #{id}\n\n"
      end
      opened_streams.delete(str)
      conn_users.delete(user)
    end
  end
end

post '/login' do
  require 'pp'
  ##puts 'Hello Sharath: '
  headers 'Access-Control-Allow-Origin' => '*'
  if(params.keys.count != 2) 
     ##puts 'Hello Sharath: 1'
    status 422
    return
  end

  if(params.key?('username') != true)
    ##puts 'Hello Sharath: 2'
    status 422
    return
  end

  if(params.key?('password') != true)
    ##puts 'Hello Sharath: 3'
    status 422
    return
  end

  if(params['username'] == '')
     ##puts 'Hello Sharath: 4' 
    status 422
    return
  end

  if(params['password'] == '')
     ##puts 'Hello Sharath: 5'
    status 422
    return
  end

  if(users.key?(params['username']) != true)
    users[params['username']] = params['password']
    ##puts "Login created"
    ##puts params['username']
    ##puts params['password']
    msg_token = SecureRandom.hex
    str_token = SecureRandom.hex
    ##puts "Stream token: " + str_token
    ##puts "Message token: " + msg_token
    streams[str_token] = params['username']
    user_streams[params['username']] = str_token
    user_msg_token[params['username']] = msg_token
    msg_user_token[msg_token] = params["username"]
    body = {message_token: "#{msg_token}", stream_token: "#{str_token}"}
    headers 'Content-Type' => 'application/json'
    ##puts "Line 353"
    return [201, body.to_json]
  else
    if(users[params['username']] != params['password'])
      ##puts "Line 357"
      status 403
      return
    else
      ##puts "Line 361"
      msg_token = user_msg_token[params['username']]
      str_token = user_streams[params['username']]
      ##puts "Stream token: " + str_token
      ##puts "Message token: " + msg_token
      var = opened_streams === str_token
      if(var == true)
        status 409
        return
      end
      ##puts "Entering past Opened streams"
      waste << str_token
      c = str_conn[str_token]
      str_conn.delete(str_token)
      streams.delete(str_token)
      user_streams.delete(params["username"])
      user_msg_token.delete(params["username"])
      msg_user_token.delete(msg_token)
      msg_token = SecureRandom.hex
      str_token = SecureRandom.hex
      conn_str.delete(c)
      str_conn.delete(c)
      ##puts "Stream token: " + str_token
      ##puts "Message token: " + msg_token
      streams[str_token] = params['username']
      user_streams[params['username']] = str_token
      user_msg_token[params['username']] = msg_token
      msg_user_token[msg_token] = params["username"]
      body = {message_token: "#{msg_token}", stream_token: "#{str_token}"}
      headers 'Content-Type' => 'application/json'
      return [201, body.to_json]
    end   
  end
end

post '/message' do
  headers 'Access-Control-Allow-Origin' => '*'
  headers "Access-Control-Expose-Headers" => "token" 
  require 'pp'

  ##puts 'request.headers:'
  #PP.pp request.env["HTTP_AUTHORIZATION"]
  ##puts

  if(request.env.key?("HTTP_AUTHORIZATION") != true)
    status 403
    return
  end

  if(request.env["HTTP_AUTHORIZATION"].length <= 7)
    status 403
    return
  end

  if(request.env["HTTP_AUTHORIZATION"][0..6] != "Bearer ")
    ##puts "Bearer Not present"
    ##puts
    status 403
    return
  end

  m_t = request.env["HTTP_AUTHORIZATION"][7..-1]
  if(msg_user_token.key?(m_t) != true)
    status 403
    return
  end

  if(params.keys.count != 1) 
    ##puts 'Hello Sharath message: 1'
    status 422
    return
  end

  if(params.key?('message') != true)
    ##puts 'Hello Sharath message : 2'
    status 422
  return
  end

  if(request.params["message"].empty?)
    ##puts "Empty message detected"
    status 422
    return
  end

  ##puts "Message that is tested is " + request.params["message"]

  u_name = msg_user_token[m_t]
  str = user_streams[u_name]
  var = opened_streams === str
  new_m_t = SecureRandom.hex
  msg_user_token.delete(m_t)
  msg_user_token[new_m_t] = u_name
  user_msg_token.delete(u_name)
  user_msg_token[u_name] = new_m_t

  var = opened_streams === str

  if(var == false)
    ##puts "While message, Stream is already opened"
    headers 'Token' => new_m_t 
    status 409
    return
  end

  headers 'Token' => new_m_t 
  ##puts "Message length = " + request.params["message"].length.to_s
  if(request.params["message"].length > 6)
    ##puts "Message first 6 chars = " + request.params["message"][0..5]
    if(request.params["message"][0..5] == "/kick ")
      ##puts "Came to kick " + request.params["message"][6..-1]
      kick_u = request.params["message"][6..-1]
      var = conn_users === kick_u
      if(var == true)
        if(kick_u == u_name)
          ##puts "Kicking same user"
          return 409
        else
          ##puts "Kicking user: " + kick_u
          c = str_conn[user_streams[kick_u]]
          eventdata = {status:u_name + " kicked " + kick_u,created:Time.now.to_i}.to_json
          id = SecureRandom.hex
          if(eventq.length >= 100)
            rem_event = eventq.shift
            idtodata.delete(rem_event)
            temp_string = "1"+id
            eventq << temp_string
            idtodata[temp_string] = eventdata
          else
            temp_string = "1"+id
            eventq << temp_string
            idtodata[temp_string] = eventdata
          end

          if(myq.length >= 100)
            rem=myq.shift
            msgidtodata.delete(rem)
            tem = "1"+id
            myq << tem
            msgidtodata[tem] = eventdata
          else
            tem = "1"+id
            myq << tem
            msgidtodata[tem] = eventdata
          end

          connections.each do |s|     
            s << "event: ServerStatus\n"
            s << "data: #{eventdata}\n"
            s << "id: #{id}\n\n"
          end

          c.close
          status 201
          return
        end
      else
        ##puts "Kicking no one "
        return 409
      end
    end
  end

  ##puts "Entering past here"
  if(request.params["message"].length == 5)
    if(request.params["message"] == "/quit")
      ##puts "ENTERING QUIT"
      ##puts "The Stream that is closing is " + user_streams[u_name]
      c = str_conn[user_streams[u_name]]
      eventdata = {created:Time.now.to_i}.to_json
      ##puts "NO ERROR 1"
      id = SecureRandom.hex
      if c.nil? != true
        ##puts "FINAL ERROR HERE"
        c << "event: Disconnect\n"
        c << "data: #{eventdata}\n"
        c << "id: #{id}\n\n"
        ##puts "NO ERROR 1"
        c.close
      end
      ##puts "ENTERING CLOSE"
      return 201
    end  
  end

  ##puts "IS IT COMING HERE?"
  if(request.params["message"].length == 10)
    if(request.params["message"] == "/reconnect")
      ##puts "RECONNECT"
      c = str_conn[user_streams[u_name]]
      c.close 
      status 201
      return
    end  
  end

  eventdata = {created:Time.now.to_i,user:u_name,message:request.params["message"]}.to_json
  id = SecureRandom.hex
  if(eventq.length >= 100)
    rem_event = eventq.shift
    idtodata.delete(rem_event)
    temp_string = "6"+id
    eventq << temp_string
    idtodata[temp_string] = eventdata
  else
    temp_string = "6"+id
    eventq << temp_string
    idtodata[temp_string] = eventdata
  end
  
  if(myq.length >= 100)
    rem=myq.shift
    msgidtodata.delete(rem)
    tem = "2"+id
    myq << tem
    msgidtodata[tem] = eventdata
  else
    tem = "2"+id
    myq << tem
    msgidtodata[tem] = eventdata
  end

  connections.each do |s|
    s << "event: Message\n"
    s << "data: #{eventdata}\n"
    s << "id: #{id}\n\n"
  end
  headers 'Token' => new_m_t 
  status 201
  return
end
