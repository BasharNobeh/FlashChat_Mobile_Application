// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

final _fireStore = FirebaseFirestore.instance;
late User loggedInUser;

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _auth = FirebaseAuth.instance;

  late String message;
  final myController = TextEditingController();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getUser();
  }

  void getUser() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        loggedInUser = user;
        print("${user.email} is Now Logged In");
      }
    } catch (e) {
      print(e);
    }
  }

  void getMessagesStream() async {
    try {
      await for (var message in _fireStore.collection("messages").snapshots()) {
        for (var text in message.docs) {
          print(text.data());
        }
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("chat"),
        actions: [
          IconButton(
              onPressed: () {
                // getMessagesStream();
                _auth.signOut();
                Navigator.pop(context);
              },
              icon: const Icon(Icons.cancel_outlined))
        ],
      ),
      body: SafeArea(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          MessagesStream(),
          Container(
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                      controller: myController,
                      onChanged: (value) {
                        message = value;
                      },
                      decoration: const InputDecoration(
                        hintText: "Type your message here..",
                      )),
                ),
                TextButton(
                  onPressed: () async {
                    myController.clear();
                    try {
                      await _fireStore
                          .collection("messages")
                          .add({"Sender": loggedInUser.email, "Text": message});
                    } catch (e) {
                      print("$e and error happened");
                    }
                  },
                  child: const Text("Send"),
                )
              ],
            ),
          )
        ],
      )),
    );
  }
}

class MessagesStream extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(
              backgroundColor: Colors.blue,
            ),
          );
        }
        final messages = snapshot.data!.docs.reversed;
        List<TextBubbles> messageBubbles = [];
        for (var element in messages) {
          final messageData = element.data() as Map<String, dynamic>;

          final messageText = messageData["Text"];
          final messageSender = messageData["Sender"];
          final currentUser = loggedInUser.email;

          final messageBubble = TextBubbles(
            sender: messageSender,
            text: messageText,
            isMe: currentUser == messageSender,
          );
          messageBubbles.add(messageBubble);
        }

        return Expanded(
          child: ListView(
            reverse: true,
            children: messageBubbles,
          ),
        );

        return Container();
      },
      stream: _fireStore.collection("messages").snapshots(),
    );
  }
}

class TextBubbles extends StatelessWidget {
  final String text;
  final String sender;
  final bool isMe;
  const TextBubbles({
    required this.text,
    required this.sender,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            sender,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          Material(
            borderRadius: isMe
                ? const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30))
                : const BorderRadius.only(
                    topRight: Radius.circular(30),
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30)),
            elevation: 5,
            color: isMe ? Colors.lightBlueAccent : Colors.white,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              child: Text(
                text,
                style: TextStyle(
                    color: isMe ? Colors.white : Colors.amber, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
