# frozen_string_literal: true

module Api
  module V1
    class BorrowingsController < BaseController
      def create
        book = Book.find(borrowing_book_id)
        reader = Reader.find(borrowing_reader_id)

        borrowing = Borrowings::Create.call(
          book: book,
          reader: reader
        )

        render_resource borrowing,
                        serializer: BorrowingSerializer,
                        status: :created
      end

      def return_book
        borrowing = Borrowing.find(params.expect(:id))

        borrowing = Borrowings::ReturnBook.call(
          borrowing: borrowing
        )

        render_resource borrowing,
                        serializer: BorrowingSerializer
      end

      private

      def borrowing_book_id
        borrowing_relationship_id(:book, 'books')
      end

      def borrowing_reader_id
        borrowing_relationship_id(:reader, 'readers')
      end

      def borrowing_relationship_id(name, expected_type)
        data = json_api_params[:data]

        unless data[:type] == 'borrowings'
          raise ActionController::BadRequest,
                "Expected resource type 'borrowings'"
        end

        relationships = data[:relationships]

        raise ActionController::BadRequest, 'Missing relationships' unless relationships.is_a?(Hash)

        relationship = relationships.dig(name, :data)

        unless relationship.is_a?(Hash) &&
               relationship[:type] == expected_type &&
               relationship[:id].present?
          raise ActionController::BadRequest,
                "Invalid #{name} relationship"
        end

        relationship[:id]
      end
    end
  end
end
