# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2018-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'telegram/bot'

# Telepost is a simple gateway to Telegram, which can post messages and
# respond to primitive requests:
#
#  require 'telepost'
#  tp = Telepost.new('... secret token ...')
#  tp.run do |chat, msg|
#    # Reply to the message via tp.post(msg, chat)
#  end
#
# For more information read
# {README}[https://github.com/yegor256/telepost/blob/master/README.md] file.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2018-2025 Yegor Bugayenko
# License:: MIT
class Telepost
  # Fake one
  class Fake
    attr_reader :sent

    def initialize
      @sent = []
    end

    def run
      # Nothing to do here
    end

    def spam(*lines)
      post(0, lines)
    end

    def post(chat, *lines)
      @sent << "#{chat}: #{lines.join(' ')}"
    end
  end

  # When can't post a message
  class CantPost < StandardError; end

  # To make it possible to get the client.
  attr_reader :client

  # Makes a new object. To obtain a token you should talk
  # to the @BotFather in Telegram.
  def initialize(token, chats: [])
    @token = token
    @chats = chats
    @bot = Telegram::Bot::Client.new(@token)
  end

  # You can run a chat bot to listen to the messages coming to it, in
  # a separate thread.
  def run
    raise 'Block must be given' unless block_given?
    @bot.listen do |message|
      yield(message.chat.id, message.text)
    end
  rescue Net::OpenTimeout
    retry
  end

  # Send the message (lines will be concatenated with a space
  # between them) to the chats provided in the constructor
  # and encapsulated.
  def spam(*lines)
    @chats.each do |chat|
      post(chat, lines)
    end
  end

  # Post a single message to the designated chat room. The
  # chat argument can either me an integer, if you know the
  # chat ID, or the name of the channel (your bot has to
  # be the admin there). The lines provided will be
  # concatenated with a space between them.
  def post(chat, *lines)
    @bot.api.send_message(
      chat_id: chat,
      parse_mode: 'Markdown',
      disable_web_page_preview: true,
      text: lines.join(' ')
    )
  end
end
