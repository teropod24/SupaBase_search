// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supersearch/screens/search/tile.dart';
import 'package:supersearch/style.dart';

class Search extends StatefulWidget {
  const Search({super.key});

  @override
  State<Search> createState() => _SearchState();
}

class _SearchState extends State<Search> {
  List<String>? _results;
  String _input = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Search Users'), backgroundColor: Colors.red,
        ),
        body: Column(children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: TextFormField(
                style: Theme.of(context).textTheme.bodyLarge,
                onChanged: _onSearchFieldChanged,
                autocorrect: false,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: "Name",
                  hintStyle: placeholderTextFieldStyle,
                  border: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                )),
          ),
          Expanded(
              child: (_results ?? []).isNotEmpty
                  ? GridView.count(
                      childAspectRatio: 1,
                      crossAxisCount: 2,
                      padding: const EdgeInsets.all(2.0),
                      mainAxisSpacing: 1.0,
                      crossAxisSpacing: 1.0,
                      children: _results!.map((r) => Tile(r)).toList())
                  : Padding(
                      padding: const EdgeInsets.only(top: 200),
                      child: _results == null
                          ? Container()
                          : Text("No results for '$_input'",
                              style: Theme.of(context).textTheme.bodySmall))),
        ]));
  }

  /// Handles user entering text into the search field. We kick off a search for
  /// every letter typed.
  _onSearchFieldChanged(String value) async {
    setState(() {
      _input = value;
      if (value.isEmpty) {
        // null is a sentinal value that allows us more control the UI
        // for a better user experience. instead of showing 'No results for ''",
        // if this is null, it will just show nothing
        _results = null;
      }
    });

    final results = await _searchUsers(value);

    setState(() {
      _results = results;
    });
  }

  /// Searches our user database via the supabase_flutter package.
  ///
  /// Returns a list of user names.
  ///
  /// WARNING:
  /// - in a more realistic example, this would be moved to a "repository" instead
  ///   optionally with something like a FutureBuilder
  /// - check fluttercrashcourse.com for tutorials on these concepts
  Future<List<String>> _searchUsers(String name) async {
    // here, we leverage Supabase's (Postgres') full text search feature
    // for super fast text searching without the need for something overkill for
    // an example like this such as ElasticSearch or Algolia
    //
    // more info on Supabase's full text search here
    // https://supabase.com/docs/guides/database/full-text-search

    // WARNING: we aren't doing proper error handling here,
    // as this is an example but typically we'd handle any exceptions via the
    // callee of this function
    // NOTE: this seaches our 'fts' (full text search column)
    // NOTE: 'limit()' will improve the performance of the call as well.
    // normally, we'd use a proper backend search index that would provide
    // us with the most relevant results, vs simply using a wildcard match
    final result = await Supabase.instance.client
        .from('names')
        .select('fname, lname')
        .textSearch('fts', "$name:*")
        .limit(100)
        .execute();

    // WARNING: we aren't doing proper response error code handling here.
    // normally, we're present some kind of feedback to the user if this fails
    // and optionally report it to an external tracking system such as Sentry,
    // Rollbar, etc
    if (result.data == null) {
      // ignore: avoid_print
      print('error: ${result.data.toString()}');
      return [];
    }

    final List<String> names = [];

    // convert results into a list here
    // 'result.data' is a list of Maps, where each map represents a returned
    // row in our database. each key of the map represents a table column
    for (var v in ((result.data ?? []) as List<dynamic>)) {
      // NOTE: string formatting over many items can be a tad resource intensive
      // but since this is across a limited set of results, it should be fine.
      // alternatively, we can format this directly in the supabase query
      names.add("${v['fname']} ${v['lname']}");
    }
    return names;
  }
}
