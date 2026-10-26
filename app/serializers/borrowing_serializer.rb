# frozen_string_literal: true

class BorrowingSerializer
  include JSONAPI::Serializer

  set_type :borrowings

  attributes :borrowed_at, :due_at, :returned_at

  attribute :status do |borrowing|
    if !borrowing.active?
      'returned'
    elsif borrowing.overdue?
      'overdue'
    else
      'active'
    end
  end

  belongs_to :book, serializer: BookSerializer
  belongs_to :reader, serializer: ReaderSerializer
end
