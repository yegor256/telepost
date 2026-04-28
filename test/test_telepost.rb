# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2018-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'tmpdir'
require 'yaml'
require_relative '../lib/telepost'
require_relative 'test__helper'

# Telepost test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2018-2026 Yegor Bugayenko
# License:: MIT
class TelepostTest < Minitest::Test
  def test_fake_posting
    tp = Telepost::Fake.new
    tp.run
    tp.post(123, 'This is', 'a simple', 'message')
    assert_equal(1, tp.sent.count)
  end

  def test_fake_spam
    tp = Telepost::Fake.new
    tp.spam('how are you all?')
  end

  def test_fake_attaches
    Dir.mktmpdir do |dir|
      file = File.join(dir, 'dump.txt')
      File.write(file, 'payload')
      tp = Telepost::Fake.new
      tp.attach(77, file, caption: 'logs')
      assert_equal(1, tp.sent.count, 'attachment was not recorded by Fake')
    end
  end

  def test_fake_attach_format_is_recognizable
    Dir.mktmpdir do |dir|
      file = File.join(dir, 'snapshot.sql')
      File.write(file, 'select 1')
      tp = Telepost::Fake.new
      tp.attach(99, file)
      refute_nil(tp.sent.first[/snapshot\.sql/], 'basename is missing from Fake record')
    end
  end

  def test_sends_attachment
    WebMock.disable_net_connect!
    stub_request(:post, 'https://api.telegram.org/botfoo/sendDocument').to_return(body: '{}')
    Dir.mktmpdir do |dir|
      file = File.join(dir, 'note.txt')
      File.write(file, 'hi there')
      tp = Telepost.new('foo')
      tp.attach(42, file, caption: 'see attached')
    end
  end

  def test_sends_attachment_with_io
    WebMock.disable_net_connect!
    stub_request(:post, 'https://api.telegram.org/botbar/sendDocument').to_return(body: '{}')
    Dir.mktmpdir do |dir|
      path = File.join(dir, 'data.bin')
      File.write(path, 'x')
      File.open(path, 'rb') do |io|
        tp = Telepost.new('bar')
        tp.attach(7, io)
      end
    end
  end

  def test_sends_single_message
    WebMock.disable_net_connect!
    stub_request(:post, 'https://api.telegram.org/botfoo/sendMessage').to_return(body: '{}')
    tp = Telepost.new('foo')
    tp.post(42, 'hello!')
  end

  def test_sends_simple_spam
    WebMock.disable_net_connect!
    stub_request(:post, 'https://api.telegram.org/bottoken/sendMessage').to_return(body: '{}')
    tp = Telepost.new('token', chats: [42])
    tp.spam('hey!')
  end

  def test_listens
    WebMock.disable_net_connect!
    stub_request(:post, 'https://api.telegram.org/botxx/getUpdates').to_return(status: 200, body: '{}')
    tp = Telepost.new('xx')
    t =
      Thread.new do
        tp.run { |_chat, _msg| nil }
      end
    t.terminate
    t.join
  end

  def test_skips_nil_message_when_listening
    tp = Telepost.new('xx')
    bot = Object.new
    bot.define_singleton_method(:listen) { |&blk| blk.call(nil) }
    tp.instance_variable_set(:@bot, bot)
    invoked = false
    tp.run { |_chat, _msg| invoked = true }
    refute(invoked, 'block must not be invoked when telegram delivers a nil update payload')
  end

  def test_skips_message_without_chat_when_listening
    tp = Telepost.new('xx')
    bot = Object.new
    bot.define_singleton_method(:listen) { |&blk| blk.call(Object.new) }
    tp.instance_variable_set(:@bot, bot)
    invoked = false
    tp.run { |_chat, _msg| invoked = true }
    refute(invoked, 'block must not be invoked when the update carries no chat')
  end

  def test_yields_chat_id_and_text_when_listening
    tp = Telepost.new('xx')
    msg = Struct.new(:chat, :text).new(Struct.new(:id).new(7), 'hello')
    bot = Object.new
    bot.define_singleton_method(:listen) { |&blk| blk.call(msg) }
    tp.instance_variable_set(:@bot, bot)
    seen = nil
    tp.run { |chat, text| seen = [chat, text] }
    assert_equal([7, 'hello'], seen, 'chat id and text were not delivered to the block')
  end

  def test_real_posting
    WebMock.enable_net_connect!
    cfg = '/code/home/assets/zerocracy/baza.yml'
    skip unless File.exist?(cfg)
    yaml = YAML.safe_load_file(cfg)
    tp = Telepost.new(yaml['tg']['token'], chats: [Integer(yaml['tg']['admin_chat'].to_s, 10)])
    tp.spam('This is just a test message from telepost test')
  end
end
