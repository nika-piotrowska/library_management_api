# frozen_string_literal: true

class BorrowingMailer < ApplicationMailer
  def before_due_reminder(borrowing)
    @borrowing = borrowing

    mail(
      to: borrowing.reader.email,
      subject: "Book return reminder: #{borrowing.book.title}"
    )
  end

  def due_reminder(borrowing)
    @borrowing = borrowing

    mail(
      to: borrowing.reader.email,
      subject: "Book return due today: #{borrowing.book.title}"
    )
  end
end
