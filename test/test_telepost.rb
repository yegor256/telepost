# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2018-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'yaml'
require_relative 'test__helper'
require_relative '../lib/telepost'

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
    stub_request(:post, 'https://api.telegram.org/botxx/getUpdates')
      .to_return(status: 200, body: '{}')
    tp = Telepost.new('xx')
    t =
      Thread.new do
        tp.run do |chat, msg|
          # we'll never reach this point
        end
      end
    t.terminate
    t.join
  end

  def test_real_posting
    WebMock.enable_net_connect!
    cfg = '/code/home/assets/zerocracy/baza.yml'
    skip unless File.exist?(cfg)
    yaml = YAML.safe_load_file(cfg)
    tp = Telepost.new(
      yaml['tg']['token'],
      chats: [yaml['tg']['admin_chat'].to_i]
    )
    tp.spam('This is just a test message from telepost test')
  end
end
