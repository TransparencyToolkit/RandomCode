require 'pry'
require 'json'
require 'csv'

class RedLatam
  def initialize(file, prefix)
    @file = File.read(file)
    @prefix = prefix
  end

  # Extract text
  def extract
    extract_doubles
    extract_singles
    save_files
  end

  # Remove extra brackes
  def clean(matches)
    return matches.map{|i| i[0].strip.lstrip}
  end

  def split(matches)
    split_matches = matches.map{|i| i.split(";")}
    clean_split = split_matches.map{|i| i.map{|j| j.strip.lstrip.gsub("\n", " ")}}
    return bracket_remove(clean_split)
  end

  # Remove brackets and XXX
  def bracket_remove(matches)
    clean_matches = matches.map{|i| i.map{|j| j.gsub(/^\s?\[+\s?/, "")}}
    clean_matches.delete(["XXX"])
    return clean_matches
  end
  
  # Extract double brackets
  def extract_doubles
    @double_matches = split(clean(@file.scan(/\[{2}([^]]+)\]{2}/))) 
  end

  # Extract single brackets
  def extract_singles
    @single_matches = split(clean(@file.scan(/\[([^]]+)\]/))) 
  end

  # Process data for saving
  def save_files
    @law_h = [:law, :link, :section]
    @case_h = [:case, :link, :date]

    # Parse into hashes
    @single_matches = @single_matches-@double_matches
    case_hash = @double_matches.map{|i| {@case_h[0] => i[0], @case_h[1] => i[1], @case_h[2] => i[2]}}
    law_hash = @single_matches.map{|i| {@law_h[0] => i[0], @law_h[1] => i[1], @law_h[2] => i[2]}}
    
    # Write files
    write_files(case_hash, law_hash)
  end

  # Write the files themselves
  def write_files(cases, laws)
    File.write(@prefix+"redlatam_cases.json", JSON.pretty_generate(cases))
    File.write(@prefix+"redlatam_laws.json", JSON.pretty_generate(laws))
    File.write(@prefix+"redlatam_cases.csv", gen_csv(@prefix+"redlatam_cases.json", @case_h))
    File.write(@prefix+"redlatam_laws.csv", gen_csv(@prefix+"redlatam_laws.json", @law_h))
  end

  # Generate the CSV
  def gen_csv(file, headers)
    return CSV.generate do |csv|
      csv << headers
      JSON.parse(File.open(file).read).each do |hash|
        csv << hash.values
      end
    end
  end
end

             
file_name = "/home/shidash/Code/red_latam/red_latam.txt"
prefix = "/home/shidash/Code/red_latam/"
r = RedLatam.new(file_name, prefix)
r.extract
