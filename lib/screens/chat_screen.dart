import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flash_chat/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';


final _firestore = FirebaseFirestore.instance;
late User loggedInUser;

class ChatScreen extends StatefulWidget {
  static const String id = 'chat_screen';
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _auth = FirebaseAuth.instance;
  final messageTextController = TextEditingController();

  late String messageText;

  @override
  void initState(){
    super.initState();
    getCurrentUser();

  }
  void getCurrentUser() async {
    try {
      final user = await _auth.currentUser;
      if (user != null) {
        loggedInUser = user;
        print(loggedInUser.email);
      }
    }
    catch(e){
      print(e);
    }
  }


  // void getMessages() async{
  //   final messages = await _firestore.collection('messages').get()
  //       .then((QuerySnapshot querySnapshot) => {
  //   querySnapshot.docs.forEach((doc) {
  //   print(doc.data());
  //       })
  //   });
  // }
  void messagesStream() async{
    await for (var snapshot in _firestore.collection('messages').snapshots()) {
      for (var message in snapshot.docs){
        print(message.data());
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: null,
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                //Implement logout functionality
                // _auth.signOut();
                // Navigator.pop(context);
                // getMessages();
                messagesStream();
              }),
        ],
        title: Text('⚡️Chat'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            MessagesStream(),

            Container(
              decoration: kMessageContainerDecoration,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: messageTextController,
                      style: TextStyle(color: Colors.black),
                      onChanged: (value) {
                        //Do something with the user input.
                        messageText = value;
                      },
                      decoration: kMessageTextFieldDecoration,
                    ),
                  ),
                  FlatButton(
                    onPressed: () {
                      //Implement send functionality.
                      messageTextController.clear();
                      _firestore.collection('messages').add({
                        'text': messageText,
                        'sender': loggedInUser.email,
                        'time': DateTime.now(),
                      });
                    },
                    child: Text(
                      'Send',
                      style: kSendButtonTextStyle,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MessagesStream extends StatelessWidget {
  const MessagesStream({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(

      stream: _firestore.collection('messages').snapshots(),
      builder: (context,snapshot){
        if(snapshot.hasData) {

          final messages = snapshot.data!.docs.reversed;
          List<MessageBubble> messageBubbles=[];
          for(var message in messages) {
            final messageText = (message.data() as Map<String,
                dynamic>)['text'];
            final messageSender = (message.data() as Map<String,
                dynamic>)['sender'];
            final messageTime = (message.data() as Map<String,
                dynamic>)['time'];
            final currentUser = loggedInUser.email;
            if (currentUser == messageSender){

            }
            final messageBubble = MessageBubble(
                sender: messageSender,
                text: messageText,
                time: messageTime,
                isMe: currentUser == messageSender,);
                messageBubbles.add(messageBubble);
                messageBubbles.sort((a , b ) => b.time.compareTo(a.time));

          }


          return Expanded(
            child: ListView(
              reverse: true,
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 20),
              children: messageBubbles,
            ),
          );
        }else if (!snapshot.hasData){
          return Center(
            child: CircularProgressIndicator(
              backgroundColor: Colors.lightBlueAccent,
            ),
          );
        }
        throw '';
      },
    );
  }
}

class MessageBubble extends StatelessWidget {
  MessageBubble({required this.sender, required this.text, required this.isMe, required this.time});
  late final String sender;
  late final String text;
  late final Timestamp time;
  final bool isMe;


  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(sender, style: TextStyle(
              color: Colors.black54,
              fontSize: 12,),),
          Material(
            elevation: 5,
            borderRadius: BorderRadius.only(
                topLeft: isMe ? Radius.circular(30) : Radius.zero,
                topRight: isMe ? Radius.zero : Radius.circular(30),
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30)),
            color: isMe ? Colors.lightBlueAccent : Colors.white,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                child: Text('$text', style: TextStyle(
                    color: isMe ? Colors.white : Colors.black54,
                    fontSize: 15) ),
              )),
        ],
      ),
    );
  }
}
