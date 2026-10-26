# frozen_string_literal: true

module Api
  module V1
    class BooksController < BaseController
      before_action :set_book, only: %i[show destroy]

      def index
        books = Book.active.order(:id).includes(:borrowings)

        render_resource books, serializer: BookSerializer
      end

      def show
        book = Book.includes(borrowings: :reader).find(params.expect(:id))

        render_resource book,
                        serializer: BookSerializer,
                        options: { include: [:'borrowings.reader'] }
      end

      def create
        book = Book.new(book_params)

        if book.save
          render_resource book,
                          serializer: BookSerializer,
                          status: :created
        else
          render_errors book.errors.full_messages
        end
      end

      def destroy
        @book.with_lock do
          if @book.borrowings.exists?
            @book.update!(archived_at: Time.current)
          else
            @book.destroy!
          end
        end

        head :no_content
      end

      private

      def set_book
        @book = Book.find(params.expect(:id))
      end

      def book_params
        resource_attributes('books').permit(
          :title,
          :author
        )
      end
    end
  end
end
