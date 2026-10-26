# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Books API', type: :request do
  let(:headers) do
    {
      'ACCEPT' => 'application/vnd.api+json',
      'CONTENT_TYPE' => 'application/vnd.api+json'
    }
  end

  describe 'GET /api/v1/books' do
    it 'returns books in JSON:API format' do
      books = create_list(:book, 2)

      get '/api/v1/books', headers: headers

      data = JSON.parse(response.body)['data']

      expect(response).to have_http_status(:ok)
      expect(data.size).to eq(2)
      expect(data.pluck('type')).to all(eq('books'))
      expect(data.pluck('id')).to match_array(books.map { |book| book.id.to_s })
    end

    it 'returns only active books' do
      active_book = create(:book)
      create(:book, :archived)

      get '/api/v1/books', headers: headers

      data = JSON.parse(response.body)['data']

      expect(data.pluck('id')).to eq([active_book.id.to_s])
    end

    it 'returns the availability status of books' do
      available_book = create(:book)
      borrowed_book = create(:book)
      create(:borrowing, book: borrowed_book)

      get '/api/v1/books', headers: headers

      data = JSON.parse(response.body)['data']

      statuses = data.to_h do |resource|
        [resource['id'], resource.dig('attributes', 'status')]
      end

      expect(statuses[available_book.id.to_s]).to eq('available')
      expect(statuses[borrowed_book.id.to_s]).to eq('borrowed')
    end
  end

  describe 'GET /api/v1/books/:id' do
    let(:book) { create(:book) }

    it 'returns a book in JSON:API format' do
      get "/api/v1/books/#{book.id}", headers: headers

      data = JSON.parse(response.body)['data']

      expect(response).to have_http_status(:ok)
      expect(data['type']).to eq('books')
      expect(data['id']).to eq(book.id.to_s)
      expect(data['attributes']).to include(
        'serial_number' => book.serial_number,
        'title' => book.title,
        'author' => book.author
      )
    end

    it 'returns borrowing history with readers' do
      create(:borrowing, :returned, book: book)

      get "/api/v1/books/#{book.id}", headers: headers

      included = JSON.parse(response.body)['included']

      expect(response).to have_http_status(:ok)
      expect(included.pluck('type')).to include('borrowings', 'readers')
    end

    it 'returns 404 when the book does not exist' do
      get '/api/v1/books/999999', headers: headers

      body = JSON.parse(response.body)

      expect(response).to have_http_status(:not_found)
      expect(body['errors']).to be_present
    end
  end

  describe 'POST /api/v1/books' do
    let(:attributes) do
      {
        title: 'Dune',
        author: 'Frank Herbert'
      }
    end

    let(:payload) do
      {
        data: {
          type: 'books',
          attributes: attributes
        }
      }
    end

    def create_book
      post '/api/v1/books',
           params: payload.to_json,
           headers: headers
    end

    context 'with valid attributes' do
      it 'creates a book' do
        expect { create_book }.to change(Book, :count).by(1)

        expect(response).to have_http_status(:created)
      end

      it 'automatically generates a six-digit serial number' do
        create_book

        book = Book.last

        expect(book.serial_number).to match(/\A[0-9]{6}\z/)
        expect(book.serial_number).to eq(format('%06d', book.id))
      end

      it 'returns the created book in JSON:API format' do
        create_book

        data = JSON.parse(response.body)['data']
        book = Book.last

        expect(data['type']).to eq('books')
        expect(data['id']).to eq(book.id.to_s)
        expect(data['attributes']).to include(
          'serial_number' => book.serial_number,
          'title' => 'Dune',
          'author' => 'Frank Herbert',
          'status' => 'available'
        )
      end

      it 'generates a unique serial number for each book' do
        create_book
        first_serial_number = Book.last.serial_number

        create_book
        second_serial_number = Book.last.serial_number

        expect(first_serial_number).not_to eq(second_serial_number)
      end

      it 'ignores a serial number provided by the client' do
        attributes[:serial_number] = '999999'

        create_book

        book = Book.last

        expect(response).to have_http_status(:created)
        expect(book.serial_number).to eq(format('%06d', book.id))
        expect(book.serial_number).not_to eq('999999')
      end
    end

    context 'with invalid attributes' do
      it 'rejects a missing title' do
        attributes[:title] = nil

        create_book

        expect(response).to have_http_status(:unprocessable_content)
        expect(JSON.parse(response.body)['errors']).to be_present
      end

      it 'rejects a missing author' do
        attributes[:author] = nil

        create_book

        expect(response).to have_http_status(:unprocessable_content)
        expect(JSON.parse(response.body)['errors']).to be_present
      end

      it 'does not create a book when attributes are invalid' do
        attributes[:title] = nil

        expect { create_book }.not_to change(Book, :count)
      end
    end

    context 'with invalid JSON:API payload' do
      it 'rejects an incorrect resource type' do
        payload[:data][:type] = 'readers'

        create_book

        expect(response).to have_http_status(:bad_request)
        expect(JSON.parse(response.body)['errors']).to be_present
      end

      it 'rejects a missing data object' do
        post '/api/v1/books',
             params: { book: attributes }.to_json,
             headers: headers

        expect(response).to have_http_status(:bad_request)
        expect(JSON.parse(response.body)['errors']).to be_present
      end
    end
  end

  describe 'DELETE /api/v1/books/:id' do
    it 'deletes a book without borrowing history' do
      book = create(:book)

      expect do
        delete "/api/v1/books/#{book.id}", headers: headers
      end.to change(Book, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end

    it 'archives a book with borrowing history' do
      book = create(:book)
      borrowing = create(:borrowing, :returned, book: book)

      delete "/api/v1/books/#{book.id}", headers: headers

      expect(response).to have_http_status(:no_content)
      expect(book.reload.archived?).to be(true)
      expect(Borrowing.exists?(borrowing.id)).to be(true)
    end

    it 'returns 404 for a nonexistent book' do
      delete '/api/v1/books/0', headers: headers

      expect(response).to have_http_status(:not_found)
    end
  end
end
