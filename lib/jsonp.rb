# frozen_string_literal: true

require_relative "jsonp/version"

module Jsonp
  class Error < StandardError; end

  class Token
    attr_reader :literal

    def initialize(literal = nil)
      @literal = literal
    end

    def ==(other)
      self.class == other.class
    end

    def value
      raise Error.new, "Cannot unwrap empty token #{token}" if @literal.nil?

      @literal
    end
  end

  class TokenNull < Token
    def to_s
      "Token(null)"
    end
  end

  class TokenFalse < Token
    def to_s
      "Token(false)"
    end
  end

  class TokenTrue < Token
    def to_s
      "Token(true)"
    end
  end

  class TokenLCurly < Token
    def to_s
      "Token({)"
    end
  end

  class TokenRCurly < Token
    def to_s
      "Token(})"
    end
  end

  class TokenLBracket < Token
    def to_s
      "Token([)"
    end
  end

  class TokenRBracket < Token
    def to_s
      "Token(])"
    end
  end

  class TokenColon < Token
    def to_s
      "Token(:)"
    end
  end

  class TokenComma < Token
    def to_s
      "Token(,)"
    end
  end

  class TokenString < Token
    def ==(other)
      self.class == other.class && @literal == other.literal
    end

    def to_s
      "Token(string, \"#{@literal}\")"
    end
  end

  class TokenNumber < Token
    def ==(other)
      self.class == other.class && @literal == other.literal
    end

    def to_s
      "Token(number, #{@literal})"
    end
  end

  class ::String
    def alphanumeric?
      self[/^\w/] != nil
    end

    def digit?
      self[/^\d/] != nil
    end
  end

  class LexerError < Error; end

  class Lexer
    def initialize
      @input = ""
      @cursor = 0
      @char = nil
    end

    # @param input [String]
    # @return [Array<Token>]
    def lex(input)
      init_with input

      return [] if eof

      tokens = []
      until eof
        case @char
        when "{"
          tokens << TokenLCurly.new
        when "}"
          tokens << TokenRCurly.new
        when "["
          tokens << TokenLBracket.new
        when "]"
          tokens << TokenRBracket.new
        when ","
          tokens << TokenComma.new
        when ":"
          tokens << TokenColon.new
        when '"'
          tokens << tokenize_string
          next
        when "0".."9"
          tokens << tokenize_number
          next
        when " ", '\t', '\r', '\n'
          advance_cursor
          next
        else
          tokens << tokenize_literal
          next
        end
        advance_cursor
      end
      tokens
    end

    private

    def advance_cursor
      if @cursor >= @input.size
        @char = nil
        return
      end

      @char = @input[@cursor]
      @cursor += 1
    end

    def eof
      @char.nil?
    end

    # @param input [String]
    def init_with(input)
      @input = input
      @cursor = 0
      advance_cursor
    end

    def tokenize_literal
      str = ""
      until eof || !@char.alphanumeric?
        str += @char
        advance_cursor
      end

      case str
      when "null" then TokenNull.new
      when "false" then TokenFalse.new
      when "true" then TokenTrue.new
      else
        raise LexerError.new, "Unknown literal '#{str}'"
      end
    end

    def tokenize_number
      str = ""
      until eof || !@char.digit?
        str += @char
        advance_cursor
      end

      TokenNumber.new str
    end

    def tokenize_string
      advance_cursor
      str = ""
      until eof || @char == '"'
        str += @char
        advance_cursor
      end

      raise LexerError.new, "unexpected end of input, couldn't close string #{str}" if eof

      advance_cursor
      TokenString.new str
    end
  end

  class Node
    attr_reader :value

    def initialize(value)
      @value = value
    end
  end

  class ValueNode < Node
    def ==(other)
      return false unless other.is_a? ValueNode

      @value == other.value
    end
  end

  class ArrayNode < Node
    def initialize
      super([])
    end

    def ==(other)
      return false unless other.is_a? ArrayNode

      @value == other.value
    end

    def <<(value)
      raise ArgumentError.new, "Only JsonNode can be added to a JsonArrayNode" unless value.is_a?(Node)

      @value << value
    end
  end

  class ObjectNode < Node
    def initialize
      super({})
    end

    def ==(other)
      return false unless other.is_a? ObjectNode

      @value == other.value
    end

    def set(key, value)
      @value[key] = value
    end
  end

  class ParserError < Error; end

  class Parser
    def initialize
      @lexer = Lexer.new
      @tokens = []
    end

    def parse(input)
      init_with input

      raise ParserError.new, "Empty input, is not valid json" if @tokens.empty?

      parse_value
    end

    private

    def init_with(input)
      @tokens = @lexer.lex input
    end

    def parse_value
      token = @tokens.shift

      case token
      when nil
        raise ParserError.new, "unexpected end of input"
      when TokenNull
        ValueNode.new nil
      when TokenFalse
        ValueNode.new false
      when TokenTrue
        ValueNode.new true
      when TokenString
        ValueNode.new token.literal
      when TokenNumber
        ValueNode.new token.literal.to_i
      when TokenLCurly
        parse_object
      when TokenLBracket
        parse_array
      else
        raise ParserError.new, "Unexpected token #{token}"
      end
    end

    def parse_array
      node = ArrayNode.new

      Kernel.loop do
        peek = @tokens[0]
        raise ParserError.new, "Unexpected end of input" if peek.nil?

        if peek.is_a? TokenRBracket
          @tokens.shift
          return node
        elsif peek.is_a? TokenComma
          @tokens.shift
          next
        end

        node << parse_value
      end
    end

    def parse_object
      node = ObjectNode.new

      Kernel.loop do
        key = @tokens.shift
        raise ParserError.new, "Unexpected end of input for key" if key.nil?

        if key.is_a? TokenRCurly
          @tokens.shift
          return node
        elsif key.is_a? TokenComma
          next
        elsif !key.is_a?(TokenString)
          raise ParserError.new, "Unexpected token for key #{key}"
        end

        colon = @tokens.shift
        raise ParserError.new, "Unexpected end of input for colon" if colon.nil?
        raise ParserError.new, "Unexpected token for colon #{colon}" unless colon.is_a? TokenColon

        node.set key.value, parse_value
      end
    end
  end
end
