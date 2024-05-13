import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      routes: {
        '/': (context) => const MyHomePage(title: 'Login'),
        '/home': (context) => const HomePage(username: 'brianbaker232'),
        '/create-post': (context) => const CreatePostPage(username: 'brianbaker232'),
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _errorMessage = '';
  late Future<String> _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _profileImageUrl = fetchProfileImageUrl();
  }

  Future<String> fetchProfileImageUrl() async {
    final response = await http.get(Uri.parse('http://192.168.56.1:3000/logo.jpg'));
    if (response.statusCode == 200) {
      var jsonResponse = json.decode(response.body);
      return jsonResponse['results'][0]['picture']['large'];
    } else {
      throw Exception('Failed to load profile image');
    }
  }

  void _login(BuildContext context) {
    if (_usernameController.text == 'brianbaker232' &&
        _passwordController.text == 'password') {
      Navigator.pushNamed(context, '/home');
    } else {
      setState(() {
        _errorMessage = 'Invalid username or password';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            FutureBuilder<String>(
              future: _profileImageUrl,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return const Icon(Icons.broken_image, size: 100);
                } else {
                  return CircleAvatar(
                    radius: 50,
                    backgroundImage: NetworkImage(snapshot.data!),
                  );
                }
              },
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Username or Email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 10),
            Text(
              _errorMessage,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _login(context),
              child: const Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.username});

  final String username;

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<Post>> _postsFuture;

  Future<List<Post>> fetchPosts() async {
    final response = await http.get(Uri.parse('http://192.168.56.1:3000/posts'));

    if (response.statusCode == 200) {
      List jsonResponse = json.decode(response.body);
      return jsonResponse.map((post) => Post.fromJson(post)).toList();
    } else {
      throw Exception('Failed to load posts');
    }
  }

  Future<void> toggleLike(int postId) async {
    final response = await http.get(
      Uri.parse('http://192.168.56.1:3000/posts/like?postId=$postId&username=${widget.username}'),
    );

    if (response.statusCode == 200) {
      setState(() {
        _postsFuture = fetchPosts();
      });
    }
  }

  Future<void> postComment(int postId, String comment) async {
    final response = await http.get(
      Uri.parse('http://192.168.56.1:3000/posts/comment?postId=$postId&username=${widget.username}&comment=$comment'),
    );

    if (response.statusCode == 200) {
      setState(() {
        _postsFuture = fetchPosts();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to post comment')),
      );
    }
  }

  void _showCommentsDialog(BuildContext context, List<Comment> comments) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('All Comments'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              itemCount: comments.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: const Icon(Icons.account_circle),
                  title: Text(comments[index].username),
                  subtitle: Text(comments[index].comment),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _postsFuture = fetchPosts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Life Story',
          style: TextStyle(color: Colors.black),
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.camera_alt),
            color: Colors.black,
            onPressed: () async {
              final result = await Navigator.pushNamed(context, '/create-post');
              if (result == true) {
                setState(() {
                  _postsFuture = fetchPosts();
                });
              }
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Post>>(
        future: _postsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No posts found'));
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final post = snapshot.data![index];
                final bool userHasLiked = post.likes.any((like) => like.username == widget.username);
                final likeIconColor = userHasLiked ? Colors.red : Colors.black;
                final List<Comment> displayedComments = post.comments.take(3).toList();
                final TextEditingController _commentController = TextEditingController();

                return Column(
                  children: <Widget>[
                    ListTile(
                      leading: const Icon(Icons.account_circle, size: 50.0),
                      title: Text(post.username),
                      trailing: const Icon(Icons.more_vert),
                    ),
                    Container(
                      height: 300.0,
                      child: Image.network(
                        post.imageURL,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.broken_image, size: 100),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          IconButton(
                            icon: Icon(Icons.favorite, color: likeIconColor),
                            onPressed: () => toggleLike(post.id),
                          ),
                          const SizedBox(width: 8),
                          Text('${post.likes.length} likes'),
                          const SizedBox(width: 8),
                          const Icon(Icons.comment),
                        ],
                      ),
                    ),
                    for (var comment in displayedComments)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
                        child: ListTile(
                          leading: const Icon(Icons.account_circle, size: 30.0),
                          title: Text(
                            comment.username,
                            style: const TextStyle(fontSize: 14),
                          ),
                          subtitle: Text(
                            comment.comment,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: InkWell(
                        onTap: () => _showCommentsDialog(context, post.comments),
                        child: const Text(
                          'View all comments',
                          style: TextStyle(color: Colors.blue),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _commentController,
                              decoration: const InputDecoration(
                                hintText: 'Add a comment...',
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.send, color: Colors.blue),
                            onPressed: () {
                              if (_commentController.text.isNotEmpty) {
                                postComment(post.id, _commentController.text);
                                _commentController.clear();
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                );
              },
            );
          }
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_box),
            label: 'Upload',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Activity',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'Profile',
          ),
        ],
        selectedItemColor: Colors.amber[800],
      ),
    );
  }
}

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key, required this.username});

  final String username;

  @override
  _CreatePostPageState createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  File? _image;
  final TextEditingController _commentController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final pickedFile = await showDialog<XFile?>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Choose Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () async {
                  final file = await _picker.pickImage(source: ImageSource.camera);
                  Navigator.pop(context, file);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () async {
                  final file = await _picker.pickImage(source: ImageSource.gallery);
                  Navigator.pop(context, file);
                },
              ),
            ],
          ),
        );
      },
    );

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No image selected')),
      );
    }
  }

  Future<void> _submitPost() async {
    if (_image == null || _commentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add an image and a comment')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final request = http.MultipartRequest('POST', Uri.parse('http://192.168.56.1:3000/post?comment=${_commentController.text}&username=${widget.username}'))
      ..files.add(await http.MultipartFile.fromPath('image', _image!.path));

    final response = await request.send();

    setState(() {
      _isLoading = false;
    });

    if (response.statusCode == 200) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to post. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Post'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_image != null)
              Image.file(_image!, height: 200, fit: BoxFit.cover)
            else
              const SizedBox(
                height: 200,
                child: Center(child: Text('No image selected')),
              ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _pickImage,
              child: const Text('Pick Image'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _commentController,
              decoration: const InputDecoration(
                labelText: 'Comment',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
              onPressed: _submitPost,
              child: const Text('Post'),
            ),
          ],
        ),
      ),
    );
  }
}

class Post {
  final int id;
  final String imageURL;
  final List<Like> likes;
  final List<Comment> comments;
  final String username;

  Post({
    required this.id,
    required this.imageURL,
    required this.likes,
    required this.comments,
    required this.username,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'],
      imageURL: json['imageURL'],
      likes: (json['likes'] as List).map((like) => Like.fromJson(like)).toList(),
      comments: (json['comments'] as List)
          .map((comment) => Comment.fromJson(comment))
          .toList(),
      username: json['username'],
    );
  }
}

class Like {
  final int id;
  final String username;

  Like({
    required this.id,
    required this.username,
  });

  factory Like.fromJson(Map<String, dynamic> json) {
    return Like(
      id: json['id'],
      username: json['username'],
    );
  }
}

class Comment {
  final int id;
  final String username;
  final String comment;

  Comment({
    required this.id,
    required this.username,
    required this.comment,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'],
      username: json['username'],
      comment: json['comment'],
    );
  }
}
