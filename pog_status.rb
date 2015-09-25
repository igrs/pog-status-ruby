class PogStatus

  def initialize
    @scraper = Scraper.new
  end

  def exec
    invokable.call
  end

private

  def invokable
    case ARGV.size
    when 1
      one_arg
    when 2
      two_args
    else
      usage
    end
  end

  def one_arg
    if ARGV.first === "-h" || ARGV.first === "-help"
      help
    else
      id = ARGV.first
      -> { @scraper.detail(id) }
    end
  end

  def two_args
    if ARGV.first === "-f" || ARGV.first === "-file"
      file_path = ARGV.last
    elsif ARGV.last === "-f" || ARGV.last === "-file"
      file_path = ARGV.first
    end
    if !file_path.nil?
      if File.exist?(file_path)
        -> { @scraper.list(File.readlines(file_path).map { |l| l }) }
      else
        error("File not found.")
      end
    else
      usage
    end
  end

  def error(message = "Something happend.")
    -> {
      puts <<-EOS.gsub(/^\s+/, '')
        ----------------------------------------------
        Error: #{message}
        ----------------------------------------------
      EOS
  }
  end

  def usage
    -> {
      puts <<-EOS.gsub(/^\s+/, '')
        ----------------------------------------------
        Usage: pog_status [netkeiba ID or -f filename]
        ----------------------------------------------
      EOS
  }
  end

  def help
    -> {
      puts <<-EOS.gsub(/^\s+/, '')
        ----------------------------------------------
        Options
        ----------------------------------------------
        -f -file ---- search information from file(with filename)
        -h -help ---- show help
        ----------------------------------------------
      EOS
    }
  end

end


class Scraper

  require 'mechanize'

  def initialize
    @horse = Struct.new("Horse", :name, :prize_c, :prize_l, :record)
    @agent = Mechanize.new
  end

  def list(ids)
    ids.each do |id|
      detail(id)
    end
  end

  def detail(id)
    page = @agent.get("http://db.netkeiba.com/horse/#{id}")
    horse = {}
    horse["馬名"] = page.search('h1').text
    horse["馬名"] =  "存在しません" if horse["馬名"].empty?
    page.search('.db_prof_table').css('tr').each do |tr|
      horse[tr.css('th').text] = tr.css('td').text
    end
    puts_info(horse)
  end

private

  def puts_info(horse)
    puts ""
    puts "----------------------------------------------"
    horse.each do |k, v|
      puts "#{k}: #{v}"
    end
    puts ""
  end
end

# 実行
pog_status = PogStatus.new()
pog_status.exec
