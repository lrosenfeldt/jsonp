# frozen_string_literal: true

require "test_helper"

class TestJsonp < Minitest::Test
  def setup
    @lexer = Jsonp::Lexer.new
  end

  def test_that_it_has_a_version_number
    refute_nil ::Jsonp::VERSION
  end

  # def test_lexer_tokenizes_empty_input
  #   tokens = @lexer.lex ""
  #   assert_equal [], tokens
  # end
  def test_lexer_tokenizes_null
    tokens = @lexer.lex "null"
    assert_equal [Jsonp::TokenNull.new], tokens
  end

  def test_lexer_tokenizes_true
    tokens = @lexer.lex "true"
    assert_equal [Jsonp::TokenTrue.new], tokens
  end

  def test_lexer_tokenizes_false
    tokens = @lexer.lex "false"
    assert_equal [Jsonp::TokenFalse.new], tokens
  end

  def test_lexer_tokenizes_array_of_literals
    tokens = @lexer.lex "[true, [null, true], false, []]"
    expected = [
      Jsonp::TokenLBracket.new,
      Jsonp::TokenTrue.new,
      Jsonp::TokenComma.new,
      Jsonp::TokenLBracket.new,
      Jsonp::TokenNull.new,
      Jsonp::TokenComma.new,
      Jsonp::TokenTrue.new,
      Jsonp::TokenRBracket.new,
      Jsonp::TokenComma.new,
      Jsonp::TokenFalse.new,
      Jsonp::TokenComma.new,
      Jsonp::TokenLBracket.new,
      Jsonp::TokenRBracket.new,
      Jsonp::TokenRBracket.new
    ]

    assert_equal expected, tokens
  end

  def test_lexer_tokenize_key_value_pair
    tokens = @lexer.lex %({ "name": "value" })
    expected = [
      Jsonp::TokenLCurly.new,
      Jsonp::TokenString.new("name"),
      Jsonp::TokenColon.new,
      Jsonp::TokenString.new("value"),
      Jsonp::TokenRCurly.new
    ]

    assert_equal expected, tokens
  end

  def test_lexer_tokenizes_object
    tokens = @lexer.lex %({ "name": "jsonp", "version": 14, "isDebug": true, "releaseUrl": null, "tags": ["json", "parser"] })
    expected = [
      Jsonp::TokenLCurly.new,
      Jsonp::TokenString.new("name"),
      Jsonp::TokenColon.new,
      Jsonp::TokenString.new("jsonp"),
      Jsonp::TokenComma.new,
      Jsonp::TokenString.new("version"),
      Jsonp::TokenColon.new,
      Jsonp::TokenNumber.new("14"),
      Jsonp::TokenComma.new,
      Jsonp::TokenString.new("isDebug"),
      Jsonp::TokenColon.new,
      Jsonp::TokenTrue.new,
      Jsonp::TokenComma.new,
      Jsonp::TokenString.new("releaseUrl"),
      Jsonp::TokenColon.new,
      Jsonp::TokenNull.new,
      Jsonp::TokenComma.new,
      Jsonp::TokenString.new("tags"),
      Jsonp::TokenColon.new,
      Jsonp::TokenLBracket.new,
      Jsonp::TokenString.new("json"),
      Jsonp::TokenComma.new,
      Jsonp::TokenString.new("parser"),
      Jsonp::TokenRBracket.new,
      Jsonp::TokenRCurly.new
    ]

    assert_equal expected, tokens
  end

  def test_parser_parses
    input = %({ "name": "jsonp", "version": 14, "isDebug": true, "releaseUrl": null, "tags": ["json", "parser"] })
    expected = Jsonp::ObjectNode.new
    expected.set("name", Jsonp::ValueNode.new("jsonp"))
    expected.set("version", Jsonp::ValueNode.new(14))
    expected.set("isDebug", Jsonp::ValueNode.new(true))
    expected.set("releaseUrl", Jsonp::ValueNode.new(nil))
    tags_node = Jsonp::ArrayNode.new
    tags_node << Jsonp::ValueNode.new("json")
    tags_node << Jsonp::ValueNode.new("parser")
    expected.set("tags", tags_node)

    parser = Jsonp::Parser.new

    assert_equal expected, parser.parse(input)
  end
end
