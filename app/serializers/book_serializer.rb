# frozen_string_literal: true

class BookSerializer
  include JSONAPI::Serializer

  set_type :books

  attributes :serial_number, :title, :author, :archived_at

  attribute :status do |book|
    if book.archived?
      'archived'
    elsif book.current_borrowing.present?
      'borrowed'
    else
      'available'
    end
  end

  has_many :borrowings, serializer: BorrowingSerializer
end
