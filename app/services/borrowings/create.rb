# frozen_string_literal: true

module Borrowings
  class Create
    def self.call(book:, reader:)
      new(book: book, reader: reader).call
    end

    def initialize(book:, reader:)
      @book = book
      @reader = reader
    end

    def call
      book.with_lock do
        validate_availability!

        Borrowing.create!(
          book: book,
          reader: reader
        )
      end
    end

    private

    attr_reader :book, :reader

    def validate_availability!
      raise Error, 'Book is archived' if book.archived?
      raise Error, 'Book is already borrowed' if book.current_borrowing
    end
  end
end
