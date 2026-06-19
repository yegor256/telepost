# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2018-2026 Yegor Bugayenko
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
# Copyright:: Copyright (c) 2018-2026 Yegor Bugayenko
# License:: MIT
class Telepost
  # Fake implementation for testing
  #
  # @note Use this class for testing purposes
  class Fake
    attr_reader :sent

    def initialize
      @sent = []
    end

    def run; end

    def spam(*lines)
      post(0, lines)
    end

    def post(chat, *lines)
      @sent << "#{chat}: #{lines.join(' ')}"
    end

    def attach(chat, file, caption: nil)
      @sent <<
        if file.is_a?(Array)
          "#{chat}: [attach-group:#{names(file)}#{cap(caption)}]"
        else
          "#{chat}: [attach:#{names([file])}#{cap(caption)}]"
        end
    end

    private

    def names(files)
      files.map { |f| File.basename(f.is_a?(String) ? f : f.path) }.join(',')
    end

    def cap(caption)
      caption.nil? ? '' : " caption=#{caption}"
    end
  end

  # When can't post a message
  #
  # @note Raised when message posting fails
  class CantPost < StandardError; end

  attr_reader :client

  # Makes a new object. To obtain a token you should talk
  # to the @BotFather in Telegram.
  #
  # @param token [String] Telegram bot token
  # @param chats [Array<Integer>] Optional list of chat IDs
  def initialize(token, chats: [])
    @token = token
    @chats = chats
    @bot = Telegram::Bot::Client.new(@token)
  end

  # You can run a chat bot to listen to the messages coming to it, in
  # a separate thread.
  #
  # @yield [Integer, String] Yields chat ID and message text
  # @return [void]
  # @raise [RuntimeError] If no block is given
  def run
    raise(RuntimeError, 'Block must be given') unless block_given?
    @bot.listen do |message|
      next unless message.respond_to?(:chat)
      next if message.chat.nil?
      yield(message.chat.id, message.respond_to?(:text) ? message.text : '')
    end
  rescue Net::OpenTimeout
    retry
  end

  # Send the message (lines will be concatenated with a space
  # between them) to the chats provided in the constructor
  # and encapsulated.
  #
  # @param lines [Array<String>] Message lines to send
  # @return [void]
  def spam(*lines)
    @chats.each do |chat|
      post(chat, *lines)
    end
  end

  # Post a single message to the designated chat room. The
  # chat argument can either be an integer, if you know the
  # chat ID, or the name of the channel (your bot has to
  # be the admin there). The lines provided will be
  # concatenated with a space between them.
  #
  # @param chat [Integer, String] Chat ID or channel name
  # @param lines [Array<String>] Message lines to send
  # @return [Telegram::Bot::Types::Message] The sent message object
  def post(chat, *lines, parse_mode: 'Markdown')
    @bot.api.send_message(chat_id: chat, parse_mode:, disable_web_page_preview: true, text: lines.join(' '))
  end

  # Attach a file (as a Telegram document) to the chat. The file
  # argument can either be a path (String) or an open IO/File. The
  # filename shown in Telegram comes from the basename of the path.
  #
  # When +file+ is an +Array+, all of its items are posted as a single
  # grouped message (a Telegram "album") via +sendMediaGroup+. Items
  # with an image extension are wrapped in +InputMediaPhoto+, the rest
  # in +InputMediaDocument+. The +caption+ is attached to the first
  # item only, so the album shows one caption.
  #
  # @param chat [Integer, String] Chat ID or channel name
  # @param file [String, File, IO, Array] File (or array of files) to attach
  # @param caption [String, nil] Optional caption for the attachment
  # @param parse_mode [String] Parse mode used for the caption
  # @return [Telegram::Bot::Types::Message] The sent message object
  def attach(chat, file, caption: nil, parse_mode: 'Markdown')
    return album(chat, file, caption:, parse_mode:) if file.is_a?(Array)
    @bot.api.send_document(chat_id: chat, document: upload(file), caption:, parse_mode:)
  end

  PHOTO_EXTENSIONS = %w[.jpg .jpeg .png .gif .webp].freeze

  private

  def album(chat, files, caption: nil, parse_mode: 'Markdown')
    params = { chat_id: chat }
    params[:media] =
      files.each_with_index.map do |file, idx|
        params[:"file#{idx}"] = upload(file)
        attrs = { media: "attach://file#{idx}" }
        if idx.zero? && !caption.nil?
          attrs[:caption] = caption
          attrs[:parse_mode] = parse_mode
        end
        klass(file).new(**attrs)
      end
    @bot.api.send_media_group(**params)
  end

  def upload(file)
    return file unless file.is_a?(String)
    Faraday::UploadIO.new(file, 'application/octet-stream', File.basename(file))
  end

  def klass(file)
    photo?(file) ? Telegram::Bot::Types::InputMediaPhoto : Telegram::Bot::Types::InputMediaDocument
  end

  def photo?(file)
    PHOTO_EXTENSIONS.include?(File.extname(file.is_a?(String) ? file : file.path).downcase)
  end
end
