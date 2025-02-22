# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2018-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'minitest/autorun'
require 'yaml'
require_relative '../lib/telepost'

# Telepost test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2018-2025 Yegor Bugayenko
# License:: MIT
class TelepostTest < Minitest::Test
  def test_fake_posting
    tp = Telepost::Fake.new
    tp.run
    tp.post('This is', 'a simple', 'message')
    assert_equal(1, tp.sent.count)
  end

  def test_real_posting
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
