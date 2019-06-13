[![EO principles respected here](https://www.elegantobjects.org/badge.svg)](https://www.elegantobjects.org)
[![DevOps By Rultor.com](http://www.rultor.com/b/yegor256/telepost)](http://www.rultor.com/p/yegor256/telepost)
[![We recommend RubyMine](https://www.elegantobjects.org/rubymine.svg)](https://www.jetbrains.com/ruby/)

[![Build Status](https://travis-ci.org/yegor256/telepost.svg)](https://travis-ci.org/yegor256/telepost)
[![Gem Version](https://badge.fury.io/rb/telepost.svg)](http://badge.fury.io/rb/telepost)
[![Maintainability](https://api.codeclimate.com/v1/badges/21aec58faee3866bdfbb/maintainability)](https://codeclimate.com/github/yegor256/telepost/maintainability)
[![Yard Docs](http://img.shields.io/badge/yard-docs-blue.svg)](http://rubydoc.info/github/yegor256/telepost/master/frames)

[![Hits-of-Code](https://hitsofcode.com/github/yegor256/telepost)](https://hitsofcode.com/view/github/yegor256/telepost)

Telepost is a simple gateway to Telegram, which can post messages and respond to primitive requests.

First, get your token from [@BotFather](https://t.me/BotFather).

Then, install it:

```bash
$ gem install telepost
```

Then, use it like this:

```ruby
require 'telepost'
tp = Telepost.new('..token..')
Thread.start do
  tp.run do |chat, msg|
    tp.post(chat, 'Thanks for talking to me!')
  end
end
tp.post(12345, 'How are you?', 'How are you doing?')
```

All lines you provide to the `post()` method will be concatenated
with a space between them.

Or you can pre-configure it to talk to certain list of chats.
Your bot has to be an admin of the channel, in order to post there.
Here is how you "spam":

```ruby
tp = Telepost.new('..token..', chats: ['my_channel'])
tp.spam('How are you?')
```

That's it.

## How to contribute

Read [these guidelines](https://www.yegor256.com/2014/04/15/github-guidelines.html).
Make sure you build is green before you contribute
your pull request. You will need to have [Ruby](https://www.ruby-lang.org/en/) 2.3+ and
[Bundler](https://bundler.io/) installed. Then:

```
$ bundle update
$ bundle exec rake
```

If it's clean and you don't see any error messages, submit your pull request.
