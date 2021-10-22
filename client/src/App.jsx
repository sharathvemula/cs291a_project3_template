import React, { Component } from "react";
import './index.css';
import ReactDOM from 'react-dom';
var users = new Set()
var messages =  []
var message_token = ""
var childData;

function date_format(timestamp) {
    var date = new Date(timestamp * 1000);
    return date.toLocaleDateString("en-US") + " " + date.toLocaleTimeString("en-US");
}

class MessageList extends React.Component {
  constructor(props) {
    super(props);
    this.state = {msg: []};
    this.myRef = React.createRef();
  }

  componentDidMount() {
    this.myRef.current.scrollIntoView({ behavior: 'smooth' })
  }

  componentDidUpdate() {
    this.myRef.current.scrollIntoView({ behavior: 'smooth' })
  }

  update_msg(){
    this.setState({msg: messages})

  }

  null_msg(){
    this.setState({msg: []});
  }

  render() {
    return(
      <div id="chat">
        <div >
          {
            this.state.msg && Array.from(this.state.msg).map((item) =>
            <div>{item}</div>
          )}
        </div>
        <div ref = {this.myRef}> </div>
    </div>
    );
  }
}

class UserList extends React.Component {
  constructor(props) {
    super(props);
    this.state = {cur_users: new Set()};
  }

  update_users(){
    this.setState({cur_users: users});
  }

  render() {
    return(
      <div id="user_window">
        <h2>Online</h2>
          <ul>
            {
              Array.from(this.state.cur_users).sort().map((item) =>
              <li id="users">{item}</li>
            )}
          </ul>
      </div>
    );
  }
}


class LoginForm1 extends React.Component {
  constructor(props) {
    super(props);
    this.state = {url: '', username: '', password: '', display: true, message_token: '', streamToken:''};

    this.handleChange = this.handleChange.bind(this);
    this.handleSubmit = this.handleSubmit.bind(this);
    this.changedis = this.changedis.bind(this);
    this.startStream = this.startStream.bind(this);
    //this.function = this.function.bind(this);
  }

  handleChange(event) {
    if(event.target.name === "url"){
      this.setState({url: event.target.value});
    }

    if(event.target.name === "username"){
      this.setState({username: event.target.value});
    }

    if(event.target.name === "password"){
      this.setState({password: event.target.value});
    }
    
  }

  startStream(that) {
    console.log("URL" + that.state.url);
    console.log("MSG Token" + that.state.message_token);
    console.log("STR token" + that.state.streamToken);
    var streamToken = that.state.streamToken
    var messageToken = that.state.message_token
    message_token = messageToken
    const stream = new EventSource(
        sessionStorage.getItem("url") + "/stream/" + streamToken
    );

    stream.addEventListener(
        "open",
        function(_event) {
          that.setState({display: false});
          that.props.handle_connect()
        }
    );
    stream.addEventListener(
        "Disconnect",
        function(_event) {
            console.log("COMING HERE: 103")
            console.log ("CLOSING STREAM: " + streamToken)
            stream.close();
            users = new Set();
            that.props.parentcall();
            streamToken = null;
            messageToken = null;
            that.state.messageToken = null;
            that.state.streamToken = null;
            that.props.thirdcall();
            messages = [];
            console.log("Disconnect reached");
            that.setState({display: true});
            that.setState({url: ""});
            that.setState({username: ""});
            that.setState({password: ""});
            that.props.handle_disconnect();
        },
        false
    );
    stream.addEventListener(
        "Join",
        function(event) {
            var data = JSON.parse(event.data);
            console.log("User: "+ data.user)
            users.add(data["user"]);
            that.props.parentcall();
            messages.push(date_format(data["created"]) + " JOIN: " + data.user);
            that.props.secondcall();
        },
        false
    );
    stream.addEventListener(
        "Message",
        function(event) {
            var data = JSON.parse(event.data);
            messages.push(date_format(data["created"]) + " (" + data.user + ") " + data.message);
            that.props.secondcall();
        },
        false
    );
    stream.addEventListener(
        "Part",
        function(event) {
            var data = JSON.parse(event.data);
            console.log("DELeting User: "+ data.user)
            users.delete(data.user);
            that.props.parentcall();
            messages.push(date_format(data["created"]) + " PART: " + data.user);
            that.props.secondcall();
        },
        false
    );
    stream.addEventListener(
        "ServerStatus",
        function(event) {
            console.log("Coming here ServerStatus line 147")
            var data = JSON.parse(event.data);
            messages.push(date_format(data["created"]) + " STATUS: " + data.status);
            that.props.secondcall();
        },
        false
    );
    stream.addEventListener(
        "Users",
        function(event) {
            users = new Set(JSON.parse(event.data).users);
            that.props.parentcall();
        },
        false
    );
    stream.addEventListener(
        "error",
        function(event) {
            if (event.target.readyState == 2) {
                that.state.messageToken = null;
                that.state.streamToken = null;
                console.log("Disconnect reached at error")
                that.setState({display: true});
                that.setState({url: ""});
                that.setState({username: ""});
                that.setState({password: ""});
                users = new Set();
                that.props.parentcall();
                that.props.handle_disconnect();
            } else {
                that.props.handle_disconnect();
                console.log("Disconnected, retrying");
            }
        },
        false
    );
    
  }

  start(data) {
    console.log("MSG token:");
    console.log(data["message_token"]);
    this.setState({display: false});
  }

  changedis(){
    console.log("Sharath");
    this.setState({display: false});
  }


