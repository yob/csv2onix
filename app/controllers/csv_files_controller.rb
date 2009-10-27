# coding: utf-8

class CsvFilesController < ApplicationController

  def index
    new
    render :action => "new"
  end

  def new
    #reset_session
  end

  def create
    if params[:csvfile].blank?
      flash[:error] = 'Please begin by uploading a CSV file' and return
    end

    begin
      basename = File.basename(params[:csvfile].original_filename)
      csvfile = ::CsvFile.create(params[:csvfile].path, basename)
      redirect_to csv_file_path(csvfile)
    rescue Exception => e
      flash[:error] = e.message
      redirect_to "/"
    end
  end

  def show
    @csv_file = CsvFile.find(params[:id])
    if @csv_file.nil?
      flash[:error] = "File #{params[:id]} not found"
      redirect_to("/") and return
    end

    @column_options = (1..@csv_file.col_count).map do |num|
      [num, num - 1]
    end
    @currencies = [
      ["Australian Dollar", "AUD"],
      ["Euro", "EUR"],
      ["Pound Sterling", "GBP"],
      ["Singapore Dollar", "SGD"],
      ["US Dollar","USD"]
    ]

    if @csv_file.nil?
      flash[:error] = "No matching CSV file found"
      redirect_to "/" and return
    end

    respond_to do |format|
      format.html
      format.xml do
        @csv_file.generate_onix
        send_file(@csv_file.onix_filename, :filename => @csv_file.download_filename,
                                           :type     => "text/xml",
                                           :disposition => 'attachment')
      end
    end
  end

  def formmap
    @csv_file = CsvFile.find(params[:id])
    @onixforms = ONIX::Lists::PRODUCT_FORM.map do |code, human|
      [human, code]
    end.sort_by { |arr| arr[1]}

    if @csv_file.nil?
      flash[:error] = "No matching CSV file found"
      redirect_to "/" and return
    end
  end

  def ready
    @csv_file = CsvFile.find(params[:id])

    if @csv_file.nil?
      flash[:error] = "No matching CSV file found"
      redirect_to "/" and return
    end
  end

  def update
    @csv_file = CsvFile.find(params[:id])

    if @csv_file.nil?
      flash[:error] = "No matching CSV file found"
      redirect_to "/" and return
    end

    if @csv_file.update_attributes(params[:csv_file])
      if @csv_file.formcol.blank? || @csv_file.formmap
        redirect_to ready_csv_file_path(@csv_file)
      else
        redirect_to formmap_csv_file_path(@csv_file)
      end
    else
      flash.now[:error] = "Error updating CSV file"
      render :action => "show"
    end
  end

  def edit
    @csv_file = CsvFile.find(params[:id])

    if @csv_file.nil?
      flash[:error] = "No matching CSV file found"
      redirect_to "/" and return
    else
      redirect_to csv_file_path(params[:id])
    end
  end
end
