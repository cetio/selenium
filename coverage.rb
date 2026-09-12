#!/usr/bin/env ruby

BROWSERS = %w[chrome edge firefox safari].freeze
PROJECT_DIR = __dir__
SUMMARY_PATTERN = /^(.*?) (?:is \d+% covered|has no code)\s*$/
COUNT_PATTERN = /^\s*(\d+)\|/


def run_suite(browser = nil)
  command = ['dub', 'test', '--coverage']
  command << "--d-version=#{browser}" if browser
  label = browser || 'offline'

  puts "== #{label}: #{command.join(' ')}"
  ret = system(*command, chdir: PROJECT_DIR)
  puts "!! #{label} failed (exit #{$?.exitstatus})" unless ret
  ret
end


def parse_lst(path)
  lines = File.readlines(path, chomp: true)
  source = lines.last&.match(SUMMARY_PATTERN)&.captures&.first || File.basename(path)
  counts = lines.filter { |line| line.include?('|') }.map do |line|
    match = line.match(COUNT_PATTERN)
    match[1].to_i if match
  end
  [source, counts]
end


def collect(merged)
  Dir.glob(File.join(PROJECT_DIR, '*.lst')).each do |path|
    source, counts = parse_lst(path)
    current = merged[source] ||= []
    counts.each_with_index do |count, index|
      next unless count

      current[index] = [current[index] || 0, count].max
    end
  end
end


def report(merged, include_dependencies)
  rows = merged.filter_map do |source, counts|
    next if !include_dependencies && (source.start_with?('..') || source.start_with?('/'))

    executable = counts.count { |count| count.is_a?(Integer) }
    next if executable.zero?

    covered = counts.count { |count| count.is_a?(Integer) && count.positive? }
    [source, covered, executable]
  end.sort_by(&:first)

  if rows.empty?
    warn 'No coverage results were produced.'
    return 2
  end

  width = rows.map { |row| row.first.length }.max
  puts format("\n%-#{width}s  %9s  %6s", 'File', 'Lines', 'Cover')

  totals = rows.each_with_object([0, 0]) do |(source, covered, executable), sum|
    puts format("%-#{width}s  %4d/%-4d  %5.1f%%", source, covered, executable, covered * 100.0 / executable)
    sum[0] += covered
    sum[1] += executable
  end
  puts format("%-#{width}s  %4d/%-4d  %5.1f%%", 'TOTAL', totals[0], totals[1], totals[0] * 100.0 / totals[1])
  0
end


keep = ARGV.delete('--keep')
include_dependencies = ARGV.delete('--all')
browsers = ARGV.empty? ? BROWSERS : ARGV
lst_files = -> { Dir.glob(File.join(PROJECT_DIR, '*.lst')) }
lst_files.call.each { |path| File.delete(path) }
merged = {}
failed = []

begin
  failed << 'offline' unless run_suite
  collect(merged)
  browsers.each do |browser|
    failed << browser unless run_suite(browser)
    collect(merged)
  end

  ret = report(merged, include_dependencies)
  unless failed.empty?
    puts "\nFailed suites: #{failed.join(', ')}"
    ret = 1
  end
ensure
  lst_files.call.each { |path| File.delete(path) } unless keep
end

exit ret