  handleSubmit(event) {
    console.log(this.state.username);
    const that = this;
    var request = new XMLHttpRequest();
    var form1 = new FormData();
    form1.append("password", this.state.password);
    form1.append("username", this.state.username);
    sessionStorage.setItem("url", this.state.url);
    console.log("TEST");
    request.open("POST", sessionStorage.getItem("url") + "/login");
    //request.setRequestHeader('Access-Control-Allow-Origin', '*');
    request.onreadystatechange = function() {
      console.log("TEST1");
      if (request.readyState != 4) {
        console.log("TEST3");
        return;
      }
      console.log("Ready State " + this.readyState);
      if (request.status === 201) {
          console.log("TEST2");
          that.changedis();
          that.state.password = "";
          that.state.password  = "";
          const data = JSON.parse(this.responseText);
          that.state.message_token = data.message_token;
          console.log(data.message_token);
          that.state.streamToken = data.stream_token;
          that.startStream(that);
      } else if (request.status === 403) {
          alert("Invalid username or password");
      } else if (request.status === 409) {
          alert(that.state.username + " is already logged in");

      } else {
          alert(request.status + " failure to /login");
      }
    }
    request.send(form1);

    event.preventDefault();

  }
  render() {
    return (
      <form onSubmit={this.handleSubmit}>
        <div id = "login-modal" class= {this.state.display ? "login" : "hide"}>
          <div class = "content" >
          <h2 > Login </h2>
          <div>
            <label>
              URL:
              <input name="url" type="text" value={this.state.url} onChange={this.handleChange} />
            </label>
          </div>

          <div>
            <label>
              username:
              <input name="username" type="text" value={this.state.username} onChange={this.handleChange} />
            </label>
          </div>


          <div>
            <label>
              Password:
              <input name="password" type="password" value={this.state.password} onChange={this.handleChange} />
            </label>
          </div>

          <div>
            <label>  
              <input type="submit" value="Submit" />
            </label>
          </div>
        </div>
      </div>
      </form>

    );
  }
}



class Compose extends React.Component {
  constructor(props) {
    super(props);  
    this.state = {message: '', display: false};
    this.child1 = React.createRef();
    this.child2 = React.createRef();
    this.handleChange = this.handleChange.bind(this);
    this.handleSubmit = this.handleSubmit.bind(this);
    this.update_usersnlists = this.update_usersnlists.bind(this)
    this.updatemsg = this.updatemsg.bind(this)
    this.nullmsg = this.nullmsg.bind(this)
    this.connect = this.connect.bind(this)
    this.disconnect = this.disconnect.bind(this)
  }

  connect(){
    this.setState({display: true});
  }

  disconnect(){
    this.setState({display: false});
  }

  update_usersnlists(){
    this.child2.current && this.child2.current.update_users();
  }

  updatemsg() {
    this.child1.current && this.child1.current.update_msg();
  }

  nullmsg() {
    this.child1.current.null_msg();
  }

  handleChange(event) {
    if(event.target.name === "message-id"){
      this.setState({message: event.target.value});
    }
    
  }

  handleSubmit(event) {
    console.log(this.state.message);
    event.preventDefault();
    if(this.state.message == "") {
      event.preventDefault();
      return;
    }
    var that = this;
    var request1 = new XMLHttpRequest();
    var form = new FormData();
    form.append("message", this.state.message);
    request1.open("POST", sessionStorage.getItem("url") + "/message");
    request1.setRequestHeader(
        "Authorization",
        "Bearer " + message_token
    );

    request1.onreadystatechange = function(event) {
        console.log("Entering here");
        if (request1.readyState == 4 && request1.status != 403 && message_token != null) {
            message_token = request1.getResponseHeader("token");
            console.log("Message Token" + message_token)
        }
    }
    request1.send(form);
    that.setState({message:""});
  }

  render() {
    return (
      <section id="container">
      <h1 id="title" class= {this.state.display ? "connected" : "disconnected"}>CS291 Chat</h1>
        <div id = "window">
          <MessageList ref={this.child1}/>
          <UserList ref={this.child2}/>
        </div>
      <form onSubmit={this.handleSubmit}>
       <div id="message">
        <label>
          <input name="message-id" size="175" type="text" value={this.state.message} onChange={this.handleChange} />
        </label>
       </div>

       <div>
        <label>  
          <input type="submit" value="Submit" />
        </label>
       </div>
      </form>
      </section>
    );
  }
}




class LoginForm extends React.Component {
  constructor(props) {
    super(props);
    this.child = React.createRef();
    this.handleCallback = this.handleCallback.bind(this)
    this.messageupdate = this.messageupdate.bind(this)
    this.messagenull = this.messagenull.bind(this)
    this.handleconnect = this.handleconnect.bind(this)
    this.handledisconnect = this.handledisconnect.bind(this)
  }

  handleCallback = () => {
    if(this.child.current) { 
      this.child.current.update_usersnlists();
    }
  }

  messageupdate = () => {
    this.child.current && this.child.current.updatemsg();
  }

  messagenull = () => {
    this.child.current && this.child.current.nullmsg();
  }

  handleconnect = () => {
    this.child.current && this.child.current.connect();
  }

  handledisconnect = () => {
    this.child.current && this.child.current.disconnect();
  }

  render() {
    return (
      <div>
        <section id = "container">
            <Compose ref={this.child}/>
        </section>
        <div>
          <LoginForm1 parentcall={this.handleCallback} secondcall={this.messageupdate} thirdcall={this.messagenull} handle_connect={this.handleconnect} handle_disconnect={this.handledisconnect}/>
        </div>
      </div>
    );
  }
}


export default LoginForm;
