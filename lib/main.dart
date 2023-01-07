import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GitHub Repositories',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int page = 1;
  int perPage = 30;
  String searchQuery = '';
  String user = 'karthik-dasari';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('GitHub Repositories'),
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Search repositories',
            ),
            onChanged: (query) {
              setState(() {
                searchQuery = query;
                page = 1;
              });
            },
          ),
        ),
        Expanded(
            child: FutureBuilder<dynamic>(
                future: getRepositories(user),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return ListView.builder(
                      itemCount: snapshot.data!.length + 1,
                      itemBuilder: (context, index) {
                        if (index == snapshot.data!.length) {
                          return Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ElevatedButton(
                              child: Text('Load more'),
                              onPressed: () {
                                setState(() {
                                  page++;
                                });
                              },
                            ),
                          );
                        }
                        Repository repository = snapshot.data![index];
                        return FutureBuilder<Commit>(
                          future: getLastCommit(user, repository.name),
                          builder: (context, commitSnapshot) {
                            if (commitSnapshot.hasData) {
                              Commit? commit = commitSnapshot.data;
                              return ListTile(
                                title: Text(repository.name),
                                subtitle: Text(commit!.message),
                                trailing: Text(commit.author),
                              );
                            } else if (commitSnapshot.hasError) {
                              return Text('${commitSnapshot.error}');
                            }
                            return CircularProgressIndicator();
                          },
                        );
                      },
                    );
                  }
                  return FutureBuilder<dynamic>(
                    future: getRepositories(user),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return ListView.builder(
                          itemCount: snapshot.data!.length,
                          itemBuilder: (context, index) {
                            Repository repository = snapshot.data![index];
                            return ListTile(
                              title: Text(repository.name),
                              subtitle: Text(repository.description),
                            );
                          },
                        );
                      } else if (snapshot.hasError) {
                        return Text('${snapshot.error}');
                      }
                      return CircularProgressIndicator();
                    },
                  );
                }))
      ]),
    );
  }

  Future<dynamic> getRepositories(String user) async {
    var response = await http.get(Uri.parse(
        'https://api.github.com/search/repositories?q=$searchQuery+user:$user'));
    if (response.statusCode == 200) {
      Map<String, dynamic> data = jsonDecode(response.body);
      return data['items'].map((repo) => Repository.fromJson(repo)).toList();
    } else {
      throw Exception('Failed to load repositories');
    }
  }

  Future<Commit> getLastCommit(String user, String repo) async {
    var response = await http
        .get(Uri.parse('https://api.github.com/repos/$user/$repo/commits'));
    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return Commit.fromJson(data[0]);
    } else {
      throw Exception('Failed to load commit');
    }
  }
}

class Repository {
  final String name;
  final String description;

  Repository({required this.name, required this.description});

  factory Repository.fromJson(Map<String, dynamic> json) {
    return Repository(
      name: json['name'],
      description: json['description'],
    );
  }
}

class Commit {
  final String message;
  final String author;

  Commit({required this.message, required this.author});

  factory Commit.fromJson(Map<String, dynamic> json) {
    return Commit(
      message: json['commit']['message'],
      author: json['commit']['author']['name'],
    );
  }
}
