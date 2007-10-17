require 'fastercsv'
require 'bigdecimal'
require 'rbook/onix'
require 'mime/types'

class StageController < ApplicationController

  # by default, load the upload form
  def index
    upload
    render :action => 'upload'
  end

  # display a form allowing the user to upload a CSV file
  def upload
    if request.post?

      # if the page is being loaded without uploading a file, return to the upload form
      if params['csvfile'].blank?
        flash.now[:error] = 'Please begin by uploading a CSV file' and return
      end

      # rails integration testing doesn't support file uploads
      # so to work around it, tests will submit the local path
      # to a file instead of the file itself
      if Rails.test?
        filename = params['csvfile']
      else

        # if no filename has been specified, return to the upload form
        if params['csvfile'].original_filename.blank?
          flash.now[:error] = 'You must upload a valid CSV file to continue' and return
        end
 
        filename = RAILS_ROOT+"/tmp/files/"+params['csvfile'].original_filename
      end
      
      unless MIME::Types.type_for(filename).to_s == "text/csvtext/comma-separated-values"
        flash.now[:error] = 'The uploaded file is not a valid CSV file.' and return
      end

      # If the file hasn't been saved yet, save a copy into a temp location
      unless session[:filename] == filename
        session[:filename] = filename
        File.open(session[:filename], "w") { |f| f.write(params['csvfile'].read) } unless Rails.test?
      end
      
      # attempt to load the file into memory and check its formatting
      begin
        @data = load_data
        
        if @data.size > MAX_CSV_LINES
          flash.now[:error] = 'The CSV file must be no more than ' + MAX_CSV_LINES.to_s + ' lines long' and return
        end
      rescue FasterCSV::MalformedCSVError
        flash.now[:error] = 'Invalid CSV file:<br />'+$! and return
      rescue
        flash.now[:error] = 'There was an error loading your csv file:<br \>'+$! and return
      end
      
      redirect_to :action => 'settings'
    else
      reset_session
    end
  end

  # once the CSV file has been successfully uploaded, prompt the user to answer some questions
  # description the layout of the file
  def settings
    
    # this stage can only proceed if the file has been uploaded. 
    # return to the upload form if it hasn't been
    unless session[:filename]
      flash[:error] = "Please upload a file to begin the conversion"
      redirect_to :action => 'upload' and return
    end

    # load the data required to present the settings form to the user
    @data = load_data
    cols = @data[0].size
    @cols_array = [["Select a column", ""]] + (1..cols).to_a
   
    # process the form if it has been submitted
    if request.post?
      
      # if the correct form has been submitted but required data is missing
      # reshow the form and an appropriate error message
      if params['from_company'] == '' ||
         params['from_person'] == '' ||
         params['isbncol'] == '' ||
         params['titlecol'] == '' ||
         params['authorcol'] == '' ||
         params['publisher_name'] == '' ||
         params['supplier_name'] == ''

        flash.now[:error] = "A required field is missing" and return
      end
    
      # halt if we've been asked to multiply the price by a non-number
      if params[:multiply_price].match(/\A\d+\.?\d*\Z/).nil? && params[:multiply_price].length > 0
        flash.now[:error] = "Prices can only be multiplied by a positive number" and return
      end
    
      # store ONIX message header information directly into session variables where necessary
      session[:from_company] = params[:from_company]
      session[:from_person] = params[:from_person]
      session[:message_note] = params[:message_note] unless params[:message_note].blank?
      session[:publisher_name] = params[:publisher_name] unless params[:publisher_name].blank?
      session[:supplier_name] = params[:supplier_name] unless params[:supplier_name].blank?
   
      # instead of storing all the product data in session vars, only store which column in the 
      # file represents which piece of information. The data can be read out of the file later.
      session[:isbncol] = params[:isbncol].to_i - 1 unless params[:isbncol].blank?
      session[:titlecol] = params[:titlecol].to_i - 1 unless params[:titlecol].blank?
      session[:subtitlecol] = params[:subtitlecol].to_i - 1 unless params[:subtitlecol].blank?
      session[:authorcol] = params[:authorcol].to_i - 1 unless params[:authorcol].blank?
      session[:pubdatecol] = params[:pubdatecol].to_i - 1 unless params[:pubdatecol].blank?
      session[:formcol] = params[:formcol].to_i - 1 unless params[:formcol].blank?
      session[:pricecol] = params[:pricecol].to_i - 1 unless params[:pricecol].blank?
      session[:websitecol] = params[:websitecol].to_i - 1 unless params[:websitecol].blank?
      session[:descriptioncol] = params[:descriptioncol].to_i - 1 unless params[:descriptioncol].blank?
  
      # store any misc settings directly into session vars
      session[:ignore_first_line] = true unless params[:ignore_first_line].nil?
      session[:round_price] = true unless params[:round_price].nil?

      if BigDecimal.new(params['multiply_price']) > 0
        session[:multiply_price] = BigDecimal.new(params['multiply_price'])
      end
        
      # if a column with product formats has been specified, we need to display an extra
      # step asking the user to match each format to an ONIX format. If no format column was
      # specified, when can skip this step.
      if session[:formcol] != nil
        redirect_to :action => 'form_map' and return
      else
        redirect_to :action => 'download' and return
      end
    end
   
  end

  # displays a form to the user asking them to match the various product forms
  # listed in the CSV file to an ONIX equivalent. 
  def form_map
    # this stage can only proceed if the file has been uploaded. 
    # return to the upload form if it hasn't been
    unless session[:filename]
      flash[:error] = "Please upload a file to begin the conversion"
      redirect_to :action => 'upload' and return
    end
    
    # this stage can only proceed if settings form has been completed.
    # check this by checking the session variables, and return to the settings
    # form if need be
    unless session[:isbncol]
      flash[:error] = "Please complete the settings form before continuing to later steps"
      redirect_to :action => 'settings' and return
    end
   
    # if the settings form has been filled out, but no form column specified
    # then there is no need to visit this page, so redirect the user
    # to the downloads page
    unless session[:formcol]
      redirect_to :action => 'download' and return
    end
   
    # if the form mapping forms to ONIX codes has been submitted, save the
    # results as a hash, then redirect to the download page
    if request.post?
      session[:form_hash] = params[:form] unless params[:form].nil?
      redirect_to :action => 'download' and return
    end
   
    # load the forms from the CSV file to present to the user for matching 
    # to ONIX equivalents
    data = load_data 
        
    @forms = []
        
    data.each do |row|
      @forms << row[session[:formcol]]
    end
    @forms = @forms.uniq
    @forms.delete(nil)
    @forms.delete('')
    @onixforms = RBook::Onix::Lists::FORM_CODES

  end

  # a simple action to display a link to download the ONIX file
  def download
    # this stage can only proceed if the file has been uploaded. 
    # return to the upload form if it hasn't been
    unless session[:filename]
      flash[:error] = "Please upload a file to begin the conversion"
      redirect_to :action => 'upload' and return
    end
    
    # this stage can only proceed if settings form has been completed.
    # check this by checking the session variables, and return to the settings
    # form if need be
    unless session[:isbncol]
      flash[:error] = "Please complete the settings form before continuing to later steps"
      redirect_to :action => 'settings' and return
    end
    
    # If a form column has been specified, but no form hash exists, redirect to the form_map stage.
    if session[:formcol] && session[:form_hash].nil?
      flash[:error] = "Please complete the form mapping form"
      redirect_to :action => 'form_map' and return
    end
  end

  # returns an ONIX file representing the CSV file
  def onix
    
    # this stage can only proceed if the file has been uploaded. 
    # return to the upload form if it hasn't been
    unless session[:filename]
      flash[:error] = "Please upload a file to begin the conversion"
      redirect_to :action => 'upload' and return
    end
    
    # this stage can only proceed if settings form has been completed.
    # check this by checking the session variables, and return to the settings
    # form if need be
    unless session[:isbncol]
      flash[:error] = "Please complete the settings form before continuing to later steps"
      redirect_to :action => 'settings' and return
    end
    
    # If a form column has been specified, but no form hash exists, redirect to the form_map stage.
    if session[:formcol] && session[:form_hash].nil?
      flash[:error] = "Please complete the form mapping form"
      redirect_to :action => 'form_map' and return
    end
    
    begin
      msg = RBook::Onix::Message.new

      data = load_data 

      msg.from_company = session[:from_company]
      msg.from_person = session[:from_person]
      msg.message_note = session[:message_note]

      isbncol = session[:isbncol]
      titlecol = session[:titlecol]
      subtitlecol = session[:subtitlecol]
      authorcol = session[:authorcol]
      pubdatecol = session[:pubdatecol]
      formcol = session[:formcol]
      pricecol = session[:pricecol]
      websitecol = session[:websitecol]
      descriptioncol = session[:descriptioncol]
        
      data.each do |row| 
          
        product = RBook::Onix::Product.new
          
        product.product_identifier = row[isbncol].gsub(/-/,'').strip
        product.title = row[titlecol].strip
        
        unless subtitlecol.nil? || row[subtitlecol].nil?
          product.subtitle = row[subtitlecol].strip
        end
          
        unless authorcol.nil? || row[authorcol].nil?
          contributor = RBook::Onix::Contributor.new
          contributor.name_inverted = row[authorcol].strip
          contributor.role = 'A01'
          contributor.sequence_number = '01'
          product.add_contributor(contributor)
        end
          
        if formcol.nil? || row[formcol].nil? || row[formcol].blank?
          product.form = '00'
        else
          if session[:form_hash][row[formcol]].nil?
            product.form = '00'
          else
            product.form = session[:form_hash][row[formcol]]
          end
        end
          
        product.description = row[descriptioncol] unless descriptioncol.nil?
        product.description.strip! unless product.description.nil?

        product.publisher = session[:publisher_name] unless session[:publisher_name].nil?
  
        restriction = RBook::Onix::SalesRestriction.new
        restriction.type = '00'
        restriction.detail = 'Unknown'
        product.add_sales_restriction(restriction)
        
        unless session[:supplier_name].nil?
          supply_detail = RBook::Onix::SupplyDetail.new
          supply_detail.supplier_name = session[:supplier_name] unless session[:supplier_name].nil?
           
          supply_detail.availability_code = 'CS'
          
          unless pricecol.nil? || row[pricecol].nil?

            supply_detail.price = BigDecimal.new(row[pricecol].strip.gsub("\$", ""))
          
            unless session[:multiply_price].nil?
              supply_detail.price = supply_detail.price * session[:multiply_price]
            end
            
            unless session[:round_price].nil? || supply_detail.price == BigDecimal.new("0")
              if supply_detail.price.frac > BigDecimal.new("0.95") && 
                 supply_detail.price.frac <= BigDecimal.new("0.99")
  
                supply_detail.price = supply_detail.price.truncate + BigDecimal.new("0.95")
              elsif supply_detail.price.frac >= BigDecimal.new("0.0") &&
                    supply_detail.price.frac <= BigDecimal.new("0.45")
                  
                supply_detail.price = (supply_detail.price.truncate - 1) + BigDecimal.new("0.95")
              elsif supply_detail.price.frac >= BigDecimal.new("0.46") &&
                    supply_detail.price.frac <= BigDecimal.new("0.94")
                
                supply_detail.price = supply_detail.price.truncate + BigDecimal.new("0.95")
              end
            end

          end
          product.add_supply_detail(supply_detail)
        end
         
        begin
          product.pubdate = Date.parse(row[pubdatecol].strip) unless pubdatecol.nil?
        rescue
          # do nothing
        end

        product.website = row[websitecol].strip unless websitecol.nil?
        msg.add_product(product)
      end
        
      send_data(msg.to_s, :disposition => 'attachment', :type => "text/xml", :filename => File.basename(session[:filename], '.csv')+'.xml')
    #rescue
    #  flash[:error] = "An error occured while processing your request: <br />" + $! 
    #  redirect_to :action => 'download'    
    end
  end

private
 
  # reads in the CSV file, sanitises it, the returns a 2D array.
  def load_data
    return [] unless session[:filename]
    return [] unless File.exist?(session[:filename])

    # load the file into an array
    data = FasterCSV.read(session[:filename])
      
    # remove the first line if necesary
    data.delete_at(0) if session[:ignore_first_line] && data.size > 0

    # remove any blank lines
    data.delete([])

    return data

  end
end
