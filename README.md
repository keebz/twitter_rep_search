twitter_rep_search
==================
#@whosmyrep
This app functions as a search tool for twitter users. Users can tweet @whosmyrep with a hastag of a state (eg. #TN or #ohio) and they will get a repsonse with the contact information of their senators and governors.

##Authors
[Keebz](http://github.com/keebz) and [Diane Douglas](http://github.com/DianeDouglas) and 

##Setup
In your terminal, clone this repo:

Make sure you've installed [postgres](http://www.postgresql.org/download/) and have started the server:

```console
$ postgres
```

Install all the dependencies:

```console
$ bundle install
```

Set up the databases on your local machine:

```console
$ rake db:create
$ rake db:schema:load
```

Finally, start the rails server:

```console
$ ruby whosmyrep.rb
```
##License
MIT
