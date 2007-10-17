require File.dirname(__FILE__) + "/../test_helper"
require 'mime/types'

class StoriesTest < ActionController::IntegrationTest

  def test_upload_invalid_file
    new_session do |bob| 
      bob.uploads_invalid_file("gir_dance.png")
    end
  end

  def test_upload_file_with_too_many_lines
    new_session do |bob| 
      bob.uploads_invalid_file("too_many_lines.csv")
    end
  end

  def test_upload_valid_file
    new_session do |bob| 
      bob.uploads_valid_file("valid.csv")
    end
  end

  def test_no_settings
    new_session do |bob| 
      bob.uploads_valid_file("valid.csv")
      bob.chooses_no_settings
    end
  end

  def test_forgets_required_settings
    new_session do |bob| 
      bob.uploads_valid_file("valid.csv")
      bob.forgets_required_settings(:header)
    end
    
    new_session do |jane| 
      jane.uploads_valid_file("valid.csv")
      jane.forgets_required_settings(:cols)
    end
  end
  
  def test_invalid_multiply_price
    new_session do |bob| 
      bob.uploads_valid_file("valid.csv")
      bob.enters_invalid_multiply_price
    end
  end  

  def test_valid_settings_no_formcol
    new_session do |bob| 
      bob.uploads_valid_file("valid.csv")
      bob.enters_valid_settings_no_formcol
    end
  end  

  def test_valid_settings_with_formcol
    new_session do |bob| 
      bob.uploads_valid_file("valid.csv")
      bob.enters_valid_settings_with_formcol
      bob.makes_form_map_selection
    end
  end  
  
  def test_multiply_price_with_some_nil_prices
    new_session do |bob| 
      bob.uploads_valid_file("valid_missing_some_prices.csv")
      bob.enters_valid_settings_with_formcol
      bob.makes_form_map_selection
    end
  end  
  
private

  module MyTestingDSL

    def uploads_invalid_file(filename)
      post '/stage/upload', :csvfile => RAILS_ROOT + "/test/fixtures/files/" + filename
      assert_response :success 
      assert_template "upload"
    end

    def uploads_valid_file(filename)
      post '/stage/upload', :csvfile => RAILS_ROOT + "/test/fixtures/files/" + filename
      assert_response :redirect
      follow_redirect!
      assert_response :success
      assert_template "settings"
    end
    
    def chooses_no_settings
      post '/stage/settings', {"subtitlecol"=>"", "titlecol"=>"", "multiply_price"=>"", "pubdatecol"=>"", "authorcol"=>"", "isbncol"=>"", "publisher_name"=>"", "message_note"=>"", "from_person"=>"", "action"=>"settings", "pricecol"=>"", "formcol"=>"", "controller"=>"stage", "descriptioncol"=>"", "supplier_name"=>"", "from_company"=>"", "websitecol"=>""}
      assert_response :success 
      assert_template "settings"
    end
    
    def forgets_required_settings(forget)
      params = {}
      if forget == :header
        params = {"subtitlecol"=>"", "titlecol"=>"3", "multiply_price"=>"", "pubdatecol"=>"", "authorcol"=>"4", "isbncol"=>"1", "publisher_name"=>"", "message_note"=>"", "from_person"=>"", "action"=>"settings", "pricecol"=>"6", "formcol"=>"5", "controller"=>"stage", "descriptioncol"=>"", "supplier_name"=>"", "from_company"=>"", "websitecol"=>""}
      elsif forget == :cols
        params = {"subtitlecol"=>"", "titlecol"=>"", "multiply_price"=>"", "pubdatecol"=>"", "authorcol"=>"", "isbncol"=>"", "publisher_name"=>"Testy McTest", "message_note"=>"", "from_person"=>"James", "action"=>"settings", "pricecol"=>"", "formcol"=>"", "controller"=>"stage", "descriptioncol"=>"", "supplier_name"=>"Rainbow Book Agencies", "from_company"=>"Testy mcTest", "websitecol"=>""}
      end
      post '/stage/settings', params 
      assert_response :success 
      assert_template "settings"
    end
    
    def enters_invalid_multiply_price 
      params = {"subtitlecol"=>"", "titlecol"=>"3", "multiply_price"=>"aa", "pubdatecol"=>"", "authorcol"=>"4", "isbncol"=>"1", "publisher_name"=>"testy mctest", "message_note"=>"", "from_person"=>"James", "action"=>"settings", "pricecol"=>"6", "formcol"=>"5", "controller"=>"stage", "descriptioncol"=>"", "supplier_name"=>"Rainbow", "from_company"=>"Testy McTest", "websitecol"=>""}
      
      post '/stage/settings', params 
      assert_response :success 
      assert_template "settings"
    end
  
    def enters_valid_settings_with_multiply_price
      params = {"subtitlecol"=>"3", "titlecol"=>"2", "multiply_price"=>"2.25", "pubdatecol"=>"11", "authorcol"=>"4", "isbncol"=>"1", "publisher_name"=>"Columba", "message_note"=>"", "from_person"=>"James", "action"=>"settings", "pricecol"=>"8", "formcol"=>"", "controller"=>"stage", "descriptioncol"=>"9", "supplier_name"=>"Rainbow", "from_company"=>"Testy McTest", "websitecol"=>"", "ignore_first_line" => "yes"}
      
      post '/stage/settings', params 
      assert_response :redirect
      follow_redirect!
      assert_response :success
      assert_template "download"
    end
    
    def enters_valid_settings_no_formcol
      params = {"subtitlecol"=>"", "titlecol"=>"3", "multiply_price"=>"", "pubdatecol"=>"", "authorcol"=>"4", "isbncol"=>"1", "publisher_name"=>"testy mctest", "message_note"=>"", "from_person"=>"James", "action"=>"settings", "pricecol"=>"6", "formcol"=>"", "controller"=>"stage", "descriptioncol"=>"", "supplier_name"=>"Rainbow", "from_company"=>"Testy McTest", "websitecol"=>""}
      
      post '/stage/settings', params 
      assert_response :redirect
      follow_redirect!
      assert_response :success
      assert_template "download"
    end
  
    def enters_valid_settings_with_formcol
      params = {"subtitlecol"=>"", "titlecol"=>"3", "multiply_price"=>"", "pubdatecol"=>"", "authorcol"=>"4", "isbncol"=>"1", "publisher_name"=>"testy mctest", "message_note"=>"", "from_person"=>"James", "action"=>"settings", "pricecol"=>"6", "formcol"=>"5", "controller"=>"stage", "descriptioncol"=>"", "supplier_name"=>"Rainbow", "from_company"=>"Testy McTest", "websitecol"=>""}
      
      post '/stage/settings', params 
      assert_response :redirect
      follow_redirect!
      assert_response :success
      assert_template "form_map"
    end
 
    def makes_form_map_selection
      params = {"action"=>"form_map", "controller"=>"stage", "form"=>{"BX"=>"00", "HC"=>"BB", "TR"=>"00"}}

      post '/stage/form_map', params
      assert_response :redirect
      follow_redirect!
      assert_response :success
      assert_template "download"
    end
  
  end

  def new_session
    open_session do |sess|
      sess.extend(MyTestingDSL)
      yield sess if block_given?
    end
  end
end
