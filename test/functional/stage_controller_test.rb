# coding: utf-8
require File.dirname(__FILE__) + '/../test_helper'
require 'stage_controller'

# Re-raise errors caught by the controller.
class StageController; def rescue_action(e) raise e end; end

class StageControllerTest < Test::Unit::TestCase
  def setup
    @controller = StageController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # test what happens when this action is the first page loaded in a session
  def test_upload_view
    get :upload
    assert_response :success
    assert_template 'upload'
    assert_valid_markup
  end

  # test what happens when this action is the first page loaded in a session
  def test_settings_view
    get :settings
    assert_redirected_to :action => 'upload'
  end

  # test what happens when this action is the first page loaded in a session
  def test_form_map_view
    get :form_map
    assert_redirected_to :action => 'upload'
  end

  # test what happens when this action is the first page loaded in a session
  def test_download_view
    get :download
    assert_redirected_to :action => 'upload'
  end

  # test what happens when this action is the first page loaded in a session
  def test_onix_view
    get :onix
    assert_redirected_to :action => 'upload'
  end
end
