# coding: utf-8

class ApplicationController < ActionController::Base

  layout 'default'

  include ExceptionNotifiable

  rescue_from FasterCSV::MalformedCSVError, :with => :csv_error

  # method for handling a malformed CSV file
  def csv_error
    render :template => 'errors/csv', :status => 500
    true
  end

end
