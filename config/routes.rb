# coding: utf-8

CsvToOnix::Application.routes.draw do

  resources :csv_files do
    member do
      get :formmap
      get :ready
    end
  end

  root to: "csv_files#index"
end
