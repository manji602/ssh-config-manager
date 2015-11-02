require 'optparse'

SED_COMMAND = 'gsed'

def parse_configs(path)
  parsed_configs = []

  begin
    config_begin_lines, config_end_lines = fetch_config_lines(path)

    File.open(path) do |file|
      filelines = file.readlines
      config_begin_lines.zip(config_end_lines).each do |begin_line, end_line|

        parsed_config = { begin_line: begin_line, end_line: end_line, property: [] }

        property = parse_property(filelines[begin_line - 1], begin_line)
        parsed_config[:host] = property[:value]

        ((begin_line + 1)..end_line).to_a.each do |i|
          property = parse_property(filelines[i - 1], i)
          parsed_config[:property].push property
        end

        parsed_configs.push parsed_config
      end
    end
  rescue => e
    puts "error has occured. message: #{e.inspect}"
  end

  parsed_configs
end

def fetch_config_lines(path)
  config_begin_lines = []
  config_end_lines = []

  File.open(path) do |file|
    file.each_line do |line|
      config_begin_lines.push file.lineno unless line.match(/^Host \S+/).nil?
    end

    end_lineno = file.lineno
    config_end_lines = config_begin_lines.clone
    config_end_lines.shift
    config_end_lines = config_end_lines.map { |n| n - 1 }.push end_lineno
  end

  [config_begin_lines, config_end_lines]
end

def parse_property(line, line_number)
  is_property = line.match(/^#.+/).nil? && !line.chomp.empty?
  matched     = line.match(/^(.+)\s(\S+)$/) if is_property
  key         = is_property ? matched[1] : nil
  value       = is_property ? matched[2] : nil

  {
    line_number: line_number,
    type: is_property ? 'property' : 'comment',
    key: key,
    value: value
  }
end

def add(parsed_configs, params)
  host_line = params[:body].split('\n').first
  host = parse_property(host_line, 0)[:value]

  is_exists = parsed_configs.map { |config| config[:host] }.include? host

  if is_exists
    overwrite_host(host, parsed_configs, params)
  else
    add_host(params[:body], params[:path])
  end
end

def overwrite_host(host, parsed_configs, params)
  config = parsed_configs.find { |item| item[:host] == host }

  delete_lines(config[:begin_line], config[:end_line], params[:path])
  add_host(params[:body], params[:path])
end

def add_host(body, path)
  begin
    `echo "#{body}" >> #{path}`
  rescue => e
    "add host failed. message: #{e.inspect}"
  end
end

def fix(parsed_configs, params)
  config = parsed_configs.find { |item| item[:host] == params[:host] }
  exit if config.nil?

  property = config[:property].find { |line| line[:key].match(params[:key]) }
  if property.nil?
    puts "target property #{params[:key]} not found."
    exit
  end

  body = "#{property[:key]} #{params[:value]}".gsub(' ', '\ ')
  delete_line = property[:line_number]
  insert_line = delete_line - 1

  begin
    `#{SED_COMMAND} -i -e '#{delete_line}, #{delete_line}d' #{params[:path]}`
    `#{SED_COMMAND} -i -e '#{insert_line}a #{body}' #{params[:path]}`
  rescue => e
    "fix config property failed. message: #{e.inspect}"
  end
end

def delete(parsed_configs, params)
  config = parsed_configs.find { |item| item[:host] == params[:host] }
  exit if config.nil?
  delete_lines(config[:begin_line], config[:end_line], params[:path])
end

def delete_lines(begin_line, end_line, path)
  begin
    `#{SED_COMMAND} -i -e '#{begin_line}, #{end_line}d' #{path}`
  rescue => e
    "delete lines failed. message: #{e.inspect}"
  end
end

def operate(params)
  File.open(params[:path], 'w').close unless File.exist?(params[:path])
  parsed_configs = parse_configs(params[:path])

  case params[:operate]
  when 'add'
    add(parsed_configs, params)
  when 'fix'
    fix(parsed_configs, params)
  when 'delete'
    delete(parsed_configs, params)
  end
end

def help
  puts '[Usage]'
  puts '[add] ruby ssh-config-manager.rb --operate add --body "Hosts xxx.com\n..."'
  puts '[fix] ruby ssh-config-manager.rb --operate fix --host "xxx.com" --key "User" --value "git"'
  puts '[delete] ruby ssh-config-manager.rb --operate delete --host "xxx.com"'

  exit
end

def main
  home = ENV['HOME']

  params = Hash[ ARGV.getopts(
    'h', 'help', 'operate:', 'body:', 'host:', 'key:', 'value:', "path:#{home}/.ssh/config"
  ).map { |k, v| [k.to_sym, v] }]
  help if params[:h] || params[:help]

  operate(params)
end

main
