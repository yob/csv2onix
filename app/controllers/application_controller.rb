# coding: utf-8

class ApplicationController < ActionController::Base

  layout 'default'

  include ExceptionNotifiable

end
