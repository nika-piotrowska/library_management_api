# frozen_string_literal: true

module Borrowings
  class ReturnBook
    def self.call(borrowing:)
      new(borrowing: borrowing).call
    end

    def initialize(borrowing:)
      @borrowing = borrowing
    end

    def call
      borrowing.book.with_lock do
        borrowing.reload

        raise Error, 'Book has already been returned' unless borrowing.active?

        borrowing.update!(returned_at: Time.current)

        borrowing
      end
    end

    private

    attr_reader :borrowing
  end
end
