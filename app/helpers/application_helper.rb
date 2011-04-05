# coding: utf-8
# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  def array_as_table(data)
    counter = 1
    output = '<table class="table1" style="width: 90%; margin-left: auto; margin-right: auto; ">'

    output += "<tr>"
      output += "<th>&nbsp;</th>"
      (1..data[0].size).to_a.each do |cell|
        output += "<th>#{cell}</th>"
      end
    output += "</tr>"

    data.each do |row|
      output += "<tr>"
      output += "<td>#{counter}</td>"
      row.each do |cell|
        output += "<td>#{cell}</td>"
      end

      output += "</tr>"

      counter += 1
    end

    output += "</table>"

    output.html_safe
  end
end
