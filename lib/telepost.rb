# frozen_string_literal: true

# (The MIT License)
#
# Copyright (c) 2018 Yegor Bugayenko
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the 'Software'), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

require 'telebot'

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
# Copyright:: Copyright (c) 2018 Yegor Bugayenko
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

    def post(*lines, chat: 0)
      @sent << "#{chat}: #{lines.join(' ')}"
    end
  end

  def initialize(token, chat: 0)
    @token = token
    @client = Telebot::Client.new(token)
    @chat = chat
  end

  def run
    Telebot::Bot.new(@token).run do |chat, message|
      if block_given?
        yield(chat, message)
      else
        post(
          "This is your chat ID: `#{message.chat.id}`.",
          chat: message.chat.id
        )
      end
    end
  end

  def post(*lines, chat: @chat)
    raise 'Default chat ID is not provided in the constuctor' if chat.zero?
    @client.send_message(
      chat_id: chat,
      parse_mode: 'Markdown',
      disable_web_page_preview: true,
      text: lines.join(' ')
    )
  rescue Telebot::Error => e
    raise "#{e.message}: \"#{msg}\""
  end
end
