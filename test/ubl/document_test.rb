# frozen_string_literal: true

require "test_helper"
require "date"

class TestEnvoiceUblDocument < Minitest::Test

  def test_tax_groups_intra
    document = Envoice::Ubl::Document.new(
      type: Envoice::Ubl::Document::TYPE_INVOICE,
      id: 'F2025/001',
      issue_date: Date.parse('2025-11-18'),
      due_date: Date.parse('2025-12-18'),
      currency: 'EUR',
      tax_exemption_reason: 'Intra-community supply - Services B2B'
    )
    document.sender = Envoice::Ubl::Party.new(name: 'Sender BV', street: 'Verzendstraat', number: 32, city: 2810, zip_code: 'Verzendegem', country_iso2: 'BE', vat_number: 'BE0123456445', email: 'info@sender.be')
    document.receiver = Envoice::Ubl::Party.new(name: 'Receiver LTD', street: 'Receiverstreet', number: 353, city: 2810, zip_code: 'Receivershire', country_iso2: 'IE', vat_number: 'IE0123456444', email: 'info@receiver.ie')

    exception = assert_raises(RuntimeError) { document.tax_groups }
    assert_equal 'No lines on document', exception.message

    document.add_line(name: 'line 001 21%', quantity: 2.5, unit_price: 5, tax_rate: 21.0)
    document.add_line(name: 'line 002 21%', quantity: 5, unit_price: 10.5, tax_rate: 21.0)

    document.add_line(name: 'line 003 6%', quantity: 3.2, unit_price: 100, tax_rate: 6.0)

    document.add_line(name: 'line 004 0%', quantity: 1, unit_price: 5, tax_rate: 0.0)

    tax_groups = document.tax_groups
    assert_equal 3, tax_groups.size

    zero = tax_groups[0]
    assert_equal 0.0, zero.tax_rate
    assert_equal 'K', zero.classified_tax_category
    assert_equal 'Intra-community supply - Services B2B', zero.tax_exemption_reason
    assert_equal 0.0, zero.total_vat_amount
    assert_equal 5.0, zero.total_amount_without_vat

    six = tax_groups[1]
    assert_equal 6.0, six.tax_rate
    assert_equal 'S', six.classified_tax_category
    assert_nil six.tax_exemption_reason
    assert_equal 19.2, six.total_vat_amount
    assert_equal 320.0, six.total_amount_without_vat

    twenty_one = tax_groups[2]
    assert_equal 21.0, twenty_one.tax_rate
    assert_equal 'S', twenty_one.classified_tax_category
    assert_nil twenty_one.tax_exemption_reason
    assert_equal 13.66, twenty_one.total_vat_amount
    assert_equal 65.0, twenty_one.total_amount_without_vat

    assert_equal 390.0, document.total_without_vat
    assert_equal 32.86, document.total_vat_amount
    assert_equal 422.86, document.total_with_vat
  end

  def test_tax_groups_exemption
    document = Envoice::Ubl::Document.new(
      type: Envoice::Ubl::Document::TYPE_INVOICE,
      id: 'F2025/001',
      issue_date: Date.parse('2025-11-18'),
      due_date: Date.parse('2025-12-18'),
      currency: 'EUR'
    )
    document.sender = Envoice::Ubl::Party.new(name: 'Sender BV', street: 'Verzendstraat', number: 32, city: 2810, zip_code: 'Verzendegem', country_iso2: 'BE', vat_number: 'BE0123456445', email: 'info@sender.be')
    document.receiver = Envoice::Ubl::Party.new(name: 'Receiver BV', street: 'Ontvangsstraat', number: 32, city: 2810, zip_code: 'Ontvangegem', country_iso2: 'BE', vat_number: 'BE0123456444', email: 'info@receiver.be')

    document.tax_exemption_reason = 'BTW verlegd'

    exception = assert_raises(RuntimeError) { document.tax_groups }
    assert_equal 'No lines on document', exception.message

    document.add_line(name: 'line 001 21%', quantity: 2.5, unit_price: 5, tax_rate: 21.0)
    document.add_line(name: 'line 002 21%', quantity: 5, unit_price: 10.5, tax_rate: 21.0)

    document.add_line(name: 'line 003 6%', quantity: 3.2, unit_price: 100, tax_rate: 6.0)

    document.add_line(name: 'line 004 0%', quantity: 1, unit_price: 5, tax_rate: 0.0)

    tax_groups = document.tax_groups
    assert_equal 3, tax_groups.size

    zero = tax_groups[0]
    assert_equal 0.0, zero.tax_rate
    assert_equal 'E', zero.classified_tax_category
    assert_equal 'BTW verlegd', zero.tax_exemption_reason
    assert_equal 0.0, zero.total_vat_amount
    assert_equal 5.0, zero.total_amount_without_vat

    six = tax_groups[1]
    assert_equal 6.0, six.tax_rate
    assert_equal 'S', six.classified_tax_category
    assert_nil six.tax_exemption_reason
    assert_equal 19.2, six.total_vat_amount
    assert_equal 320.0, six.total_amount_without_vat

    twenty_one = tax_groups[2]
    assert_equal 21.0, twenty_one.tax_rate
    assert_equal 'S', twenty_one.classified_tax_category
    assert_nil twenty_one.tax_exemption_reason
    assert_equal 13.66, twenty_one.total_vat_amount
    assert_equal 65.0, twenty_one.total_amount_without_vat

    assert_equal 390.0, document.total_without_vat
    assert_equal 32.86, document.total_vat_amount
    assert_equal 422.86, document.total_with_vat
  end

  def test_fix_rounding_issues_by_overriding_line_extension_and_tax_amount
    document = Envoice::Ubl::Document.new(
      type: Envoice::Ubl::Document::TYPE_INVOICE,
      id: 'F2025/001',
      issue_date: Date.parse('2025-11-18'),
      due_date: Date.parse('2025-12-18'),
      currency: 'EUR'
    )
    document.add_line(name: 'line 001 21%', quantity: 1.0, unit_price: 171.0744, tax_rate: 21.0)
    document.add_line(name: 'line 002 21%', quantity: 1.0, unit_price: 171.0744, tax_rate: 21.0)
    document.add_line(name: 'line 003 21%', quantity: 1.0, unit_price: 82.64, tax_rate: 21.0)

    line = document.lines.first
    assert_equal 171.07, line.line_extension_amount
    assert_equal 35.92, line.tax_amount

    assert_equal 424.78, document.total_without_vat
    assert_equal 89.19, document.total_vat_amount
    assert_equal 513.97, document.total_with_vat

    document = Envoice::Ubl::Document.new(
      type: Envoice::Ubl::Document::TYPE_INVOICE,
      id: 'F2025/001',
      issue_date: Date.parse('2025-11-18'),
      due_date: Date.parse('2025-12-18'),
      currency: 'EUR'
    )
    document.add_line(name: 'line 001 21%', quantity: 1.0, unit_price: 171.0744, tax_rate: 21.0, line_extension_amount: 171.07, tax_amount: 35.93)
    document.add_line(name: 'line 002 21%', quantity: 1.0, unit_price: 171.0744, tax_rate: 21.0, line_extension_amount: 171.07, tax_amount: 35.93)
    document.add_line(name: 'line 003 21%', quantity: 1.0, unit_price: 82.64, tax_rate: 21.0, line_extension_amount: 82.64, tax_amount: 17.36)

    line = document.lines.first
    assert_equal 171.07, line.line_extension_amount
    assert_equal 35.93, line.tax_amount

    assert_equal 424.78, document.total_without_vat
    assert_equal 89.22, document.total_vat_amount
    assert_equal 514.00, document.total_with_vat
  end

end