# coding: utf-8
require 'helper'

class TargetTest < TestCase
  module MessageSplit
    Mask = 'msg_split!~msg_split@an-irc-client.some-provider.net'
    Command = 'NOTICE'
    Channel = '#msg_split_test'
    Prefix = ":#{Mask} #{Command} #{Channel} :" # 78 bytes
    MaxBytesize = 510 - Prefix.bytesize
  end

  test 'A short text should not be split' do
    target = Cinch::Target.new(nil, nil)
    short_lorem_ipsum =
      'Lorem ipsum dolor sit amet, consectetur adipiscing elit, ' \
      'sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.'

    actual_chunks = target.__send__(:split_message,
                                    short_lorem_ipsum, MessageSplit::Prefix,
                                    '... ', ' ...')
    expected_chunks = [short_lorem_ipsum]

    assert(expected_chunks.all? { |string|
      string.length < MessageSplit::MaxBytesize
    })
    assert_equal(expected_chunks, actual_chunks)
  end

  test 'A long single-byte text should be split at the correct position' do
    target = Cinch::Target.new(nil, nil)
    lorem_ipsum =
      'Lorem ipsum dolor sit amet, consectetur adipiscing elit, ' \
      'sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. ' \
      'Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris ' \
      'nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in ' \
      'reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla ' \
      'pariatur. Excepteur sint occaecat cupidatat non proident, sunt in ' \
      'culpa qui officia deserunt mollit anim id est laborum.'

    expected_chunks = [
      'Lorem ipsum dolor sit amet, consectetur adipiscing elit, ' \
      'sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. ' \
      'Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris ' \
      'nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in ' \
      'reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla ' \
      'pariatur. Excepteur sint occaecat cupidatat non proident, sunt in ' \
      'culpa qui officia deserunt mollit ...',

      '... anim id est laborum.'
    ]
    actual_chunks = target.__send__(:split_message,
                                    lorem_ipsum, MessageSplit::Prefix,
                                    '... ', ' ...')

    assert(expected_chunks.all? { |string|
      string.length < MessageSplit::MaxBytesize
    })
    assert_equal(expected_chunks, actual_chunks)
  end

  test 'A long multi-byte text should be split at the correct position' do
    target = Cinch::Target.new(nil, nil)
    japanese_text =
      '私はその人を常に先生と呼んでいた。だからここでもただ先生と書く' \
      'だけで本名は打ち明けない。これは世間を憚かる遠慮というよりも、' \
      'その方が私にとって自然だからである。私はその人の記憶を呼び起す' \
      'ごとに、すぐ「先生」といいたくなる。筆を執っても心持は同じ事で' \
      'ある。よそよそしい頭文字などはとても使う気にならない。'

    expected_chunks = [
      '私はその人を常に先生と呼んでいた。だからここでもただ先生と書く' \
      'だけで本名は打ち明けない。これは世間を憚かる遠慮というよりも、' \
      'その方が私にとって自然だからである。私はその人の記憶を呼び起す' \
      'ごとに、すぐ「先生」といいたくなる。筆を執っても心持は同じ事で' \
      'ある。よそよそしい頭文字などはとても ...',

      '... 使う気にならない。'
    ]
    actual_chunks = target.__send__(:split_message,
                                    japanese_text, MessageSplit::Prefix,
                                    '... ', ' ...')

    assert(expected_chunks.all? { |string|
      string.length < MessageSplit::MaxBytesize
    })
    assert_equal(expected_chunks, actual_chunks)
  end

  test 'A very long multi-byte text should be split at the correct position' do
    target = Cinch::Target.new(nil, nil)
    japanese_text =
      'JAPANESE_TEXT:親譲りの無鉄砲で小供の時から損ばかりしている。' \
      '小学校に居る時分学校の二階から飛び降りて一週間ほど腰を抜かした' \
      '事がある。なぜそんな無闇をしたと聞く人があるかも知れぬ。別段深い理由' \
      'でもない。新築の二階から首を出していたら、同級生の一人が冗談に、' \
      'いくら威張っても、そこから飛び降りる事は出来まい。弱虫やーい。' \
      'と囃したからである。小使に負ぶさって帰って来た時、おやじが' \
      '大きな眼をして二階ぐらいから飛び降りて腰を抜かす奴があるかと' \
      '云ったから、この次は抜かさずに飛んで見せますと答えた。親類の' \
      'ものから西洋製のナイフを貰って奇麗な刃を日に翳して、友達に' \
      '見せていたら、一人が光る事は光るが切れそうもないと云った。'

    expected_chunks = [
      'JAPANESE_TEXT:親譲りの無鉄砲で小供の時から損ばかりしている。' \
      '小学校に居る時分学校の二階から飛び降りて一週間ほど腰を抜かした' \
      '事がある。なぜそんな無闇をしたと聞く人があるかも知れぬ。別段深い理由' \
      'でもない。新築の二階から首を出していたら、同級生の一人が冗談に、' \
      'いくら威張っても、そこから飛び降りる ...',

      '... 事は出来まい。弱虫やーい。' \
      'と囃したからである。小使に負ぶさって帰って来た時、おやじが' \
      '大きな眼をして二階ぐらいから飛び降りて腰を抜かす奴があるかと' \
      '云ったから、この次は抜かさずに飛んで見せますと答えた。親類の' \
      'ものから西洋製のナイフを貰って奇麗な刃を日に翳して、友達に' \
      '見せていたら、一人が ...',

      '... 光る事は光るが切れそうもないと云った。'
    ]
    actual_chunks = target.__send__(:split_message,
                                    japanese_text, MessageSplit::Prefix,
                                    '... ', ' ...')

    assert(expected_chunks.all? { |string|
      string.length < MessageSplit::MaxBytesize
    })
    assert_equal(expected_chunks, actual_chunks)
  end
end
