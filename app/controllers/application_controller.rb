# coding: utf-8

require 'csv'

class ApplicationController < ActionController::Base

  layout 'default'

  rescue_from CSV::MalformedCSVError, :with => :csv_error

  # method for handling a malformed CSV file
  def csv_error
    render :template => 'errors/csv', :status => 500
    true
  end

end

