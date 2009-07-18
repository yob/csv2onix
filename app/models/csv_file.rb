# encoding: utf-8

class CsvFile

  TEMPDIR = RAILS_ROOT + "/tmp/files/"

  attr_reader :id

  attr_accessor :from_company, :from_person, :message_note, :publisher_name
  attr_accessor :supplier_name, :currency_code, :measurement_system

  attr_accessor :isbncol, :titlecol, :subtitlecol, :formcol
  attr_accessor :pricecol, :pubdatecol, :websitecol, :descriptioncol
  attr_accessor :pagescol, :seriescol, :dimensionscol, :weightcol
  attr_accessor :author1col, :author2col, :author3col

  attr_accessor :formmap

  attr_accessor :multiply_price, :round_price, :ignore_first_line

  class << self

    def create(path)
      raise "#{path} does not exist" unless File.file?(path)

      @id = CsvFile.get_id
      FileUtils.cp(path, CsvFile::TEMPDIR + "#{@id}.dat")
      CsvFile.new(@id)
    end

    def find(id)
      return nil if id.nil?
      return nil unless File.file?("#{CsvFile::TEMPDIR}#{id}.dat")

      return CsvFile.new(id)
    end

    # return a random unused file ID
    def get_id
      FileUtils.mkdir_p(CsvFile::TEMPDIR)

      id = rand(1000000)
      while File.file?("#{CsvFile::TEMPDIR}#{id}.dat")
        id = rand(1000000)
      end
      return id
    end

    def human_name
      "CSV File"
    end
  end

  def initialize(id)
    @id = id.to_i

    load_attributes
  end

  def to_param
    @id.to_s
  end

  def attribute_filename
    "#{CsvFile::TEMPDIR}#{id}.att"
  end

  def input_filename
    "#{CsvFile::TEMPDIR}#{id}.dat"
  end

  def onix_filename
    "#{CsvFile::TEMPDIR}#{id}.xml"
  end

  def generate_onix
    File.open(onix_filename, "w") do |output|
      header = ONIX::Header.new
      header.from_company = from_company unless from_company.blank?
      header.from_person  = from_person  unless from_person.blank?
      #header.to_person    = to_person    unless to_person.blank?
      #header.to_company   = to_company   unless to_company.blank?
      header.sent_date    = Time.now
      header.default_currency_code = currency_code unless currency_code.blank?

      ONIX::Writer.open(output, header) do |writer|
        self.each_onix_product do |product|
          writer << product
        end
      end

    end
  end

  def each_onix_product(&block)
    counter = 0
    FasterCSV.foreach(input_filename) do |row|
      counter += 1
      next if counter == 1 && ignore_first_line

      product = ONIX::APAProduct.new

      unless measurement_system.blank?
        product.measurement_system = measurement_system.downcase.to_sym
      end

      id = row[isbncol.to_i].to_s.gsub("-","").strip
      product.record_reference = id

      if EAN13.valid?(id)
        ean = EAN13.new(id)
        product.ean = id
        product.isbn13 = id if ean.bookland?
      elsif UPC.valid?(id)
        product.ean = "0#{id}"
      else
        product.proprietary_id = id
      end

      product.title = row[titlecol.to_i].to_s.strip

      unless subtitlecol.blank? || row[subtitlecol.to_i].blank?
        product.subtitle = row[subtitlecol.to_i].strip
      end

      unless author1col.blank? || row[author1col.to_i].blank?
        contributor = ONIX::Contributor.new
        contributor.person_name_inverted = row[author1col.to_i].strip
        contributor.contributor_role = 'A01'
        contributor.sequence_number = '01'
        product.product.contributors << contributor
      end

      unless author2col.blank? || row[author2col.to_i].blank?
        contributor = ONIX::Contributor.new
        contributor.person_name_inverted = row[author2col.to_i].strip
        contributor.contributor_role = 'A01'
        contributor.sequence_number = '02'
        product.product.contributors << contributor
      end

      unless author3col.blank? || row[author3col.to_i].blank?
        contributor = ONIX::Contributor.new
        contributor.person_name_inverted = row[author3col.to_i].strip
        contributor.contributor_role = 'A01'
        contributor.sequence_number = '03'
        product.product.contributors << contributor
      end

      if formcol.blank? || row[formcol.to_i].blank?
        product.product_form = '00'
      else
        code = formmap[row[formcol.to_i]]
        if code.blank?
          product.product_form = '00'
        else
          product.product_form = formmap[row[formcol.to_i]]
        end
      end

      unless descriptioncol.blank? || row[descriptioncol.to_i].blank?
        product.main_description = row[descriptioncol.to_i].strip
      end

      product.publisher = self.publisher_name

      product.sales_restriction_type = 0
      product.supplier_name = self.supplier_name
      product.product_availability = 99
      product.publishing_status = 9 # Unknown

      unless pricecol.blank? || row[pricecol.to_i].blank?
        price = row[pricecol.to_i].to_s.gsub(/[^\d\.]/,"")
        price = BigDecimal.new(price)

        unless multiply_price.blank?
          price = price * BigDecimal.new(multiply_price)
        end

        if round_price && price > 0
          if price.frac > BigDecimal.new("0.95") && price.frac <= BigDecimal.new("0.99")
            price = price.truncate + BigDecimal.new("0.95")
          elsif price.frac >= BigDecimal.new("0.0") && price.frac <= BigDecimal.new("0.45")
            price = (price.truncate - 1) + BigDecimal.new("0.95")
          elsif price.frac >= BigDecimal.new("0.46") && price.frac <= BigDecimal.new("0.94")
            price = price.truncate + BigDecimal.new("0.95")
          end
        end

        product.rrp_inc_sales_tax = price
      end

      unless pubdatecol.blank? || row[pubdatecol.to_i].blank?
        begin
          product.publication_date = Chronic.parse(row[pubdatecol.to_i].strip)
        rescue
          # do nothing
        end
      end

      unless websitecol.blank? || row[websitecol.to_i].blank?
        product.supplier_website = row[websitecol.to_i].strip
      end

      unless pagescol.blank? || row[pagescol.to_i].blank?
        pages = row[pagescol.to_i].scan(/\d+/).first
        product.number_of_pages = pages.to_i if pages
      end

      unless dimensionscol.blank? || row[dimensionscol.to_i].blank?
        height = row[dimensionscol.to_i].scan(/\d+/)[0].to_s.to_i
        width  = row[dimensionscol.to_i].scan(/\d+/)[1].to_s.to_i
        product.height = height if height > 0
        product.width  = width  if width > 0
      end

      unless weightcol.blank? || row[weightcol.to_i].blank?
        weight = row[weightcol.to_i].scan(/\d+/).first
        product.weight = weight.to_i if weight
      end

      unless seriescol.blank? || row[seriescol.to_i].blank?
        product.series = row[seriescol.to_i].strip
      end

      yield product
    end
  end

  def first_100_rows
    rows = []

    FasterCSV.foreach(input_filename) do |row|
      rows << row

      # only display the first 100 records
      break if rows.size >= 100
    end

    rows
  end

  def forms
    forms = []
    return forms if formcol.blank?

    counter = 0
    FasterCSV.foreach(input_filename) do |row|
      counter += 1
      next if counter == 1 && ignore_first_line

      forms << row[formcol.to_i]
    end

    forms.uniq!
    forms.delete(nil)
    forms.delete('')
    forms
  end

  def col_count
    FasterCSV.foreach(input_filename) do |row|
      return row.size
    end
  end

  def new_record?
    false
  end

  def save
    params = {
      :from_company   => from_company,
      :from_person    => from_person,
      :message_note   => message_note,
      :publisher_name => publisher_name,
      :supplier_name  => supplier_name,
      :currency_code  => currency_code,
      :measurement_system => measurement_system,
      :isbncol        => isbncol,
      :titlecol       => titlecol,
      :subtitlecol    => subtitlecol,
      :author1col     => author1col,
      :author2col     => author2col,
      :author3col     => author3col,
      :formcol        => formcol,
      :pricecol       => pricecol,
      :pubdatecol     => pubdatecol,
      :websitecol     => websitecol,
      :descriptioncol => descriptioncol,
      :pagescol       => pagescol,
      :seriescol      => seriescol,
      :dimensionscol  => dimensionscol,
      :weightcol      => weightcol,
      :multiply_price => multiply_price,
      :round_price    => round_price,
      :ignore_first_line => ignore_first_line,
      :formmap        => formmap
    }
    File.open(attribute_filename,"w") do |f|
      f.write YAML.dump(params)
    end
  end

  def update_attributes(params)
    params.each do |key, value|
      if self.respond_to?("#{key}=")
        self.__send__("#{key}=", value)
      end
    end
    sanitise_attributes
    save
  end

  private

  def load_attributes
    return false unless File.file?(attribute_filename)

    params = YAML.load(File.read(attribute_filename))
    params.each do |key, value|
      if self.respond_to?("#{key}=")
        self.__send__("#{key}=", value)
      end
    end
  end

  def sanitise_attributes
    if self.round_price.nil? || self.round_price == false || self.round_price == "0"
      self.round_price = false
    else
      self.round_price = true
    end

    if self.ignore_first_line.nil? || self.ignore_first_line == false || self.ignore_first_line == "0"
      self.ignore_first_line = false
    else
      self.ignore_first_line = true
    end
  end
end
