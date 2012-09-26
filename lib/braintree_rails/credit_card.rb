module BraintreeRails
  class CreditCard < SimpleDelegator
    include Model
    define_attributes :customer_id, :number, :token, :cvv, :cardholder_name, :expiration_date, :expiration_month, :expiration_year, :billing_address, :options, :created_at, :updated_at

    validates :customer_id, :presence => true, :length => {:maximum => 36}, :if => :new_record?
    validates :number, :presence => true, :numericality => { :only_integer => true }, :length => {:minimum => 12, :maximum => 19}, :if => :new_record?
    validates :cvv, :presence => true, :numericality => { :only_integer => true, :greater_than_or_equal_to => 100, :less_than_or_equal_to => 9999 }
    validates :cardholder_name, :length => {:maximum => 255}
    validates :expiration_month, :presence => true, :numericality => { :only_integer => true, :greater_than_or_equal_to => 1, :less_than_or_equal_to => 12 }
    validates :expiration_year,  :presence => true, :numericality => { :only_integer => true, :greater_than_or_equal_to => 1976, :less_than_or_equal_to => 2200 }
    validates :billing_address, :presence => true
    validates_each :billing_address do |record, attribute, value|
      record.errors.add(attribute, "is not valid. #{value.errors.full_messages.join("\n")}") if value && value.invalid?
    end

    def initialize(credit_card = {})
      super(ensure_model(credit_card))
    end

    def id
      token
    end

    def customer
      new_record? ? nil : @customer ||= BraintreeRails::Customer.new(customer_id)
    end

    def transactions
      new_record? ? [] : @transactions ||= Transactions.new(customer, self)
    end

    def expiration_date=(date)
      expiration_month, expiration_year = date.split('/')
      self.expiration_month = expiration_month
      self.expiration_year = expiration_year.gsub(/^(\d\d)$/, '20\1')
    end

    def expiration_date
      expiration_month.present? ? "#{expiration_month}/#{expiration_year}" : nil
    end

    def billing_address=(val)
      @billing_address = Address.new(val)
    end

    def add_errors(validation_errors)
      billing_address.add_errors(validation_errors.for(:credit_card).for(:billing_address).to_a)
      super(validation_errors)
    end

    protected
    def attributes_for_update
      super.tap { |attributes| attributes[:billing_address].merge!(:options => {:update_existing => true}) }
    end

    def attributes_to_exclude_from_update
      [:token, :customer_id, :expiration_date, :created_at, :updated_at]
    end

    def attributes_to_exclude_from_create
      [:expiration_date, :created_at, :updated_at]
    end
  end
end